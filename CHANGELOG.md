# Changelog

All notable changes to `hane` are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this plugin adheres to [Semantic Versioning](https://semver.org/) at the plugin level (see "Versioning policy" in README).

## [Unreleased]

### Added

- `security-alert` — new skill that triages open Dependabot security alerts. Alerts are collected from `gh api .../dependabot/alerts` (not the open-PR list), risk-analyzed, and routed by `dependency.relationship`: a direct dependency is bumped (or its Dependabot security PR is deferred to the `dependabot` skill), while a transitive dependency — which often has no Dependabot PR at all — is pinned through the package manager's override mechanism (pnpm `overrides` / npm `overrides` / yarn `resolutions`). When multiple majors of the package coexist, the override key is scoped to the affected major so unaffected majors are not force-upgraded across a breaking boundary. The skill creates a tracking Issue, opens the fix PR, and records the decision in an ADR. No auto-merge; gated on `docs/adr/` like the other skills. ([#36](https://github.com/kompiro/hane/issues/36))

### Notes

- Adoption rationale and design decisions for the `security-alert` skill: [ADR-36](docs/adr/36-security-alert-skill.md).

## [0.5.0] — 2026-05-18

### Added

- `dependabot` — new skill that batch-triages open Dependabot update PRs. Every PR (`patch` / `minor` / `major` alike) gets a mandatory upstream risk analysis — release notes, version diff, maintainer/ownership changes, install scripts, dependency-tree changes, advisories — because supply-chain attacks make semver bump type an insufficient trust signal. The findings and a per-PR merge recommendation are written as a Design Doc under `docs/design/`; after the user decides, approved PRs are merged, rejected ones closed, and the outcome is recorded as an ADR (promoting the Design Doc). No auto-merge; gated on `docs/design/` and `docs/adr/` like the other skills. ([#33](https://github.com/kompiro/hane/issues/33))

### Notes

- Adoption rationale and design decisions for the `dependabot` skill: [ADR-33](docs/adr/33-dependabot-update-skill.md).

## [0.4.0] — 2026-05-18

### Added

- `init` — new skill that scaffolds the host-repo conventions the other skills expect. It interactively asks which doc directories to adopt, the ADR filename scheme, whether to use `status: *` labels, and whether to create `.claude/rules/`, then creates the directories, copies each document template from the owning skill's asset (`design-doc` / `acceptance-test` / `test-perspective`), writes a `docs/process.md` skeleton, and optionally creates the status labels. Idempotent — existing files/labels are skipped and a created/skipped report is printed. ([#28](https://github.com/kompiro/hane/issues/28))
- `design-doc`: standalone `TEMPLATE.md` asset — the design-doc skeleton was extracted from the inline `## ファイル形式` block so it can be copied verbatim into a host repo. `SKILL.md` points to it, and procedure step 4 now seeds `docs/design/TEMPLATE.md` into host repos that lack one. ([#26](https://github.com/kompiro/hane/issues/26))
- `acceptance-test`, `test-perspective`: each skill now ships a standalone `TEMPLATE.md` asset (the AT record skeleton / the TPL frontmatter + 5-section body), extracted from the inline definition in `SKILL.md` — following the `design-doc` `TEMPLATE.md` precedent. The `SKILL.md` `## ファイル形式` / record-creation sections shrink to a pointer. ([#29](https://github.com/kompiro/hane/issues/29))
- `design-doc`: new `ADR-TEMPLATE.md` asset — an ADR skeleton in hane's existing ADR format (no frontmatter, GitHub-number-based id, `背景` / `決定` / `理由` / `却下した案` body). `design-doc` (ADR promotion) and `start-dev` (cleanup) reference it. ([#29](https://github.com/kompiro/hane/issues/29))

### Changed

- `start-dev`: reinforce that the Issue (with its acceptance criteria and scope) is read before the worktree is created, and add a step to run `/rename` right after worktree creation so parallel sessions stay identifiable. ([#24](https://github.com/kompiro/hane/issues/24))
- The AT / TPL / ADR template extractions are faithful — no behavior change to the authoring workflows; the templates are now reusable assets that the `init` skill seeds into host repos without duplication.

## [0.3.0] — 2026-05-12

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
