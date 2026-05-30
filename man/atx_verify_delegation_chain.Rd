% Generated from R/verify_delegation.R
\name{atx_verify_delegation_chain}
\alias{atx_verify_delegation_chain}
\title{Verify a UCAN delegation chain (Ed25519 per link + attenuation)}
\usage{
atx_verify_delegation_chain(chain, public_key, now = Sys.time(),
  revoked_jti = character(0))
}
\arguments{
\item{chain}{A list describing the chain. Accepts the conformance-vector shape
(\code{parent_token}, \code{token}, and optional \code{parent_att} /
\code{child_att}) or a list of compact JWT strings ordered root-first.}
\item{public_key}{The Ed25519 server public key (raw 32 bytes or hex).}
\item{now}{Reference time. Defaults to \code{Sys.time()}.}
\item{revoked_jti}{Optional revoked \code{jti} character vector.}
}
\value{
A list with \code{parent_signature_valid}, \code{child_signature_valid},
\code{attenuation_is_subset}, and the overall \code{verify}.
}
\description{
Mirrors the recursive \code{prf}-chain verification in
\code{attestix/services/delegation_service.py}. Each token is a PyJWT EdDSA
JWT; the signed message is the compact \code{header.payload} form (base64url
unpadded), NOT the JCS canonical form. The chain verifies iff every token's
signature is valid and unexpired/unrevoked AND each child's \code{att} is a
subset of its parent's \code{att} (escalation is rejected). Cycles (repeated
\code{jti}) are rejected.
}
\examples{
\dontrun{
atx_verify_delegation_chain(list(parent_token = pt, token = ct), pk)
}
}
