#' Minimal, deterministic JSON parser for canonicalisation
#'
#' \code{jsonlite} is excellent but its number handling is ambiguous for our
#' needs: we must tell a big integer (\code{9007199254740993}, which must be
#' emitted bare with no precision loss) apart from a JSON string, and we must
#' know whether a numeric token was written \code{1.0} (whole -> int) or
#' \code{1.5} (non-whole). This hand-written recursive-descent parser preserves
#' every number token as a tagged raw lexeme so the canonicaliser can apply the
#' exact Attestix number rules.
#'
#' Returned value tree:
#' \itemize{
#'   \item object -> named \code{list} (insertion order preserved)
#'   \item array  -> unnamed \code{list}
#'   \item string -> length-1 \code{character} (UTF-8)
#'   \item number -> length-1 \code{character} with class \code{"atx_number"}
#'                   carrying the raw lexeme (e.g. "9007199254740993", "1.0")
#'   \item true/false -> length-1 \code{logical}
#'   \item null   -> \code{NULL} wrapped as \code{list(NULL)} element so it
#'                   survives in lists; top-level null is \code{NULL}
#' }
#' Empty object vs empty array are distinguished: \code{{}} -> empty
#' \emph{named} list, \code{[]} -> empty \emph{unnamed} list.
#'
#' @param txt JSON text (length-1 character) or raw UTF-8 bytes.
#' @return The parsed value tree.
#' @keywords internal
#' @export
atx_json_parse <- function(txt) {
  if (is.raw(txt)) {
    s <- rawToChar(txt)
    Encoding(s) <- "UTF-8"
    txt <- s
  }
  txt <- enc2utf8(txt)
  chars <- utf8ToInt(txt)
  state <- new.env(parent = emptyenv())
  state$cp <- chars
  state$i <- 1L
  state$n <- length(chars)
  .atx_skip_ws(state)
  val <- .atx_parse_value(state)
  .atx_skip_ws(state)
  if (state$i <= state$n) {
    stop("atx_json_parse: trailing content after JSON value")
  }
  val
}

.atx_peek <- function(st) {
  if (st$i > st$n) return(-1L)
  st$cp[st$i]
}

.atx_skip_ws <- function(st) {
  while (st$i <= st$n) {
    c <- st$cp[st$i]
    if (c == 0x20L || c == 0x09L || c == 0x0AL || c == 0x0DL) {
      st$i <- st$i + 1L
    } else {
      break
    }
  }
}

.atx_parse_value <- function(st) {
  c <- .atx_peek(st)
  if (c == -1L) stop("atx_json_parse: unexpected end of input")
  if (c == 0x7BL) return(.atx_parse_object(st))      # {
  if (c == 0x5BL) return(.atx_parse_array(st))       # [
  if (c == 0x22L) return(.atx_parse_string(st))      # "
  if (c == 0x74L || c == 0x66L) return(.atx_parse_bool(st))  # t / f
  if (c == 0x6EL) return(.atx_parse_null(st))        # n
  return(.atx_parse_number(st))
}

.atx_parse_object <- function(st) {
  st$i <- st$i + 1L # consume {
  .atx_skip_ws(st)
  res <- list()
  keys <- character(0)
  if (.atx_peek(st) == 0x7DL) {
    st$i <- st$i + 1L
    # Mark as an (empty) object: a named list of length 0.
    return(structure(list(), names = character(0)))
  }
  repeat {
    .atx_skip_ws(st)
    if (.atx_peek(st) != 0x22L) stop("atx_json_parse: expected string key")
    key <- .atx_parse_string(st)
    .atx_skip_ws(st)
    if (.atx_peek(st) != 0x3AL) stop("atx_json_parse: expected ':'")
    st$i <- st$i + 1L
    .atx_skip_ws(st)
    val <- .atx_parse_value(st)
    res[[length(res) + 1L]] <- val
    keys <- c(keys, key)
    .atx_skip_ws(st)
    c <- .atx_peek(st)
    if (c == 0x2CL) { st$i <- st$i + 1L; next }
    if (c == 0x7DL) { st$i <- st$i + 1L; break }
    stop("atx_json_parse: expected ',' or '}'")
  }
  names(res) <- keys
  res
}

