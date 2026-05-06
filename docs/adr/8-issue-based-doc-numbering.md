# ADR-8: Use GitHub Issue or PR numbers for AT/ADR file naming

- **Date**: 2026-05-06
- **Status**: Accepted
- **Issue**: none — numbered after PR [#8](https://github.com/kompiro/hane/pull/8) per the fallback rule this ADR establishes
- **Related**: PR [#8](https://github.com/kompiro/hane/pull/8) (skill changes), PR [#9](https://github.com/kompiro/hane/pull/9) (this record)

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
trivially traceable back to GitHub.

## Decision

Number AT and ADR files from GitHub identifiers, with this priority order:

1. **Linked GitHub Issue number** (preferred).
2. **PR number** when no Issue exists but a PR does (e.g. retroactive
   records, drive-by docs that were merged via PR without an Issue).
3. **Local sequential** (`max(existing) + 1`, no zero-padding) only when
   neither exists yet (e.g. AT drafted before any branch is pushed).

Common rules:

- No zero-padding — Issue and PR numbers are variable width.
- Multiple docs per number are allowed and disambiguated by the kebab slug
  (e.g. `42-login-form.md`, `42-login-error.md`).
- Once a number is assigned, **never rename** the file. External references
  (Issues, PR descriptions, commit messages, AT cross-links) point at the
  number, and renaming silently breaks them. If a later Issue gets filed
  for an AT that was already given a PR-fallback or local number, record
  the new linkage in the body's `Issue:` field instead.

Per-doc-type specifics:

- **Acceptance Test**: `docs/acceptance/<number>-kebab-title.md`, heading
  `AT-<number>`. ATs are typically created on a feature branch before the
  PR is opened — pushing the branch (or opening a draft PR) early to claim
  a PR number is the recommended path when no Issue exists.
- **ADR**: `docs/adr/<number>-kebab-title.md`, heading `ADR-<number>`. Host
  repo conventions (e.g. `YYYYMMDD-NN-description.md`) take precedence
  when the host repo has already adopted them.
- **Design Doc**: filenames stay topic-only — 1 Issue ≠ 1 Design Doc,
  since the exploratory phase often spawns several docs per Issue or
  none at all. An `Issue:` meta field records the linkage when one exists.
- **review-docs**: same-Issue/PR multi-AT is allowed; only collisions
  between distinct numbering sources (e.g. Issue #5 and a local-fallback
  `5-`) are warned. Existing `NNNN-`-prefixed files are left as-is to
  preserve external references.

## Consequences

**Positive**

- AT and ADR numbers are globally unique without coordination — GitHub
  assigns them.
- One-hop traceability from a doc filename to its Issue or PR and back.
- The `start-dev` flow is already Issue-driven, so the new convention
  composes cleanly with the existing skill chain.
- Retroactive records (like this ADR itself) get a stable, externally
  meaningful number via the PR fallback instead of an opaque local seq.

**Negative**

- Writing an AT before any branch is pushed forces a choice between
  using local fallback (and accepting it will not be renamed later) or
  pushing/opening a draft PR earlier than usual to claim a number.
- The new and legacy naming styles coexist in repos that already have
  `NNNN-`-prefixed ATs. `review-docs` accepts both rather than forcing
  a migration.
- Three numbering sources (Issue / PR / local) means the rule is more
  to remember than a single-source scheme; mitigated by having a clear
  priority order.

## Alternatives considered

- **Keep `NNNN-` zero-padded local numbering** — rejected because parallel
  branches keep producing collisions and the numbers carry no semantic
  link to the work they describe.
- **Issue number only, no PR fallback** — rejected; retroactive records
  and Issue-less drive-by changes (this ADR's own situation) would be
  stuck on opaque local numbers.
- **PR number as the primary source** — rejected; Issues exist before
  branches and are the natural unit of work, and PR numbers don't exist
  at the moment most ATs are first drafted.
- **Force-rename existing `NNNN-` ATs in host repos** — rejected; external
  references would silently break.
