#' Verify an Ed25519 (RFC 8032) signature
#'
#' Thin wrapper over \code{sodium::sig_verify} (libsodium). Returns a logical
#' rather than signalling, so callers can fold it into a structured result.
#'
#' @param message Raw vector of the signed message bytes.
#' @param signature Raw vector, 64 bytes.
#' @param public_key Raw vector, 32 bytes.
#' @return \code{TRUE} if the signature is valid, else \code{FALSE}.
#' @examples
#' \dontrun{
#' atx_ed25519_verify(msg, sig, pubkey)
#' }
#' @export
atx_ed25519_verify <- function(message, signature, public_key) {
  if (!is.raw(message)) stop("atx_ed25519_verify: message must be raw")
  if (!is.raw(signature) || length(signature) != 64L) {
    return(FALSE)
  }
  if (!is.raw(public_key) || length(public_key) != 32L) {
    stop("atx_ed25519_verify: public_key must be 32 raw bytes")
  }
  ok <- tryCatch(
    sodium::sig_verify(message, signature, public_key),
    error = function(e) FALSE
  )
  isTRUE(ok)
}
