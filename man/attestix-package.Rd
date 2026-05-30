% Generated from R/attestix-package.R
\docType{package}
\name{attestix-package}
\alias{attestix}
\alias{attestix-package}
\title{attestix: Offline verifier for Attestix credentials and delegations}
\description{
The attestix package verifies, fully offline, the verifiable credentials and
UCAN delegation chains issued by the Attestix Python core
(\url{https://github.com/VibeTensor/attestix}). No Python runtime is needed.
Key entry points are \code{\link{atx_verify_credential}},
\code{\link{atx_canonicalize}}, \code{\link{atx_decode_did_key}} and
\code{\link{atx_verify_delegation_chain}}.
}
\seealso{
The bundle wire format at \url{https://attestix.io/spec/bundle/v1} and the
conformance vectors vendored under \code{inst/testdata/vectors.json}.
}
\author{
Pavan Kumar Dubasi
}
\keyword{internal}
