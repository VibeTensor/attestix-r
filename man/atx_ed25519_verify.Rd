% Generated from R/ed25519.R
\name{atx_ed25519_verify}
\alias{atx_ed25519_verify}
\title{Verify an Ed25519 (RFC 8032) signature}
\usage{
atx_ed25519_verify(message, signature, public_key)
}
\arguments{
\item{message}{Raw vector of the signed message bytes.}
\item{signature}{Raw vector, 64 bytes.}
\item{public_key}{Raw vector, 32 bytes.}
}
\value{
\code{TRUE} if the signature is valid, else \code{FALSE}.
}
\description{
Thin wrapper over \code{sodium::sig_verify} (libsodium); returns a logical
rather than signalling.
}
\examples{
\dontrun{
atx_ed25519_verify(msg, sig, pubkey)
}
}
