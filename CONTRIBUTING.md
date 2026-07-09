# Contributing to hane

Thanks for your interest in `hane` (羽) — a plugin of reusable Claude Code skills for a branch/worktree-based PR workflow, design docs, acceptance tests, and doc maintenance. This guide explains how the repo is laid out and the conventions a contribution is expected to follow.

By participating you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md).

## Repository layout

```
hane/
├── skills/<name>/SKILL.md   ← one skill per directory; SKILL.md is the skill body
│   └── *TEMPLATE.md         ← document skeletons owned by the skill (e.g. ADR-TEMPLATE.md)
├── .claude-plugin/
│   ├── plugin.json          ← plugin manifest
│   └── marketplace.json     ← marketplace entry
├── hooks/hooks.json         ← plugin hooks
├── docs/
│   ├── adr/                 ← Architecture Decision Records (Japanese, issue-numbered)
│   └── acceptance/          ← acceptance test records
├── README.md                ← plugin overview, install, conventions, releasing
└── CHANGELOG.md             ← Keep a Changelog format
```

This repo holds only the skill files and manifests — there is **no build or test tooling**. Skill quality is validated by dogfooding and by the downstream repos that use the plugin (e.g. [`kompiro/karasu`](https://github.com/kompiro/karasu)).

## Use hane to develop hane (dogfooding)

`hane` is developed with its own skills. Prefer:

- `/hane:start-dev` — Issue → worktree → plan → implement → commit → PR
- `/hane:commit` — Conventional Commits message from staged changes
- `/hane:ship` — push, open PR, watch CI, clean up

## Conventions

These are enforced by the skills above and expected in every contribution:

- **Branch + PR only** — never commit or push directly to `main`.
- **Worktrees** live under `.claude/worktrees/<branch-name>` (git-ignored).
- **Branch names**: `feat/`, `fix/`, `docs/`, `chore/`, `refactor/` + kebab-case.
- **Commits**: [Conventional Commits](https://www.conventionalcommits.org/) with **English** subjects.
- **Issues / PRs**: titles, bodies, and comments are written in **English**.
- **CHANGELOG**: any PR that changes skill behavior or docs adds an entry to the `## [Unreleased]` section of [CHANGELOG.md](CHANGELOG.md) **in the same PR** (create the section if it was consumed by the last release).

## Where decisions and records live

- **ADRs** (`docs/adr/`) capture the *why* behind a decision. They are written in **Japanese** (matching the existing ADRs and skill bodies), numbered from the linked GitHub Issue → PR → local sequence, with no zero-padding (see [ADR-8](docs/adr/8-issue-based-doc-numbering.md)). Use `design-doc/ADR-TEMPLATE.md` as the skeleton.
- **Acceptance tests** (`docs/acceptance/`) fence a change with concrete checks; tool-facing records use `type: tool` frontmatter and the same issue-based numbering.

## Proposing a new skill

1. Open an Issue describing the **workflow it automates**, the **trigger phrases**, the **host-repo conventions** it would read (and how it degrades when they are absent), and any **overlap** with existing skills.
2. Add `skills/<name>/SKILL.md` with a `name` + `description` frontmatter (the `description` carries the trigger phrases the harness matches on) and the step-by-step body.
3. Record the rationale in an ADR, add the skill to the README Skills table, and note it in `CHANGELOG.md` `[Unreleased]`.

## Deprecating a skill

Follow the deprecation convention in [ADR-55](docs/adr/55-skill-deprecation-convention.md):

- Mark the skill's `SKILL.md` frontmatter with `deprecated: true` + `deprecated_reason:` (and `superseded_by:` when there is a successor) and add a `> **⚠️ Deprecated.**` banner to the body.
- Choose a level: **Soft-deprecate** keeps the trigger phrases (still fires, recorded as deprecated); **Retire** also strips the trigger phrases from `description` so the harness no longer suggests it. Keep the body for provenance either way.
- Strike the skill through in the README Skills table and record it under `### Deprecated` in `CHANGELOG.md` `[Unreleased]`.

## Releasing

Releases are cut manually through PRs — see the [Releasing](README.md#releasing) section of the README.

## Questions

Open an Issue (or a GitHub Discussion, if enabled). Please do **not** file security-sensitive reports as public Issues — follow [SECURITY.md](SECURITY.md) instead.
