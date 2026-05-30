% Generated from R/didkey.R
\name{atx_decode_did_key}
\alias{atx_decode_did_key}
\title{Decode an Ed25519 did:key to its raw 32-byte public key}
\usage{
atx_decode_did_key(did)
}
\arguments{
\item{did}{A \code{did:key:z...} string.}
}
\value{
A raw vector of length 32 (the Ed25519 public key).
}
\description{
Reproduces \code{attestix/auth/crypto.py::did_key_to_public_key}: strip the
\code{did:key:z} prefix, base58btc-decode, assert the \code{0xed 0x01}
multicodec prefix, and return the remaining 32 raw bytes.
}
\examples{
did <- "did:key:z6Mko5TBPGKHkCxSgmf3aC6p6SGj2auwCfRmBydXJFEwL4ev"
length(atx_decode_did_key(did)) # 32
}
