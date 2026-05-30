# CRAN submission comments

## Submission status

NOT yet submitted to CRAN. This file documents the intended submission so the
package is submission-ready; no submission has been made.

## Test environments

- GitHub Actions, ubuntu-latest, R release and R oldrel-1 (see
  `.github/workflows/test.yml`).
- Local `R CMD check --as-cran` should be run before any submission.

## R CMD check results

Target: 0 errors | 0 warnings | 0 notes.

Notes that may appear on a first submission and their resolution:

- "New submission" — expected for a first submission.
- The package links a system library (libsodium) via the `sodium` package and
  OpenSSL via the `openssl` package; both are declared in Imports and are
  available on CRAN's check machines.

## System requirements

- libsodium (for the `sodium` package). On Debian/Ubuntu: `libsodium-dev`.

## How to submit (when ready)

```r
# 1. Final local check
R CMD build .
R CMD check --as-cran attestix_0.4.0.tar.gz

# 2. Submit via the web form or:
# devtools::submit_cran()   # requires a maintainer email confirmation
```

Maintainer: Pavan Kumar Dubasi <pkd@vibetensor.com>.

Downstream dependencies: none (new package).
