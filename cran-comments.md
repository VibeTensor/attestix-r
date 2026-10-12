## Update to 0.4.2

This update rejects normalized-key collisions, malformed present expiry,
and unsafe numeric coercion, and clarifies verifier trust and revocation limits.
It uses the supported Attestix canonical profile, rather than claiming arbitrary
cross-language numeric equivalence or strict RFC 8785 conformance.

## Validation

GitHub Actions checks R release and oldrel-1, plus a separate full-manual
R CMD check --as-cran job that fails on notes and warnings. Use the checks
for the final release commit as submission evidence.

## Submission gates

The maintainer must complete any requested win-builder or R-hub confirmations
and submit the source tarball to CRAN. Preparing a tarball or GitHub release
does not publish an update to CRAN.

## System requirements

libsodium development headers are required when installing the sodium dependency
from source. Both sodium and openssl are available from CRAN.

Maintainer: Pavan Kumar Dubasi <info@vibetensor.com>.
