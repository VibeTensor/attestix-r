# Submitting attestix to CRAN

This package is CRAN-submission-ready: `R CMD check --as-cran` is clean
(0 errors, 0 warnings, only the unavoidable "New submission" note). The actual
submission is a human web-form step and is **not** automated. Follow the steps
below.

The maintainer email in `DESCRIPTION` is `info@vibetensor.com`. CRAN sends a
confirmation email there during submission; the maintainer must be able to read
and reply from that address.

## 1. Pre-submission checks (maintainer-driven)

CRAN requires a Windows check result and recommends R-hub. These need the
maintainer's email for confirmation, so they cannot be run headlessly here.

```r
# From the package root, in R:
install.packages("devtools")
devtools::check_win_devel()   # uploads to win-builder.r-project.org;
                              # results are emailed to info@vibetensor.com
# Optionally also:
devtools::check_win_release()
```

Alternatively upload the tarball directly at <https://win-builder.r-project.org/>.

R-hub (recommended, optional):

```r
install.packages("rhub")
rhub::rhub_setup()    # one-time, validates the maintainer email
rhub::rhub_check()
```

Confirm win-builder reports the same clean result (0 errors / 0 warnings /
"New submission" note only) before proceeding.

## 2. Build the tarball

```sh
R CMD build .
# produces attestix_0.4.0.tar.gz
```

## 3. Submit

1. Go to <https://cran.r-project.org/submit.html>.
2. Maintainer name: Pavan Kumar Dubasi. Email: `info@vibetensor.com`.
3. Upload `attestix_0.4.0.tar.gz`.
4. Paste the contents of `cran-comments.md` into the comments box.
5. Submit.

## 4. Confirm

- CRAN sends an auto-generated confirmation email to `info@vibetensor.com`.
  Click the confirmation link / reply as instructed. **The submission is not
  queued until this is confirmed.**
- First submissions get a **manual review** by a CRAN volunteer. Expect
  anywhere from a couple of days to ~2 weeks, possibly with requested changes.
- If changes are requested, address them, bump the version if asked, update
  `cran-comments.md` to note it is a resubmission, and repeat from step 1.

## Notes

- Do not skip the win-builder / R-hub step — CRAN expects a Windows check and
  will reject submissions that fail on Windows.
- The package is a **verifier only**: it verifies Ed25519 W3C VCs and UCAN
  delegations; it does not issue credentials. Keep this framing in any
  description CRAN asks you to clarify.
