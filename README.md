# Attestix verifier for R

Offline verification of signed credentials and parent/child delegation pairs
issued by the [Attestix Python core](https://github.com/VibeTensor/attestix).
No Python runtime is required. This package checks technical evidence;
a valid signature does not establish the truth or legal conformity of its claims.

## Install from source

Requires R >= 4.0.0 and the `sodium`, `openssl` and `stringi` dependencies.
The `sodium` package may require system libsodium development headers.

```r
# install.packages("remotes")
remotes::install_github(
  "VibeTensor/attestix-r@38b530c6a62d429a9762d6c92cb01f4e937a7dd5"
)
```

The revision pins the source described here. Review changes before choosing a
new revision; source installation is separate from any package-registry release.

## Verify a credential

```r
library(attestix)
vc <- readChar("credential.json", file.info("credential.json")$size)
result <- atx_verify_credential(vc)
result$signature_valid
result$not_expired
result$not_revoked
result$structure_valid
result$verify
```

Use original JSON text or raw UTF-8 bytes when integer precision matters.
Converting JSON to ordinary R doubles first can lose integer precision.

Automatic key resolution uses the signed issuer's Ed25519 `did:key` and rejects
a conflicting `proof.verificationMethod`. An explicit `public_key` overrides
that resolution: the caller must obtain the key from a trusted source and bind
it to the expected issuer. Key resolution alone is not an issuer allowlist.

`expirationDate` is checked when present; a malformed present value fails.
`not_revoked` reads the supplied `credentialStatus.revoked` flag. The status is
excluded from the signed payload, and this offline verifier does not fetch an
external registry or establish current revocation status. Applications must
supply a separate trusted, fresh revocation policy and enforce their own expiry
requirements. Removing unsigned status cannot establish that a credential is live.

## Delegation and public API

| Function | Scope |
| --- | --- |
| `atx_verify_credential(vc, public_key, now)` | Credential signature, supplied expiry/status and structural checks. |
| `atx_verify_ucan_token(token, public_key, now, revoked_jti)` | EdDSA token checks with caller-supplied key, time and revoked IDs. |
| `atx_verify_delegation_chain(chain, public_key, now, revoked_jti)` | Parent/child signatures, capability subset and pair cycle checks. |
| `atx_canonicalize(obj)` | Attestix canonical bytes, rejecting normalized-key ambiguity and unsupported numbers. |
| `atx_decode_did_key(did)` | Raw Ed25519 key from `did:key`. |
| `atx_ed25519_verify(message, signature, public_key)` | Raw signature verification. |

Pass the signed parent and child tokens for delegation decisions. The chain
helper evaluates one pair; list input selects the first and last token, rather
than validating every intermediate hop. Caller-provided `parent_att`/`child_att`
fields override token capability sets and must not be accepted from an untrusted
request. Applications must validate each hop and apply their resource/action,
identity and replay policies separately.

## Canonicalization and interoperability

This is the custom Attestix v1 format, not strict RFC 8785/JCS or a general W3C
proof-suite implementation. It NFC-normalizes strings and object keys, sorts
keys and collapses supported whole-number floats to integers. Normalized-key
collisions and unsupported numeric values fail. JSON text preserves integer
lexemes; arbitrary floating-point interoperability is not guaranteed.

The [verification specification](https://github.com/VibeTensor/attestix/tree/main/spec/verify/v1)
and `inst/testdata/vectors.json` define the tested profile. Passing shared and
negative vectors establishes those cases, not universal standards conformance,
legal compliance, a SOC 2 report or ISO certification.

## Development

```r
# From the source checkout, with package dependencies installed:
roxygen2::roxygenise()
testthat::test_local()
```

CI checks release and old-release R, package examples, generated help and shared
vectors. Additional workflows check manual PDF/HTML and source-package contents.
These checks are engineering evidence, not a promise about every environment.

## License

[Apache-2.0](LICENSE). Project home: [attestix.io](https://attestix.io).
