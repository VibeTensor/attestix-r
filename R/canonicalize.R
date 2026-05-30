#' Attestix JCS-style canonical JSON
#'
#' Reproduces \code{attestix/auth/crypto.py::canonicalize_json} byte-for-byte.
#'
#' This is \strong{JCS-style, NOT strict RFC 8785}. The two load-bearing
#' divergences from RFC 8785 are:
#' \enumerate{
#'   \item NFC Unicode normalization is applied to every string value and every
#'         object key (RFC 8785 does \emph{not} normalize).
#'   \item Whole-number floats collapse to integers (\code{1.0 -> 1}); non-whole
#'         floats use Python's \code{repr} (the vectors only use integers and
#'         \code{1.5}, on which every port agrees).
#' }
#' Keys are sorted by Unicode code point, separators are \code{","} and
#' \code{":"} with no whitespace, output is raw UTF-8 (no \code{\\uXXXX}
#' escapes), and large integers (\code{> 2^53}) are preserved exactly.
#'
#' @param obj A JSON string, raw UTF-8 bytes, or a value tree produced by
#'   \code{\link{atx_json_parse}}.
#' @return A raw vector of the canonical UTF-8 bytes.
#' @examples
#' bytes <- atx_canonicalize('{"b":2,"a":1}')
#' rawToChar(bytes) # {"a":1,"b":2}
#' @export
atx_canonicalize <- function(obj) {
  if (is.character(obj) && length(obj) == 1L && !inherits(obj, "atx_number")) {
    obj <- atx_json_parse(obj)
  } else if (is.raw(obj)) {
    obj <- atx_json_parse(obj)
  }
  s <- .atx_canon_value(obj)
  charToRaw(enc2utf8(s))
}

#' Parse JSON into the canonicalisation value tree
#'
#' Convenience alias for \code{\link{atx_json_parse}}.
#'
#' @param txt JSON text or raw UTF-8 bytes.
#' @return The parsed value tree.
#' @export
atx_parse_json <- function(txt) {
  atx_json_parse(txt)
}

# ---- internals --------------------------------------------------------------

# NFC-normalize a single string value/key.
.atx_nfc <- function(s) {
  s <- enc2utf8(s)
  out <- stringi::stri_trans_nfc(s)
  enc2utf8(out)
}

# Serialize a parsed value node to its canonical JSON fragment (UTF-8 string).
.atx_canon_value <- function(x) {
  if (is.null(x)) {
    return("null")
  }
  if (inherits(x, "atx_number")) {
    return(.atx_number(unclass(x)))
  }
  if (is.logical(x) && length(x) == 1L && !is.na(x)) {
    return(if (isTRUE(x)) "true" else "false")
  }
  if (is.character(x) && length(x) == 1L) {
    return(.atx_json_string(x))
  }
  # Bare atomic numbers (e.g. from a jsonlite-parsed tree). NOTE: doubles lose
  # precision above 2^53, so integers larger than that MUST be supplied via the
  # string/raw API (which routes through atx_json_parse and preserves them as
  # exact atx_number lexemes). This branch is a convenience for ordinary values.
  if (is.numeric(x) && length(x) == 1L && !is.na(x)) {
    if (is.integer(x)) return(format(x, scientific = FALSE))
    return(.atx_number(format(x, scientific = FALSE, trim = TRUE, digits = 17)))
  }
  # Length-1 logical NA or other atomics fall through; multi-length atomic
  # vectors are treated as JSON arrays (jsonlite may keep arrays atomic).
  if (is.atomic(x) && !is.list(x) && length(x) != 1L) {
    return(.atx_array(as.list(x)))
  }
  if (is.list(x)) {
    nm <- names(x)
    if (length(x) == 0L) {
      # Empty named list -> {}; empty unnamed list -> [].
      if (!is.null(nm)) return("{}")
      return("[]")
    }
    is_obj <- !is.null(nm) && all(nzchar(nm))
    if (is_obj) return(.atx_object(x))
    return(.atx_array(x))
  }
  stop("atx_canonicalize: unsupported node type: ", class(x)[1])
}

