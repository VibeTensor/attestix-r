#' Ed25519 multicodec prefix (\code{0xed 0x01}) for \code{ed25519-pub}.
#' @keywords internal
.ED25519_MULTICODEC_PREFIX <- as.raw(c(0xed, 0x01))

#' Decode an Ed25519 \code{did:key} to its raw 32-byte public key
#'
#' Reproduces \code{attestix/auth/crypto.py::did_key_to_public_key}: strip the
#' \code{did:key:z} prefix, base58btc-decode the multibase payload, assert the
#' first two bytes are the \code{0xed 0x01} multicodec prefix, and return the
#' remaining 32 raw bytes.
#'
#' @param did A \code{did:key:z...} string.
#' @return A raw vector of length 32 (the Ed25519 public key).
#' @examples
#' did <- "did:key:z6Mko5TBPGKHkCxSgmf3aC6p6SGj2auwCfRmBydXJFEwL4ev"
#' length(atx_decode_did_key(did)) # 32
#' @export
atx_decode_did_key <- function(did) {
  if (!is.character(did) || length(did) != 1L) {
    stop("atx_decode_did_key: expected length-1 character")
  }
  prefix <- "did:key:z"
  if (substr(did, 1L, nchar(prefix)) != prefix) {
    stop("atx_decode_did_key: not a did:key:z... value")
  }
  mb <- substr(did, nchar(prefix) + 1L, nchar(did))
  decoded <- atx_base58_decode(mb)
  if (length(decoded) != 34L) {
    stop("atx_decode_did_key: expected 34 bytes (2-byte prefix + 32-byte key), got ",
         length(decoded))
  }
  if (!identical(decoded[1:2], .ED25519_MULTICODEC_PREFIX)) {
    stop("atx_decode_did_key: missing 0xed01 ed25519-pub multicodec prefix")
  }
  decoded[3:34]
}

#' Encode a raw 32-byte Ed25519 public key to a \code{did:key}
#'
#' Inverse of \code{\link{atx_decode_did_key}}.
#'
#' @param pubkey A raw vector of length 32.
#' @return A \code{did:key:z...} string.
#' @export
atx_public_key_to_did_key <- function(pubkey) {
  if (!is.raw(pubkey) || length(pubkey) != 32L) {
    stop("atx_public_key_to_did_key: expected 32 raw bytes")
  }
  payload <- c(.ED25519_MULTICODEC_PREFIX, pubkey)
  paste0("did:key:z", atx_base58_encode(payload))
}

#' Return the multibase fragment portion of a \code{did:key}
#'
#' The verification method is \code{<did>#<multibase>} where \code{<multibase>}
#' is the \code{z...} portion of the did:key. This returns that fragment with a
#' leading \code{#}.
#'
#' @param did A \code{did:key:z...} string.
#' @return The \code{#z...} fragment.
#' @export
atx_did_key_fragment <- function(did) {
  if (substr(did, 1L, 8L) != "did:key:") {
    stop("atx_did_key_fragment: not a did:key value")
  }
  paste0("#", substr(did, 9L, nchar(did)))
}

#' Full verification method for a \code{did:key} (\code{<did>#<multibase>}).
#'
#' @param did A \code{did:key:z...} string.
#' @return The verification-method string.
#' @export
atx_verification_method <- function(did) {
  paste0(did, atx_did_key_fragment(did))
}
