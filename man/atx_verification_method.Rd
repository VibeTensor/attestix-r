% Generated from R/didkey.R
\name{atx_verification_method}
\alias{atx_verification_method}
\title{Full verification method for a did:key}
\usage{
atx_verification_method(did)
}
\arguments{
\item{did}{A \code{did:key:z...} string.}
}
\value{
The verification-method string \code{<did>#<multibase>}.
}
\description{
Builds the \code{<did>#<multibase>} verification method for an Ed25519 did:key.
}