.atx_object <- function(x) {
  keys <- names(x)
  nkeys <- vapply(keys, .atx_nfc, character(1), USE.NAMES = FALSE)
  ord <- .atx_codepoint_order(nkeys)
  parts <- character(length(x))
  for (i in seq_along(ord)) {
    j <- ord[i]
    k <- .atx_json_string(nkeys[j])
    v <- .atx_canon_value(x[[j]])
    parts[i] <- paste0(k, ":", v)
  }
  paste0("{", paste(parts, collapse = ","), "}")
}

.atx_array <- function(x) {
  parts <- vapply(x, .atx_canon_value, character(1), USE.NAMES = FALSE)
  paste0("[", paste(parts, collapse = ","), "]")
}

# Sort by Unicode code point ascending (locale-independent).
.atx_codepoint_order <- function(strs) {
  if (length(strs) <= 1L) return(seq_along(strs))
  cps <- lapply(strs, function(s) utf8ToInt(enc2utf8(s)))
  ord <- seq_along(strs)
  cmp <- function(a, b) {
    ca <- cps[[a]]; cb <- cps[[b]]
    n <- min(length(ca), length(cb))
    if (n > 0L) {
      d <- which(ca[seq_len(n)] != cb[seq_len(n)])
      if (length(d) > 0L) {
        i <- d[1]
        return(if (ca[i] < cb[i]) -1L else 1L)
      }
    }
    if (length(ca) < length(cb)) return(-1L)
    if (length(ca) > length(cb)) return(1L)
    0L
  }
  for (i in seq_along(ord)[-1]) {
    key <- ord[i]
    k <- i - 1L
    while (k >= 1L && cmp(ord[k], key) > 0L) {
      ord[k + 1L] <- ord[k]
      k <- k - 1L
    }
    ord[k + 1L] <- key
  }
  ord
}

# Emit a number from its raw JSON lexeme, applying the Attestix rules:
# a whole-number value (1, -42, 1.0, 2.0, big ints) -> bare integer form;
# a non-whole value (1.5) -> minimal decimal repr.
.atx_number <- function(lex) {
  lex <- as.character(lex)
  has_frac <- grepl("[.eE]", lex)
  if (!has_frac) {
    # Pure integer lexeme (possibly > 2^53). Emit verbatim, sans leading '+'.
    return(sub("^\\+", "", lex))
  }
  val <- as.numeric(lex)
  if (is.finite(val) && val == round(val) && abs(val) < 1e15) {
    return(format(as.integer(round(val)), scientific = FALSE))
  }
  if (is.finite(val) && val == round(val)) {
    return(format(val, scientific = FALSE, trim = TRUE))
  }
  fmt <- format(val, scientific = FALSE, trim = TRUE, digits = 17)
  if (grepl("\\.", fmt)) {
    fmt <- sub("0+$", "", fmt)
    fmt <- sub("\\.$", ".0", fmt)
  }
  fmt
}

# JSON-encode a string the way Python json.dumps(ensure_ascii=False) does:
# escape ", \, and the named C0 controls; \uXXXX only for other C0 chars; emit
# everything else (incl. all non-ASCII) literally as raw UTF-8. NFC first.
.atx_json_string <- function(s) {
  s <- .atx_nfc(s)
  if (!nzchar(s)) return("\"\"")
  cps <- utf8ToInt(enc2utf8(s))
  out <- character(length(cps))
  for (i in seq_along(cps)) {
    cp <- cps[i]
    out[i] <- if (cp == 0x22L) {
      "\\\""
    } else if (cp == 0x5CL) {
      "\\\\"
    } else if (cp == 0x08L) {
      "\\b"
    } else if (cp == 0x0CL) {
      "\\f"
    } else if (cp == 0x0AL) {
      "\\n"
    } else if (cp == 0x0DL) {
      "\\r"
    } else if (cp == 0x09L) {
      "\\t"
    } else if (cp < 0x20L) {
      sprintf("\\u%04x", cp)
    } else {
      intToUtf8(cp)
    }
  }
  paste0("\"", paste(out, collapse = ""), "\"")
}
