% Generated from R/verify_delegation.R
\name{atx_jwt_decode}
\alias{atx_jwt_decode}
\title{Decode a JWT compact token without verifying}
\usage{
atx_jwt_decode(token)
}
\arguments{
\item{token}{A compact JWT (\code{header.payload.signature}).}
}
\value{
A list with \code{header}, \code{payload}, \code{signing_input} (raw bytes of
\code{header.payload}), and \code{signature} (raw bytes).
}
\description{
Splits and base64url-decodes a compact JWT into its parts; does not verify.
}
\keyword{internal}
