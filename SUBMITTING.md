# Submitting attestix to CRAN

The 0.4.2 GitHub release is separate from CRAN publication. As checked on
2026-10-30, the [CRAN package index](https://cran.r-project.org/src/contrib/PACKAGES.gz)
lists 0.4.1. Run the checks below for the exact source being submitted and use
their current results as evidence. Submission is a maintainer web-form step
and is **not** automated by the `cran-tarball` workflow.

The maintainer email in `DESCRIPTION` is `info@vibetensor.com`. CRAN sends a
confirmation email there during submission; the maintainer must be able to read
and reply from that address.

## 1. Pre-submission checks (maintainer-driven)

The maintainer should obtain current Windows check results and review CRAN's
[submission guidance](https://cran.r-project.org/submit.html). The services below
can upload source and send confirmation or result emails; run them only when
the maintainer is ready to complete those steps.

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

Review and resolve check errors, warnings and notes before proceeding. Include
the final release commit's GitHub Actions full-manual and release/old-release
checks in the submission evidence.

## 2. Build the tarball

```sh
R CMD build .
# produces attestix_0.4.2.tar.gz
```

## 3. Submit

1. Go to <https://cran.r-project.org/submit.html>.
2. Maintainer name: Pavan Kumar Dubasi. Email: `info@vibetensor.com`.
3. Upload the checked `attestix_0.4.2.tar.gz`.
4. Paste the contents of `cran-comments.md` into the comments box.
5. Submit.

## 4. Confirm

- CRAN sends an auto-generated confirmation email to `info@vibetensor.com`.
  Click the confirmation link / reply as instructed. **The submission is not
  queued until this is confirmed.**
- CRAN reviews submissions and may request changes; acceptance and timing are
  determined by CRAN.
- If changes are requested, address them, bump the version if asked, update
  `cran-comments.md` to note it is a resubmission, and repeat from step 1.

## Notes

- The package is a **verifier only** for the supported Attestix credential and
  delegation profile. It does not issue credentials or establish legal
  conformity. Keep this framing in any description CRAN asks you to clarify.
- Confirm the accepted version in the CRAN package index after submission;
  a successful tarball build or GitHub release is not registry publication.
