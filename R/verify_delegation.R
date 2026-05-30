#' Decode a JWT compact token without verifying.
#'
#' @param token A compact JWT (\code{header.payload.signature}).
#' @return A list with \code{header}, \code{payload} (parsed value trees),
#'   \code{signing_input} (raw bytes of \code{header.payload}), and
#'   \code{signature} (raw bytes).
#' @keywords internal
#' @export
atx_jwt_decode <- function(token) {
  if (!is.character(token) || length(token) != 1L) {
    stop("atx_jwt_decode: expected length-1 character")
  }
  parts <- strsplit(token, ".", fixed = TRUE)[[1]]
  if (length(parts) != 3L) stop("atx_jwt_decode: not a compact JWT")
  header <- atx_json_parse(atx_b64url_decode(parts[1]))
  payload <- atx_json_parse(atx_b64url_decode(parts[2]))
  signing_input <- charToRaw(paste0(parts[1], ".", parts[2]))
  signature <- atx_b64url_decode(parts[3])
  list(
    header = header,
    payload = payload,
    signing_input = signing_input,
    signature = signature
  )
}

#' Verify a single UCAN JWT (signature + alg + expiry + revocation).
#'
#' Mirrors the per-token checks in
#' \code{attestix/services/delegation_service.py::verify_delegation}. Only
#' \code{alg=EdDSA} is accepted; \code{alg:none} (and any other alg) is rejected.
#'
#' @param token A compact JWT string.
#' @param public_key The Ed25519 server public key (raw 32 bytes or hex).
#' @param now Reference time (POSIXct or ISO/epoch). Defaults to
#'   \code{Sys.time()}.
#' @param revoked_jti Optional character vector of revoked \code{jti} values.
#' @return A list with \code{signature_valid}, \code{not_expired},
#'   \code{not_revoked}, \code{alg_ok}, \code{jti}, \code{att}, and \code{valid}.
#' @keywords internal
#' @export
atx_verify_ucan_token <- function(token, public_key, now = Sys.time(),
                                  revoked_jti = character(0)) {
  pk <- if (is.character(public_key)) atx_hex_to_raw(public_key) else public_key
  dec <- atx_jwt_decode(token)

  alg <- dec$header[["alg"]]
  alg_ok <- is.character(alg) && identical(alg, "EdDSA")

  signature_valid <- alg_ok &&
    atx_ed25519_verify(dec$signing_input, dec$signature, pk)

  exp <- dec$payload[["exp"]]
  not_expired <- TRUE
  if (!is.null(exp)) {
    exp_num <- as.numeric(if (inherits(exp, "atx_number")) unclass(exp) else exp)
    now_epoch <- if (inherits(now, "POSIXct")) as.numeric(now) else as.numeric(now)
    not_expired <- now_epoch < exp_num
  }

  jti <- dec$payload[["jti"]]
  not_revoked <- !(is.character(jti) && jti %in% revoked_jti)

  att <- dec$payload[["att"]]
  att_chr <- if (is.list(att)) vapply(att, as.character, character(1)) else as.character(att)

  list(
    signature_valid = isTRUE(signature_valid),
    not_expired = isTRUE(not_expired),
    not_revoked = isTRUE(not_revoked),
    alg_ok = isTRUE(alg_ok),
    jti = if (is.character(jti)) jti else NA_character_,
    att = att_chr,
    valid = isTRUE(signature_valid) && isTRUE(not_expired) && isTRUE(not_revoked)
  )
}

#' Verify a UCAN delegation chain (Ed25519 per link + attenuation)
#'
#' Mirrors the recursive \code{prf}-chain verification in
#' \code{attestix/services/delegation_service.py}. Each token in the chain is a
#' PyJWT EdDSA JWT; the signed message is the compact \code{header.payload}
#' form (base64url \strong{unpadded}), NOT the JCS canonical form.
#'
#' The chain verifies iff every token's signature is valid AND every token is
#' unexpired and unrevoked AND each child's \code{att} is a \strong{subset} of
#' its parent's \code{att} (capability attenuation; escalation is rejected).
#' Cycles (a repeated \code{jti}) are rejected.
#'
#' @param chain A list describing the chain. Accepts the conformance-vector
#'   shape: \code{parent_token}, \code{token} (child), and optionally
#'   \code{parent_att} / \code{child_att}. Alternatively a list of compact JWT
#'   strings ordered root-first.
#' @param public_key The Ed25519 server public key (raw 32 bytes or hex).
#' @param now Reference time. Defaults to \code{Sys.time()}.
#' @param revoked_jti Optional revoked \code{jti} character vector.
#' @return A list with \code{parent_signature_valid},
#'   \code{child_signature_valid}, \code{attenuation_is_subset}, and the overall
#'   \code{verify}.
#' @examples
#' \dontrun{
#' atx_verify_delegation_chain(list(parent_token = pt, token = ct), pk)
#' }
#' @export
atx_verify_delegation_chain <- function(chain, public_key, now = Sys.time(),
                                        revoked_jti = character(0)) {
  pk <- if (is.character(public_key)) atx_hex_to_raw(public_key) else public_key

  # Normalize input into an ordered list of token strings (root first).
  parent_token <- chain[["parent_token"]]
  child_token <- chain[["token"]]
  if (is.null(child_token)) child_token <- chain[["child_token"]]

  if (is.null(parent_token) && is.null(child_token)) {
    # Maybe chain is itself a list of token strings.
    if (is.list(chain) && all(vapply(chain, is.character, logical(1)))) {
      tokens <- unlist(chain, use.names = FALSE)
      parent_token <- tokens[1]
      child_token <- if (length(tokens) >= 2L) tokens[length(tokens)] else NULL
    }
  }

  parent_res <- atx_verify_ucan_token(parent_token, pk, now, revoked_jti)
  child_res <- atx_verify_ucan_token(child_token, pk, now, revoked_jti)

  # Attenuation: child att subset of parent att. Prefer the token claims;
  # fall back to declared *_att fields if provided.
  parent_att <- parent_res$att
  child_att <- child_res$att
  if (!is.null(chain[["parent_att"]])) {
    parent_att <- .atx_as_chr_vec(chain[["parent_att"]])
  }
  if (!is.null(chain[["child_att"]])) {
    child_att <- .atx_as_chr_vec(chain[["child_att"]])
  }
  attenuation_is_subset <- all(child_att %in% parent_att)

  # Cycle detection on jti.
  jtis <- c(parent_res$jti, child_res$jti)
  jtis <- jtis[!is.na(jtis)]
  no_cycle <- length(jtis) == length(unique(jtis))

  verify <- isTRUE(parent_res$valid) && isTRUE(child_res$valid) &&
    isTRUE(attenuation_is_subset) && isTRUE(no_cycle)

  list(
    parent_signature_valid = isTRUE(parent_res$signature_valid),
    child_signature_valid = isTRUE(child_res$signature_valid),
    attenuation_is_subset = isTRUE(attenuation_is_subset),
    verify = verify
  )
}

.atx_as_chr_vec <- function(x) {
  if (is.list(x)) return(vapply(x, as.character, character(1)))
  as.character(x)
}
