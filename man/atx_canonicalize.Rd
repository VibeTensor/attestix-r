% Generated from R/canonicalize.R
\name{atx_canonicalize}
\alias{atx_canonicalize}
\title{Attestix JCS-style canonical JSON}
\usage{
atx_canonicalize(obj)
}
\arguments{
\item{obj}{A JSON string, raw UTF-8 bytes, or a value tree produced by
\code{\link{atx_json_parse}}.}
}
\value{
A raw vector of the canonical UTF-8 bytes.
}
\description{
Reproduces \code{attestix/auth/crypto.py::canonicalize_json} byte-for-byte.
This is JCS-style, NOT strict RFC 8785: it additionally applies NFC Unicode
normalization to every string value and object key, collapses whole-number
floats to integers (\code{1.0 -> 1}), sorts keys by Unicode code point, uses
\code{","}/\code{":"} separators with no whitespace, emits raw UTF-8 (no
\code{\\uXXXX} escapes), and preserves large integers exactly.
}
\examples{
bytes <- atx_canonicalize('{"b":2,"a":1}')
rawToChar(bytes) # {"a":1,"b":2}
}
