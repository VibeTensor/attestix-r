# attestix (R)

[![R-CMD-check](https://github.com/VibeTensor/attestix-r/actions/workflows/test.yml/badge.svg)](https://github.com/VibeTensor/attestix-r/actions/workflows/test.yml)
[![License: Apache-2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)

Offline verifier for the verifiable credentials and UCAN delegation chains
issued by the [Attestix](https://github.com/VibeTensor/attestix) Python core —
**no Python runtime needed**. Built for compliance, research and biostatistics
users who live in R and need to check AI-agent compliance credentials.

It verifies:

- **W3C Verifiable Credentials** signed with Ed25519 (RFC 8032).
- **`did:key`** Ed25519 identifiers (multibase base58btc + `0xed01` multicodec).
- **UCAN delegation chains** (EdDSA JWTs) including capability attenuation.

Every check is validated against the **shared cross-language conformance
vectors** (`inst/testdata/vectors.json`), the same oracle used by the Go, Rust,
Java and JS ports. The vectors are generated from the real attestix 0.4.0
crypto.

## The canonical form is JCS-*style*, not strict RFC 8785

This is the single most error-prone part of any port, so it is worth stating up
front. The Attestix canonical form is a **practical subset of JCS** that
**diverges from strict RFC 8785** in two load-bearing ways:

1. **NFC Unicode normalization** is applied to every string value and every
   object key. RFC 8785 explicitly does *not* normalize; Attestix does.
2. Whole-number floats collapse to integers (`1.0` -> `1`); non-whole floats use
   Python's `repr`. Signed payloads should avoid non-trivial floats (the vectors
   use only integers and `1.5`, on which all ports agree).

Otherwise: keys sorted by Unicode code point, `","`/`":"` separators with no
whitespace, raw UTF-8 output (no `\uXXXX` escapes), large integers preserved
exactly. The full spec is in the parent repo at
`spec/verify/v1/README.md` and the bundle wire format is published at
<https://attestix.io/spec/bundle/v1>.

## Install

```r
# system dependency: libsodium (e.g. `apt-get install libsodium-dev`)

# from GitHub:
# install.packages("remotes")
remotes::install_github("VibeTensor/attestix-r")

# once on CRAN (submission pending):
# install.packages("attestix")
```

## Verify a credential (10 lines)

```r
library(attestix)

# vc is the credential JSON (string, raw bytes, or a parsed value tree).
vc <- readChar("credential.json", file.info("credential.json")$size)

res <- atx_verify_credential(vc)            # issuer key auto-resolved from did:key
res$signature_valid                          # Ed25519 over JCS-canonical bytes
res$not_expired                              # now < expirationDate (tz-aware)
res$not_revoked                              # credentialStatus.revoked is falsy
res$verify                                   # TRUE only if all three hold

# canonical bytes, did:key decode, and delegation chains are first-class too:
atx_decode_did_key("did:key:z6Mko5TBPGKHkCxSgmf3aC6p6SGj2auwCfRmBydXJFEwL4ev")
```

## Public API

| Function | Purpose |
|---|---|
| `atx_verify_credential(vc, public_key, now)` | Verify a W3C VC (signature + expiry + revocation). |
| `atx_canonicalize(obj)` | JCS-style canonical UTF-8 bytes (the oracle). |
| `atx_decode_did_key(did)` | Decode an Ed25519 `did:key` to the raw 32-byte key. |
| `atx_verify_delegation_chain(chain, public_key)` | Verify a UCAN chain + attenuation. |
| `atx_ed25519_verify(message, signature, public_key)` | Raw Ed25519 verify. |

## Conformance

```r
# from the package source:
devtools::test()        # runs tests/testthat against inst/testdata/vectors.json
```

The CI workflow runs `R CMD check --as-cran` plus the vector suite on
`ubuntu-latest` across two R versions. The vectors are vendored verbatim from
the parent repo's `spec/verify/v1/vectors.json`.

## Relationship to the parent project

This is one of several language ports of the Attestix offline verifier. The
authoritative implementation and the issuing side live in the Python core at
[VibeTensor/attestix](https://github.com/VibeTensor/attestix). Project home:
[attestix.io](https://attestix.io).

## License

[Apache-2.0](./LICENSE).
