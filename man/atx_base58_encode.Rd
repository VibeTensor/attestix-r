% Generated from R/base58.R
\name{atx_base58_encode}
\alias{atx_base58_encode}
\title{Encode raw bytes to a base58btc string}
\usage{
atx_base58_encode(bytes)
}
\arguments{
\item{bytes}{A raw vector.}
}
\value{
A length-1 character string.
}
\description{
Base58btc (Bitcoin alphabet) encoder, vendored with no external dependency.
Used for did:key multibase \code{z} payloads.
}
\keyword{internal}
