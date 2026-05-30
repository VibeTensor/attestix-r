% Generated from R/didkey.R
\name{atx_did_key_fragment}
\alias{atx_did_key_fragment}
\title{Return the multibase fragment portion of a did:key}
\usage{
atx_did_key_fragment(did)
}
\arguments{
\item{did}{A \code{did:key:z...} string.}
}
\value{
The \code{#z...} fragment.
}
\description{
The verification method is \code{<did>#<multibase>} where \code{<multibase>}
is the \code{z...} portion of the did:key.
}
