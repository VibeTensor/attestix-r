#' Fields excluded from the W3C VC signature (\code{MUTABLE_FIELDS}).
#' @keywords internal
.ATX_MUTABLE_FIELDS <- c("proof", "credentialStatus")

#' Verify an Attestix W3C Verifiable Credential offline
#'
#' Mirrors \code{attestix/services/credential_service.py::verify_credential}.
#' The signing payload is the credential with the \code{proof} and
#' \code{credentialStatus} top-level keys removed; that payload is JCS-style
#' canonicalized (see \code{\link{atx_canonicalize}}) and the Ed25519 signature
#' in \code{proof.proofValue} is verified against the issuer public key.
#'
#' Three independent checks are ANDed:
#' \itemize{
#'   \item \code{signature_valid} — Ed25519 verification of the canonical bytes.
#'   \item \code{not_expired} — \code{now < expirationDate} (tz-aware ISO-8601).
#'   \item \code{not_revoked} — \code{credentialStatus$revoked} is falsy.
#' }
#'
#' @param vc The credential as a JSON string, raw UTF-8 bytes, or a value tree
#'   from \code{\link{atx_json_parse}}.
#' @param public_key The issuer Ed25519 public key. Accepts a raw 32-byte
#'   vector, a 64-char hex string, or \code{NULL} to derive it from the
#'   credential's \code{issuer.id} / \code{verificationMethod} did:key.
#' @param now The reference time for the expiry check, as a
#'   \code{POSIXct} or ISO-8601 string. Defaults to \code{Sys.time()}.
#' @return A list with logical fields \code{signature_valid},
#'   \code{not_expired}, \code{not_revoked}, \code{structure_valid}, and the
#'   overall \code{verify}.
#' @examples
#' \dontrun{
#' res <- atx_verify_credential(vc_json)
#' isTRUE(res$verify)
#' }
#' @export
atx_verify_credential <- function(vc, public_key = NULL, now = Sys.time()) {
  if (is.character(vc) && length(vc) == 1L) {
    tree <- atx_json_parse(vc)
  } else if (is.raw(vc)) {
    tree <- atx_json_parse(vc)
  } else if (is.list(vc)) {
    tree <- vc
  } else {
    stop("atx_verify_credential: vc must be JSON text, raw, or a value tree")
  }

  structure_valid <- .atx_vc_structure_ok(tree)

  # Resolve the issuer public key if not supplied.
  pk <- .atx_resolve_pubkey(public_key, tree)

  # Build the signing payload: drop mutable top-level keys.
  payload <- tree[setdiff(names(tree), .ATX_MUTABLE_FIELDS)]
  canonical <- atx_canonicalize(payload)

  # Extract proofValue.
  proof <- tree[["proof"]]
  sig_b64 <- if (is.list(proof)) proof[["proofValue"]] else NULL
  signature_valid <- FALSE
  if (!is.null(sig_b64) && is.character(sig_b64) && !is.null(pk)) {
    sig <- tryCatch(atx_b64url_decode(sig_b64), error = function(e) NULL)
    if (!is.null(sig)) {
      signature_valid <- atx_ed25519_verify(canonical, sig, pk)
    }
  }

  # Expiry.
  not_expired <- .atx_check_not_expired(tree[["expirationDate"]], now)

  # Revocation (locally checkable only).
  not_revoked <- .atx_check_not_revoked(tree[["credentialStatus"]])

  verify <- isTRUE(signature_valid) && isTRUE(not_expired) &&
    isTRUE(not_revoked) && isTRUE(structure_valid)

  list(
    signature_valid = isTRUE(signature_valid),
    not_expired = isTRUE(not_expired),
    not_revoked = isTRUE(not_revoked),
    structure_valid = isTRUE(structure_valid),
    verify = verify
  )
}

# ---- internals --------------------------------------------------------------

.atx_vc_structure_ok <- function(tree) {
  if (!is.list(tree)) return(FALSE)
  required <- c("@context", "credentialSubject", "issuer", "type", "proof")
  all(required %in% names(tree))
}

.atx_resolve_pubkey <- function(public_key, tree) {
  if (is.raw(public_key) && length(public_key) == 32L) return(public_key)
  if (is.character(public_key) && length(public_key) == 1L) {
    return(atx_hex_to_raw(public_key))
  }
  # Derive from issuer.id (a did:key) or verificationMethod.
  issuer <- tree[["issuer"]]
  did <- NULL
  if (is.list(issuer) && !is.null(issuer[["id"]])) {
    did <- issuer[["id"]]
  } else if (is.character(issuer)) {
    did <- issuer
  }
  if (is.null(did)) {
    proof <- tree[["proof"]]
    if (is.list(proof) && !is.null(proof[["verificationMethod"]])) {
      vm <- proof[["verificationMethod"]]
      did <- sub("#.*$", "", vm)
    }
  }
  if (is.character(did) && grepl("^did:key:z", did)) {
    return(tryCatch(atx_decode_did_key(did), error = function(e) NULL))
  }
  NULL
}

.atx_check_not_expired <- function(exp_str, now) {
  if (is.null(exp_str) || !is.character(exp_str) || !nzchar(exp_str)) {
    return(TRUE) # no expiry -> never expires
  }
  exp_t <- .atx_parse_iso8601(exp_str)
  now_t <- if (inherits(now, "POSIXct")) now else .atx_parse_iso8601(as.character(now))
  if (is.na(exp_t) || is.na(now_t)) return(FALSE)
  now_t < exp_t
}

.atx_check_not_revoked <- function(status) {
  if (is.null(status) || !is.list(status)) return(TRUE)
  revoked <- status[["revoked"]]
  if (is.null(revoked)) return(TRUE)
  !isTRUE(revoked)
}

# Parse an ISO-8601 timestamp (e.g. "2027-01-01T00:00:00+00:00") to POSIXct.
.atx_parse_iso8601 <- function(s) {
  if (is.null(s) || !nzchar(s)) return(as.POSIXct(NA))
  # Normalize "+00:00" -> "+0000" for strptime %z.
  s2 <- sub("([+-][0-9]{2}):([0-9]{2})$", "\\1\\2", s)
  s2 <- sub("Z$", "+0000", s2)
  fmts <- c("%Y-%m-%dT%H:%M:%OS%z", "%Y-%m-%dT%H:%M:%S%z",
            "%Y-%m-%dT%H:%M:%OS", "%Y-%m-%dT%H:%M:%S")
  for (f in fmts) {
    t <- as.POSIXct(strptime(s2, f, tz = "UTC"))
    if (!is.na(t)) return(t)
  }
  as.POSIXct(NA)
}
