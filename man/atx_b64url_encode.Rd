% Generated from R/encoding.R
\name{atx_b64url_encode}
\alias{atx_b64url_encode}
\title{base64url encode with padding}
\usage{
atx_b64url_encode(bytes)
}
\arguments{
\item{bytes}{A raw vector.}
}
\value{
A length-1 base64url string (padded).
}
\description{
Matches Python \code{base64.urlsafe_b64encode} (padded output).
}
\keyword{internal}
