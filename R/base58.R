#' Base58btc (Bitcoin alphabet) encode/decode
#'
#' Vendored minimal implementation, no external dependency. Used for did:key
#' multibase \code{z} payloads. Uses double-precision-safe big-integer-free
#' byte arithmetic (repeated base-256 <-> base-58 conversion on raw byte
#' vectors), so it is exact for arbitrary-length inputs.
#'
#' @name base58
#' @keywords internal
NULL

.B58_ALPHABET <- strsplit(
  "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz", ""
)[[1]]

#' Encode raw bytes to a base58btc string.
#'
#' @param bytes A raw vector.
#' @return A length-1 character string.
#' @keywords internal
#' @export
atx_base58_encode <- function(bytes) {
  if (!is.raw(bytes)) stop("atx_base58_encode: expected raw vector")
  if (length(bytes) == 0L) return("")
  vals <- as.integer(bytes)
  # Count leading zero bytes -> leading '1's.
  nzero <- 0L
  for (b in vals) {
    if (b == 0L) nzero <- nzero + 1L else break
  }
  # Convert base-256 number (big-endian) to base-58 digits.
  digits <- integer(0)
  input <- vals
  # Strip nothing; do long division by 58 repeatedly.
  repeat {
    # Is input all zero?
    if (all(input == 0L)) break
    remainder <- 0L
    quotient <- integer(length(input))
    for (i in seq_along(input)) {
      acc <- remainder * 256L + input[i]
      quotient[i] <- acc %/% 58L
      remainder <- acc %% 58L
    }
    digits <- c(remainder, digits)
    # Trim leading zeros from quotient for next round.
    nz <- which(quotient != 0L)
    if (length(nz) == 0L) {
      input <- integer(0)
      break
    } else {
      input <- quotient[nz[1]:length(quotient)]
    }
  }
  chars <- c(rep("1", nzero), .B58_ALPHABET[digits + 1L])
  paste(chars, collapse = "")
}

#' Decode a base58btc string to raw bytes.
#'
#' @param s A length-1 character string.
#' @return A raw vector.
#' @keywords internal
#' @export
atx_base58_decode <- function(s) {
  if (!is.character(s) || length(s) != 1L) {
    stop("atx_base58_decode: expected length-1 character")
  }
  if (!nzchar(s)) return(raw(0))
  ch <- strsplit(s, "")[[1]]
  idx <- match(ch, .B58_ALPHABET) - 1L
  if (anyNA(idx)) stop("atx_base58_decode: invalid base58 character")
  # Count leading '1's -> leading zero bytes.
  nzero <- 0L
  for (c in ch) {
    if (c == "1") nzero <- nzero + 1L else break
  }
  # Convert base-58 digits to base-256 by long division by 256.
  input <- idx
  out <- integer(0)
  repeat {
    if (all(input == 0L)) break
    remainder <- 0L
    quotient <- integer(length(input))
    for (i in seq_along(input)) {
      acc <- remainder * 58L + input[i]
      quotient[i] <- acc %/% 256L
      remainder <- acc %% 256L
    }
    out <- c(remainder, out)
    nz <- which(quotient != 0L)
    if (length(nz) == 0L) {
      input <- integer(0)
      break
    } else {
      input <- quotient[nz[1]:length(quotient)]
    }
  }
  as.raw(c(rep(0L, nzero), out))
}
