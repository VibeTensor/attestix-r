% Generated from R/didkey.R
\name{atx_public_key_to_did_key}
\alias{atx_public_key_to_did_key}
\title{Encode a raw 32-byte Ed25519 public key to a did:key}
\usage{
atx_public_key_to_did_key(pubkey)
}
\arguments{
\item{pubkey}{A raw vector of length 32.}
}
\value{
A \code{did:key:z...} string.
}
\description{
Inverse of \code{\link{atx_decode_did_key}}.
}
