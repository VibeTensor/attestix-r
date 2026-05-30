# Focused unit tests for the canonicaliser's divergence-prone rules.
# No non-ASCII literals appear in this source file; Unicode inputs are built
# from code points so the file's own encoding cannot perturb them.

test_that("keys are sorted by Unicode code point", {
  expect_equal(rawToChar(atx_canonicalize('{"b":1,"a":2,"c":3}')),
               '{"a":2,"b":1,"c":3}')
})

test_that("no whitespace and compact separators", {
  expect_equal(rawToChar(atx_canonicalize('{ "a" : [1, 2 , 3] }')),
               '{"a":[1,2,3]}')
})

test_that("whole-number floats collapse to integers", {
  out <- rawToChar(atx_canonicalize('{"x":1.0,"y":2.0,"z":1.5}'))
  expect_equal(out, '{"x":1,"y":2,"z":1.5}')
})

test_that("large integers are preserved exactly (no float coercion)", {
  out <- rawToChar(atx_canonicalize('{"big":9007199254740993}'))
  expect_equal(out, '{"big":9007199254740993}')
})

test_that("negative integers and nesting", {
  out <- rawToChar(atx_canonicalize('{"n":-42,"d":{"y":[3,2,1],"x":"z"}}'))
  expect_equal(out, '{"d":{"x":"z","y":[3,2,1]},"n":-42}')
})

test_that("empty object and empty array are distinguished", {
  out <- rawToChar(atx_canonicalize('{"o":{},"a":[]}'))
  expect_equal(out, '{"a":[],"o":{}}')
})

test_that("non-ASCII is emitted as raw UTF-8, not unicode escapes", {
  # value "cafe" + U+00E9 (precomposed) -> bytes ... 63 61 66 c3 a9
  e_acute <- intToUtf8(0x00E9L)
  Encoding(e_acute) <- "UTF-8"
  txt <- paste0('{"k":"caf', e_acute, '"}')
  bytes <- atx_canonicalize(txt)
  expect_equal(atx_raw_to_hex(bytes), "7b226b223a22636166c3a9227d")
})

test_that("NFC normalization composes decomposed sequences", {
  # "cafe" + U+0301 (combining acute) must normalize to "caf" + U+00E9.
  dec <- intToUtf8(c(utf8ToInt("cafe"), 0x0301L))
  Encoding(dec) <- "UTF-8"
  decomposed <- paste0('{"k":"', dec, '"}')
  com <- intToUtf8(c(utf8ToInt("caf"), 0x00E9L))
  Encoding(com) <- "UTF-8"
  composed <- paste0('{"k":"', com, '"}')
  expect_equal(atx_canonicalize(decomposed), atx_canonicalize(composed))
  expect_equal(atx_raw_to_hex(atx_canonicalize(decomposed)),
               "7b226b223a22636166c3a9227d")
})

test_that("4-byte emoji survives as raw UTF-8", {
  # U+1F600 grinning face -> f0 9f 98 80
  emoji <- intToUtf8(0x1F600L)
  Encoding(emoji) <- "UTF-8"
  txt <- paste0('{"k":"', emoji, '"}')
  expect_equal(atx_raw_to_hex(atx_canonicalize(txt)),
               "7b226b223a22f09f9880227d")
})

test_that("base58 round-trips arbitrary bytes", {
  for (h in c("00", "0001", "ed018022fe847be6", "ffffffff")) {
    r <- atx_hex_to_raw(h)
    expect_equal(atx_base58_decode(atx_base58_encode(r)), r, info = h)
  }
})

test_that("booleans and null literals", {
  expect_equal(rawToChar(atx_canonicalize('{"t":true,"f":false,"n":null}')),
               '{"f":false,"n":null,"t":true}')
})
