% Generated from R/json_parse.R
\name{atx_json_parse}
\alias{atx_json_parse}
\title{Minimal, deterministic JSON parser for canonicalisation}
\usage{
atx_json_parse(txt)
}
\arguments{
\item{txt}{JSON text (length-1 character) or raw UTF-8 bytes.}
}
\value{
The parsed value tree (objects as named lists, arrays as unnamed lists,
numbers as tagged \code{atx_number} lexemes, strings as character).
}
\description{
A hand-written recursive-descent JSON parser that preserves every number as a
tagged raw lexeme, so the canonicaliser can tell a big integer from a string
and a whole float (\code{1.0}) from a non-whole one (\code{1.5}). Distinguishes
empty object (\code{{}}) from empty array (\code{[]}).
}
\keyword{internal}
