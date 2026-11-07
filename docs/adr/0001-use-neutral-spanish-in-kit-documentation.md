# ADR-0001: Use Neutral Spanish in Kit Documentation

## Status

Accepted

## Context

The kit's human-facing prose was written in Rioplatense Spanish with voseo:
"Sos", "escribís", "podés", "tenés", "usá", "mergeá", and so on. It covers the
twelve agent prompts, `README.md`, `AGENTS.md`, the installation guide, and the
installer and selftest messages.

The kit is injected into arbitrary projects and its prompts are read by agents
working for teams in different Spanish-speaking regions. Voseo is regional, so
the wording made the documentation harder to reuse outside Argentina and harder
to read for non-native speakers. The user reported the regional Spanish while
building the presentation site with the kit.

`AGENTS.md` required Spanish for product documentation but did not name a
variety. The vendored skills are in English and are unaffected by this decision.

## Decision

All prose authored in this repository uses neutral Spanish:

- Second person "tú" and standard imperative forms. No voseo, no regionalisms.
- Git and CLI vocabulary (`push`, `commit`, `merge`, `PR`, `staging`) stays in
  English, because those are proper names of the tools. "deploy" in prose
  becomes "despliegue".
- Code, comments, identifiers, commits, and ADRs stay in English.

The convention is stated in `AGENTS.md` under "Idioma" and in the `tech-writer`,
`product-owner`, `business-analyst`, and `ux-designer` prompts, so new
documentation inherits it. `kit/selftest.sh` asserts that the prose installed
into a target project contains no voseo, which makes the convention
machine-checkable instead of review-dependent.

## Consequences

- The kit's documentation reads the same across Spanish-speaking regions and
  for non-native readers.
- The installer and selftest messages change wording. Those strings are
  user-facing, not a supported API.
- The selftest gains a language assertion, so reintroducing voseo fails the
  check instead of waiting for a review comment.
- Historical entries in `docs/context/decisions-log.md` keep their original
  wording, because that log is append-only. The convention applies to new
  entries.