.atx_parse_array <- function(st) {
  st$i <- st$i + 1L # consume [
  .atx_skip_ws(st)
  res <- list()
  if (.atx_peek(st) == 0x5DL) {
    st$i <- st$i + 1L
    return(res) # empty unnamed list = []
  }
  repeat {
    .atx_skip_ws(st)
    val <- .atx_parse_value(st)
    res[length(res) + 1L] <- list(val) # preserve NULL elements
    .atx_skip_ws(st)
    c <- .atx_peek(st)
    if (c == 0x2CL) { st$i <- st$i + 1L; next }
    if (c == 0x5DL) { st$i <- st$i + 1L; break }
    stop("atx_json_parse: expected ',' or ']'")
  }
  res
}

.atx_parse_string <- function(st) {
  st$i <- st$i + 1L # consume opening "
  cps <- integer(0)
  repeat {
    if (st$i > st$n) stop("atx_json_parse: unterminated string")
    c <- st$cp[st$i]
    st$i <- st$i + 1L
    if (c == 0x22L) break
    if (c == 0x5CL) {
      e <- st$cp[st$i]; st$i <- st$i + 1L
      cps <- c(cps, switch(
        as.character(e),
        "34" = 0x22L,   # "
        "92" = 0x5CL,   # backslash
        "47" = 0x2FL,   # /
        "98" = 0x08L,   # b
        "102" = 0x0CL,  # f
        "110" = 0x0AL,  # n
        "114" = 0x0DL,  # r
        "116" = 0x09L,  # t
        "117" = .atx_parse_unicode_escape(st), # u
        stop("atx_json_parse: bad escape")
      ))
    } else {
      cps <- c(cps, c)
    }
  }
  if (length(cps) == 0L) {
    s <- ""
  } else {
    s <- intToUtf8(cps)
  }
  Encoding(s) <- "UTF-8"
  s
}

.atx_parse_unicode_escape <- function(st) {
  hex <- intToUtf8(st$cp[st$i:(st$i + 3L)])
  st$i <- st$i + 4L
  cp <- strtoi(hex, 16L)
  # Surrogate pair handling.
  if (cp >= 0xD800L && cp <= 0xDBFFL) {
    if (st$cp[st$i] == 0x5CL && st$cp[st$i + 1L] == 0x75L) {
      st$i <- st$i + 2L
      hex2 <- intToUtf8(st$cp[st$i:(st$i + 3L)])
      st$i <- st$i + 4L
      lo <- strtoi(hex2, 16L)
      cp <- 0x10000L + (bitwShiftL(cp - 0xD800L, 10L)) + (lo - 0xDC00L)
    }
  }
  cp
}

.atx_parse_bool <- function(st) {
  c <- .atx_peek(st)
  if (c == 0x74L) { # true
    st$i <- st$i + 4L
    return(TRUE)
  }
  st$i <- st$i + 5L # false
  FALSE
}

.atx_parse_null <- function(st) {
  st$i <- st$i + 4L
  NULL
}

.atx_parse_number <- function(st) {
  start <- st$i
  while (st$i <= st$n) {
    c <- st$cp[st$i]
    # digits, sign, decimal point, exponent
    if ((c >= 0x30L && c <= 0x39L) || c == 0x2DL || c == 0x2BL ||
        c == 0x2EL || c == 0x65L || c == 0x45L) {
      st$i <- st$i + 1L
    } else {
      break
    }
  }
  lex <- intToUtf8(st$cp[start:(st$i - 1L)])
  structure(lex, class = "atx_number")
}
