% Generated from R/verify_delegation.R
\name{atx_verify_ucan_token}
\alias{atx_verify_ucan_token}
\title{Verify a single UCAN JWT}
\usage{
atx_verify_ucan_token(token, public_key, now = Sys.time(),
  revoked_jti = character(0))
}
\arguments{
\item{token}{A compact JWT string.}
\item{public_key}{The Ed25519 server public key (raw 32 bytes or hex).}
\item{now}{Reference time (POSIXct or epoch). Defaults to \code{Sys.time()}.}
\item{revoked_jti}{Optional character vector of revoked \code{jti} values.}
}
\value{
A list with \code{signature_valid}, \code{not_expired}, \code{not_revoked},
\code{alg_ok}, \code{jti}, \code{att}, and \code{valid}.
}
\description{
Per-token UCAN checks: signature, \code{alg=EdDSA} only (\code{alg:none} is
rejected), expiry, and revocation by \code{jti}.
}
\keyword{internal}
