## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new submission, so the "checking CRAN incoming feasibility ... NOTE
  / New submission" note is expected.

A second note may appear in offline check environments:
"checking for future file timestamps ... unable to verify current time". This
is an environment artifact (the check host could not reach the time service)
and does not reproduce when the clock service is reachable
(e.g. on win-builder or CRAN's machines). It can be silenced locally with
`_R_CHECK_SYSTEM_CLOCK_=0`.

## Test environments

- local WSL Ubuntu 24.04, R 4.3.3
- GitHub Actions ubuntu-latest (r-lib/actions), R release and R oldrel-1
- GitHub Actions ubuntu-latest (r-lib/actions), `R CMD check --as-cran`
- TODO before submission: win-builder (`devtools::check_win_devel()`) and
  R-hub, both of which require the maintainer to drive the email confirmation.

## This is a new submission.

attestix is the R port of the Attestix offline credential verifier. It verifies,
with no Python runtime, Ed25519 (RFC 8032) signatures over W3C Verifiable
Credentials and UCAN delegation chains (EdDSA JWTs with capability attenuation)
issued by the Attestix core. It reproduces the project's JCS-style JSON canonical
form byte-for-byte and is validated against the shared `spec/verify/v1`
conformance vectors (vendored under `inst/testdata/vectors.json`). The package
verifies only; it does not issue credentials. Published spec:
<https://attestix.io/spec/bundle/v1>. License: Apache-2.0.

## System requirements

- libsodium (for the `sodium` package). On Debian/Ubuntu: `libsodium-dev`.
  Both `sodium` and `openssl` are on CRAN and available on CRAN's check machines.

## Downstream dependencies

None (new package).

Maintainer: Pavan Kumar Dubasi <info@vibetensor.com>.
