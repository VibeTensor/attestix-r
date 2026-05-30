#' attestix: Offline verifier for Attestix credentials and delegations
#'
#' The \pkg{attestix} package verifies, fully offline, the verifiable
#' credentials and UCAN delegation chains issued by the Attestix Python core
#' (\url{https://github.com/VibeTensor/attestix}). No Python runtime is needed.
#'
#' Key entry points:
#' \itemize{
#'   \item \code{\link{atx_verify_credential}} — verify a W3C VC (Ed25519
#'         signature + expiry + revocation).
#'   \item \code{\link{atx_canonicalize}} — the JCS-style canonical form
#'         (\strong{NOT} strict RFC 8785; it additionally NFC-normalizes).
#'   \item \code{\link{atx_decode_did_key}} — decode an Ed25519 \code{did:key}
#'         to its raw 32-byte public key.
#'   \item \code{\link{atx_verify_delegation_chain}} — verify a UCAN delegation
#'         chain (per-link EdDSA + capability attenuation).
#' }
#'
#' The canonical form is the load-bearing detail: see the spec at
#' \url{https://attestix.io/spec/bundle/v1} and the conformance vectors vendored
#' under \code{inst/testdata/vectors.json}.
#'
#' @keywords internal
#' @importFrom sodium sig_verify
#' @importFrom openssl base64_decode base64_encode
#' @importFrom stringi stri_trans_nfc
"_PACKAGE"
