test_that("normalized key collisions are rejected", {
 expect_error(atx_canonicalize('{"\u00e9":1,"e\u0301":2}'), "duplicate normalized")
})
test_that("large whole floats do not overflow a 32 bit integer", {
 expect_equal(rawToChar(atx_canonicalize('{"n":3000000000.0}')), '{"n":3000000000}')
})
test_that("unsupported floats fail closed", {
 expect_error(atx_canonicalize('{"n":1e309}'), "non-finite")
 expect_error(atx_canonicalize('{"n":-0.0}'), "signed zero")
})
test_that("present malformed expiry fails closed", {
 now <- as.POSIXct("2026-06-01", tz="UTC")
 for (expiry in list(NULL, FALSE, 123, "", "invalid")) {
  expect_false(attestix:::.atx_check_not_expired(expiry, now))
 }
})

test_that("malformed pinned keys fail closed", {
 tree <- list(issuer = "did:key:z6Mko5TBPGKHkCxSgmf3aC6p6SGj2auwCfRmBydXJFEwL4ev")
 expect_null(attestix:::.atx_resolve_pubkey(as.raw(1), tree))
 expect_null(attestix:::.atx_resolve_pubkey("invalid-hex", tree))
})
