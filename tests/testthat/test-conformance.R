# Cross-language conformance: assert every shared vector in vectors.json.
# These vectors are the authoritative oracle generated from the real attestix
# 0.4.0 crypto. A failing vector means this port is wrong, not the vector.

load_vectors <- function() {
  path <- system.file("testdata", "vectors.json", package = "attestix")
  if (!nzchar(path)) {
    # When running from source (devtools::test) before install.
    path <- testthat::test_path("..", "..", "inst", "testdata", "vectors.json")
  }
  txt <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  jsonlite::fromJSON(txt, simplifyVector = FALSE, simplifyDataFrame = FALSE)
}

vectors_doc <- load_vectors()
server_pubkey_hex <- vectors_doc$issuer_pubkey_raw_hex
server_pubkey <- atx_hex_to_raw(server_pubkey_hex)

by_kind <- function(kind) {
  Filter(function(v) v$kind == kind, vectors_doc$vectors)
}

test_that("vectors.json loaded and well-formed", {
  expect_equal(vectors_doc$spec, "attestix-verify-conformance")
  expect_equal(vectors_doc$version, "v1")
  expect_equal(length(vectors_doc$vectors), vectors_doc$vector_count)
  expect_gte(length(vectors_doc$vectors), 7L)
})

# ---- canonicalize -----------------------------------------------------------

test_that("canonicalize vectors match canonical_bytes_hex byte-for-byte", {
  for (v in by_kind("canonicalize")) {
    got <- atx_canonicalize(v$input)
    got_hex <- atx_raw_to_hex(got)
    expect_equal(got_hex, v$canonical_bytes_hex,
                 info = paste("vector", v$id, "canonical bytes mismatch"))
    # And the decoded UTF-8 must equal expected$canonical_utf8.
    got_str <- rawToChar(got)
    Encoding(got_str) <- "UTF-8"
    expect_equal(got_str, v$expected$canonical_utf8,
                 info = paste("vector", v$id, "canonical utf8 mismatch"))
  }
})

# ---- did:key ----------------------------------------------------------------

test_that("did_key_decode vectors round-trip to the raw 32-byte key", {
  for (v in by_kind("did_key_decode")) {
    did <- v$input$did
    raw <- atx_decode_did_key(did)
    expect_equal(length(raw), 32L, info = v$id)
    expect_equal(atx_raw_to_hex(raw), v$expected$pubkey_raw_hex, info = v$id)
    expect_equal(v$expected$multicodec_prefix_hex, "ed01", info = v$id)
    # verification method and fragment.
    expect_equal(atx_verification_method(did),
                 v$expected$verification_method, info = v$id)
    expect_equal(atx_did_key_fragment(did),
                 v$expected$fragment, info = v$id)
    # round-trip: re-encode raw -> did.
    expect_equal(atx_public_key_to_did_key(raw), did, info = v$id)
  }
})

# ---- verifyCredential -------------------------------------------------------

# A fixed reference time in the credentials' validity window (post-2021,
# pre-2027) so the valid/tampered VCs are not-expired and the expired VC is.
ref_now <- as.POSIXct("2026-01-01T00:00:00", format = "%Y-%m-%dT%H:%M:%S",
                      tz = "UTC")

test_that("verify_credential vectors produce the expected structured result", {
  for (v in by_kind("verify_credential")) {
    res <- atx_verify_credential(v$input, public_key = server_pubkey,
                                 now = ref_now)
    exp <- v$expected
    expect_equal(res$signature_valid, exp$signature_valid,
                 info = paste(v$id, "signature_valid"))
    expect_equal(res$not_expired, exp$not_expired,
                 info = paste(v$id, "not_expired"))
    expect_equal(res$not_revoked, exp$not_revoked,
                 info = paste(v$id, "not_revoked"))
    expect_equal(res$verify, exp$verify,
                 info = paste(v$id, "verify"))
  }
})

test_that("verify_credential canonical signing bytes match the vector", {
  for (v in by_kind("verify_credential")) {
    if (is.null(v$canonical_bytes_hex)) next
    payload <- v$input[setdiff(names(v$input), c("proof", "credentialStatus"))]
    got_hex <- atx_raw_to_hex(atx_canonicalize(payload))
    expect_equal(got_hex, v$canonical_bytes_hex,
                 info = paste(v$id, "signing canonical bytes"))
  }
})

test_that("verify_credential derives the issuer key from the did:key", {
  # Without an explicit public_key, the verifier must resolve issuer.id.
  valid <- Filter(function(v) v$id == "vc-valid-001", vectors_doc$vectors)[[1]]
  res <- atx_verify_credential(valid$input, public_key = NULL, now = ref_now)
  expect_true(res$signature_valid)
  expect_true(res$verify)
})

# ---- verifyDelegationChain --------------------------------------------------

test_that("verify_delegation_chain vectors produce the expected result", {
  for (v in by_kind("verify_delegation_chain")) {
    res <- atx_verify_delegation_chain(v$input, public_key = server_pubkey,
                                       now = ref_now)
    exp <- v$expected
    expect_equal(res$parent_signature_valid, exp$parent_signature_valid,
                 info = paste(v$id, "parent_signature_valid"))
    expect_equal(res$child_signature_valid, exp$child_signature_valid,
                 info = paste(v$id, "child_signature_valid"))
    expect_equal(res$attenuation_is_subset, exp$attenuation_is_subset,
                 info = paste(v$id, "attenuation_is_subset"))
    expect_equal(res$verify, exp$verify, info = paste(v$id, "verify"))
  }
})

test_that("alg:none UCAN tokens are rejected", {
  # Forge an alg:none header over a valid payload; signature must not verify.
  v <- by_kind("verify_delegation_chain")[[1]]
  child <- v$input$token
  parts <- strsplit(child, ".", fixed = TRUE)[[1]]
  none_hdr <- atx_b64url_encode(charToRaw('{"alg":"none","typ":"JWT"}'))
  none_hdr <- sub("=+$", "", none_hdr)
  forged <- paste(none_hdr, parts[2], parts[3], sep = ".")
  tok <- atx_verify_ucan_token(forged, server_pubkey, now = ref_now)
  expect_false(tok$alg_ok)
  expect_false(tok$signature_valid)
  expect_false(tok$valid)
})
