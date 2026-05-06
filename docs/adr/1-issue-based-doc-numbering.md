# ADR-1: Use GitHub Issue numbers for AT/ADR file naming

- **Date**: 2026-05-06
- **Status**: Accepted
- **Issue**: none (recorded retroactively)
- **Related**: PR [#8](https://github.com/kompiro/hane/pull/8)

## Context

Acceptance tests under `docs/acceptance/` were named with a zero-padded
`NNNN-kebab.md` prefix and the next number was chosen as `max(existing) + 1`.
ADR file naming was deferred entirely to the host repository. Design Docs use
topic-only filenames.

This produced two friction points:

1. AT numbers had no relationship to GitHub Issue numbers, so tracing an AT
   back to the Issue that motivated it required reading the document body.
2. With parallel branches each picking `max + 1`, AT number collisions on
   merge were a known hazard — `review-docs` already documented that
   re-numbering is unsafe because external references (Issues, PR comments,
   commit messages) point at AT numbers.

We wanted a single numbering source that is unique across parallel work and
trivially traceable back to the Issue tracker.

## Decision

Adopt GitHub Issue numbers as the primary numbering source for AT and ADR
files:

- **Acceptance Test**: `docs/acceptance/<issue>-kebab-title.md`, heading
  `AT-<issue>`. No zero-padding (Issue numbers are variable width). Multiple
  ATs per Issue are allowed and disambiguated by the kebab slug
  (e.g. `42-login-form.md`, `42-login-error.md`). When no Issue exists, fall
  back to local sequential numbering (`max + 1`, no zero-padding) and never
  rename later — the AT body's `Issue:` field carries the linkage instead.
- **ADR**: `docs/adr/<issue>-kebab-title.md`, heading `ADR-<issue>`. Host
  repo conventions (e.g. `YYYYMMDD-NN-description.md`) take precedence when
  the host repo has already adopted them.
- **Design Doc**: filenames stay topic-only — 1 Issue ≠ 1 Design Doc, since
  the exploratory phase often spawns several docs per Issue or none at all.
  An `Issue:` meta field records the linkage when one exists.
- **review-docs**: same-Issue multi-AT is allowed; only collisions between
  Issue-based and local-fallback numbering are warned. Existing
  `NNNN-`-prefixed files are left as-is to preserve external references.

## Consequences

**Positive**

- AT and ADR numbers are globally unique without coordination — Issue
  numbers are assigned by GitHub.
- One-hop traceability from a doc filename to its Issue and back.
- The `start-dev` flow is already Issue-driven, so the new convention
  composes cleanly with the existing skill chain.

**Negative**

- Writing an AT now presumes an Issue exists. Pre-Issue exploratory ATs
  must use local numbering and accept that they will not be renamed when
  an Issue is later filed (the body's `Issue:` field bridges the gap).
- The new and legacy naming styles coexist in repos that already have
  `NNNN-`-prefixed ATs. `review-docs` accepts both rather than forcing a
  migration.

## Alternatives considered

- **Keep `NNNN-` zero-padded local numbering** — rejected because parallel
  branches keep producing collisions and the numbers carry no semantic
  link to the work they describe.
- **Make ADRs use Issue numbers but leave AT alone** — rejected; AT is the
  artifact most often referenced externally (PR descriptions, commit
  messages), so it benefits most from the change.
- **Force-rename existing `NNNN-` ATs in host repos** — rejected; external
  references would silently break.
