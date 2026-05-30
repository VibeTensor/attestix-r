% Generated from R/verify_credential.R
\name{atx_verify_credential}
\alias{atx_verify_credential}
\title{Verify an Attestix W3C Verifiable Credential offline}
\usage{
atx_verify_credential(vc, public_key = NULL, now = Sys.time())
}
\arguments{
\item{vc}{The credential as a JSON string, raw UTF-8 bytes, or a value tree
from \code{\link{atx_json_parse}}.}
\item{public_key}{The issuer Ed25519 public key: a raw 32-byte vector, a
64-char hex string, or \code{NULL} to derive it from the credential's
\code{issuer.id} / \code{verificationMethod} did:key.}
\item{now}{Reference time for the expiry check (POSIXct or ISO-8601 string).
Defaults to \code{Sys.time()}.}
}
\value{
A list with logical fields \code{signature_valid}, \code{not_expired},
\code{not_revoked}, \code{structure_valid}, and the overall \code{verify}.
}
\description{
Mirrors \code{attestix/services/credential_service.py::verify_credential}.
The signing payload is the credential with the \code{proof} and
\code{credentialStatus} top-level keys removed, JCS-style canonicalized, with
the Ed25519 signature in \code{proof.proofValue} verified against the issuer
public key. The overall result ANDs signature validity, non-expiry and
non-revocation.
}
\examples{
\dontrun{
res <- atx_verify_credential(vc_json)
isTRUE(res$verify)
}
}
