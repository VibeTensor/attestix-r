#' base64url decode (accepts padded or unpadded input)
#'
#' VC \code{proofValue} is base64url \strong{with} padding; JWT compact segments
#' are base64url \strong{without} padding. This decoder accepts both by
#' re-padding as needed, then delegating to \code{openssl::base64_decode} after
#' translating the URL alphabet (\code{-_}) to the standard alphabet
#' (\code{+/}).
#'
#' @param s A length-1 base64url string.
#' @return A raw vector.
#' @keywords internal
#' @export
atx_b64url_decode <- function(s) {
  if (!is.character(s) || length(s) != 1L) {
    stop("atx_b64url_decode: expected length-1 character")
  }
  s <- gsub("=+$", "", s)            # drop any existing padding
  s <- chartr("-_", "+/", s)         # url alphabet -> standard
  pad <- (4L - (nchar(s) %% 4L)) %% 4L
  if (pad > 0L) s <- paste0(s, strrep("=", pad))
  openssl::base64_decode(s)
}

#' base64url encode WITH padding (matches Python base64.urlsafe_b64encode).
#'
#' @param bytes A raw vector.
#' @return A length-1 base64url string (padded).
#' @keywords internal
#' @export
atx_b64url_encode <- function(bytes) {
  if (!is.raw(bytes)) stop("atx_b64url_encode: expected raw vector")
  std <- openssl::base64_encode(bytes) # standard, padded
  std <- gsub("\n", "", std)
  chartr("+/", "-_", std)
}

#' Hex string -> raw vector.
#' @param h A hex string (even length).
#' @return A raw vector.
#' @keywords internal
#' @export
atx_hex_to_raw <- function(h) {
  if (!is.character(h) || length(h) != 1L) stop("expected length-1 hex string")
  if (nchar(h) %% 2L != 0L) stop("odd-length hex string")
  if (nchar(h) == 0L) return(raw(0))
  as.raw(strtoi(substring(h, seq(1L, nchar(h), 2L), seq(2L, nchar(h), 2L)), 16L))
}

#' Raw vector -> lowercase hex string.
#' @param r A raw vector.
#' @return A hex string.
#' @keywords internal
#' @export
atx_raw_to_hex <- function(r) {
  paste(sprintf("%02x", as.integer(r)), collapse = "")
}
