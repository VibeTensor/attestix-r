% Generated from R/encoding.R
\name{atx_b64url_decode}
\alias{atx_b64url_decode}
\title{base64url decode (accepts padded or unpadded input)}
\usage{
atx_b64url_decode(s)
}
\arguments{
\item{s}{A length-1 base64url string.}
}
\value{
A raw vector.
}
\description{
Accepts both the padded base64url used by VC \code{proofValue} and the
unpadded base64url used by JWT compact segments.
}
\keyword{internal}
