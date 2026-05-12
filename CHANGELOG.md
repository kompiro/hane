# Changelog

All notable changes to `hane` are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this plugin adheres to [Semantic Versioning](https://semver.org/) at the plugin level (see "Versioning policy" in README).

## [Unreleased]

### Added

- `test-perspective` — new skill to create / update / deprecate Test Perspective Library (TPL) records under `docs/test-perspectives/`: frontmatter schema, GitHub-number-based `TPL-<n>-<slug>.md` naming (Issue → PR → local, per ADR-8/ADR-10; host convention takes precedence), 3-Yes rule, retrospective vs proactive origin, deprecation rules (never delete; rationale required), lifecycle, and reference timing. No tooling ported — `tpl:validate` / `tpl:related` and the `topic` vocabulary stay host-local. ([#13](https://github.com/kompiro/hane/issues/13))
- `acceptance-test`: TPL-aware step — when the host repo has `docs/test-perspectives/`, scan matching TPLs before writing ACs, cite their IDs in a `**Related TPLs**:` meta field, and transcribe the checklist items of cited proactive TPLs as ACs ("forward operation"). Skipped silently when the directory is absent. ([#12](https://github.com/kompiro/hane/issues/12))
- `design-doc`: TPL-aware step — when the host repo has `docs/test-perspectives/`, (1) list matching existing TPLs in a `## Related TPLs` section, and (2) scan same-topic `concepts*` / ADRs for principles not yet captured as TPLs that the design might violate, raising a proactive TPL in the same PR (via the `test-perspective` skill, 3-Yes gated). Skipped silently when the directory is absent. ([#14](https://github.com/kompiro/hane/issues/14))
- `qa`: TPL coverage hints — when the host repo has `docs/test-perspectives/`, the generated checklist gains a `## TPL Coverage Hints` section listing active TPLs whose `topic`/`scope` overlaps the in-scope ATs but that no AT cites, plus likely "forward operation" transcription gaps in cited proactive TPLs. Hints only — the full Fit/Gap matrix stays a host-repo workflow; Automated/Manual output is unchanged, and the section is omitted when the directory is absent. ([#15](https://github.com/kompiro/hane/issues/15))

### Changed

- ADR / design-doc conventions, made explicit (`.claude/rules/adr-language.md`): ADRs are written in Japanese (matching the design docs and skill bodies); promoting a design doc to an ADR condenses it into the ADR and removes the original `docs/design/` file in the same PR (no "status: decided + link" leftover). `start-dev` cleanup and the `design-doc` skill updated to match; ADR-8 translated to Japanese (filename and `ADR-8` heading unchanged). ([#21](https://github.com/kompiro/hane/issues/21))

### Notes

- Design rationale and decision for the TPL integration: [ADR-10](docs/adr/10-tpl-integration-into-skills.md) (umbrella [#10](https://github.com/kompiro/hane/issues/10); the originating design doc was condensed into the ADR on promotion).

## [0.2.0] — 2026-05-06

### Added

- `sync-docs`: handle localized README variants. Top-level `README*.md` files (e.g. `README.md`, `README.ja.md`, `README.zh-CN.md`) are now auto-included as sync targets even when not listed in `CLAUDE.md`. `README.md` is treated as canonical; `README.<locale>.md` is updated to follow it (with draft translations for missing sections), never the other direction. ([#5](https://github.com/kompiro/hane/issues/5))

## [0.1.0] — 2026-05-05

Initial release. Eight skills extracted from [kompiro/karasu](https://github.com/kompiro/karasu) and decoupled from karasu-specific assumptions.

### Added

- `commit` — generate Conventional Commits messages from staged git changes.
- `ship` — push, open a PR, watch CI, run post-checks, and clean up.
- `start-dev` — Issue → worktree → plan → implement → commit → PR workflow.
- `design-doc` — create exploratory design documents under `docs/design/`.
- `acceptance-test` — create acceptance test records under `docs/acceptance/NNNN-*.md`.
- `qa` — generate a QA checklist from acceptance test records.
- `review-docs` — detect broken links and cross-document consistency issues.
- `sync-docs` — sync reference docs (README / spec / requirements) with the current implementation; reads target docs from host `CLAUDE.md`.
- Marketplace manifest with explicit HTTPS source so the plugin works for both public and private repos without SSH key setup.

### Conventions baked in

- Worktree path: `.claude/worktrees/<branch-name>` (coexists with Claude Code's Agent auto-worktrees — verified in [karasu#1116](https://github.com/kompiro/karasu/pull/1116)).
- All ADR promotion / `status:` label updates / `docs/{design,adr,acceptance}/` operations are gated on host-repo presence; absent conventions are skipped silently.

### Origin trail

Migration plan: [karasu#1075](https://github.com/kompiro/karasu/issues/1075). Portability audit: [karasu#1084](https://github.com/kompiro/karasu/issues/1084). Worktree-coexistence verification: [karasu#1085](https://github.com/kompiro/karasu/issues/1085). Skill decoupling: [karasu#1086](https://github.com/kompiro/karasu/issues/1086). External validation: [karasu#1090](https://github.com/kompiro/karasu/issues/1090).
