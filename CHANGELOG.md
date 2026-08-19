# Changelog

All notable changes to `hane` are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this plugin adheres to [Semantic Versioning](https://semver.org/) at the plugin level (see "Versioning policy" in README).

## [Unreleased]

### Fixed

- `security-alert`: step 1 collected only `state == "open"` alerts, so any alert GitHub's Dependabot auto-triage had dismissed was invisible to the whole workflow while the vulnerable version stayed in the lock file. The skill would then report "no alerts to handle" for a repo installing a package inside an advisory's vulnerable range, which is the one conclusion this skill must not reach incorrectly. Collection now takes `auto_dismissed` alongside `open` (`fixed` and human `dismissed` stay excluded), and the termination condition moves off alert count onto the resolved version: "nothing to handle" may only be said once every collected alert's resolved version is outside its advisory range. Observed on karasu#2565: two `high` alerts, both auto-dismissed as development-scoped, both still resolving to the vulnerable version; one of them (`brace-expansion` 5.0.8 against `>= 4.0.0, < 5.0.9`) was the stale-floor case step 2 exists to catch, and it sat unfixed for two weeks because collection never surfaced it. Its row joins the step 2 example table, which now records how long each instance took to notice. (#85)
- `security-alert`: step 2 now says `scope` is for prioritising, not for deciding whether to act. The field is recomputed when the dependency graph moves: karasu's alert #68 was `open` / `runtime` in the morning and `auto_dismissed` / `development` the same afternoon, after unrelated dependency PRs changed the graph. The vulnerable version never moved. (#85)

## [0.16.0] — 2026-08-11

### Changed

- `security-alert` / `dependabot`: the collateral check in step 6 ("巻き込みの確認") now names a method, because the obvious one is wrong. Comparing the **set** of `name@version` keys in a lock cannot see a consumer switching to a version already present elsewhere in the graph — the key set is unchanged or shrinks while the resolution moves. It reported "nothing moved version" on karasu#2416 while four transitive resolutions had moved (`shiki` 4.2.0→4.4.1, `picomatch`, `@types/estree`, `@babel/helper-validator-identifier`). Reading the raw lock diff does not work either: a graph change rewrites peer suffixes tree-wide, so hundreds of lines change where no version did. Adds a snippet that compares dependency edges with peer suffixes stripped, verified to report exactly the real moves on that PR. (#82)
- `security-alert`: new step 6 item — when a moved package is consumed by an area the host's `build` / `test` does not cover, build that area by hand. On karasu#2416 the one moved resolution with user-visible output (`shiki`, the docs site's highlighter) sat in the only area PR CI never exercises, so a regression would have landed post-merge. (#82)

## [0.15.1] — 2026-08-10

### Fixed

- `security-alert`: the override-location list named `package.json`'s `pnpm.overrides` for pnpm without qualification, which is the **dead location under pnpm 11** — it no longer reads the `pnpm` field at all (pnpm/pnpm#10086), so an override written there is silently ignored rather than rejected, leaving the vulnerable version resolved while the PR goes green. The list is now split by pnpm version, checking `packageManager` first is required, and the step 2 declaration grep covers `pnpm-workspace.yaml` so an existing override there is not read as "no pin". (#79)

## [0.15.0] — 2026-08-09

### Changed

- `security-alert`: triage now diffs the advisory's vulnerable range against the host repo's **own** override entries and manifest declaration ranges, instead of trusting the lock file's resolved versions. An override pinned during an earlier alert becomes a lock onto a version a later advisory covers, and a lock-only check reads that as "already pinned, so handled" — observed twice in two days in karasu (`js-yaml` pinned `^4.3.0` against `>= 4.0.0, < 4.3.1`, `dompurify` pinned `^3.4.12` against `<= 3.4.12`). Adds a routing row for the stale-floor case, requires a package declared both in overrides and as a direct dep to move at both sites in one commit, and strengthens the lock verification from "resolves to the fixed version" to "no vulnerable-version entry remains". (#76)
- `dependabot`: a security update PR for a package that is also under an override now routes through the `security-alert` pin diff first — a stale override floor makes the bot PR either regress on merge or fail CI with `ERR_PNPM_LOCKFILE_CONFIG_MISMATCH`. (#76)
- `test-perspective`: multiple TPLs from one Issue / PR now each get a **unique number** — the number goes to the TPL that best represents the origin and the rest cascade to the next source (Issue → PR → local max+1), matching the second-ADR-from-one-Issue rule in `start-dev`. The previous guidance (share the number, distinguish by `<slug>`) produces `duplicate-id` findings under `@kompiro/tpl-tools` >= 0.0.7; the skill now points to `tpl validate` after local numbering, the only race-prone path (kompiro/karasu#2188). (#74)
- `test-perspective` / `init`: dropped the stale "karasu" attribution from the date-based convention examples — karasu migrated to the skill's default GitHub-number TPL ids (karasu ADR-2188). (#74)

## [0.14.0] — 2026-07-11

### Added

- `status: on-hold` added to the status-label model — a **deliberately shelved** state distinct from `blocked`. `blocked` means an open dependency Issue (auto-clears when that Issue closes); `on-hold` means work is intentionally paused (e.g. a concept needs rethinking) with no automatic unblock trigger, and is set/removed by human judgment. `init` now creates the label, `pick-issue` excludes it from candidates alongside the active/blocked states, and `triage-status` deliberately does **not** assign it (like the active-work states, it cannot be statically inferred from the Issue body).

## [0.13.0] — 2026-07-11

### Added

- `triage-status` skill — assigns an **initial `status:` label** to open Issues that have none yet, filling the gap between Issue creation and the lifecycle skills. Infers the status from the Issue body — `status: blocked` when an open `depends on #X` / `blocked by #X` is referenced, `status: designed` when an approved design doc already exists, else `status: ready` — and confirms before applying. Deliberately does **not** assign active-work states (`designing` / `implementing` / `in-review`) — those would mislead `pick-issue`'s in-progress exclusion — and does **not** overwrite an existing status; transitions stay owned by `start-dev` / `ship`. Gated on the presence of the `status: *` label set: a repo without it gets a "define them (`/hane:init`) first" message instead of fabricated labels. Rationale in [ADR-69](docs/adr/69-triage-status-skill.md). ([#69](https://github.com/kompiro/hane/issues/69))
- `SECURITY.md` for the public OSS release — private reporting route (GitHub Security Advisories, with an email fallback), supported-versions policy, coordinated-disclosure stance, and an explicit **scope** covering hane's real attack surface: skill bodies execute shell procedures in the **host repository**, `hooks/` run on the user's machine, the marketplace manifest is the distribution path, and skills that read external content (Issue bodies, upstream diffs) have prompt-injection paths. Linked from `README.md` and `CONTRIBUTING.md`. Enabling GitHub private vulnerability reporting is **deferred to the public flip** ([#61](https://github.com/kompiro/hane/issues/61)) because the setting only exists on public repositories; rationale in [ADR-58](docs/adr/58-security-policy-and-private-reporting.md). ([#58](https://github.com/kompiro/hane/issues/58))
- GitHub **issue templates** (`.github/ISSUE_TEMPLATE/`) for the public OSS release — YAML issue forms for bug reports (asks which skill + host-repo context), feature requests, and new-skill proposals (workflow, trigger phrases, host conventions, overlap — mirroring what an ADR needs to accept a skill), plus a `config.yml` that disables blank issues and routes questions to the README and security reports to `SECURITY.md`. ([#59](https://github.com/kompiro/hane/issues/59))

### Changed

- README made readable for a newcomer with no prior `karasu` context — a "What it is" value proposition, an "adapts to your repo" note on optional gating, a typical-loop quickstart (`pick-issue` → `start-dev` → `ship`), and a license badge, all above the skills table. Repository **topics** set (`claude-code`, `claude-code-plugin`, `claude-skills`, `developer-tools`, `ai-agents`, `git-worktree`) for discoverability. ([#60](https://github.com/kompiro/hane/issues/60))

## [0.12.0] — 2026-07-09

> **Heads-up (behavior change):** the `qa` skill is **retired** in this release — its trigger phrases were removed, so "qa" / "QAチェック" no longer invoke it. Use the `qa` subagent + `acceptance-test` skill instead (see Deprecated below).

### Added

- Skill **deprecation convention** — a `SKILL.md` frontmatter marker (`deprecated: true` + `deprecated_reason:` + optional `superseded_by:`) plus a body banner, with two retirement levels: **Soft-deprecate** (keeps trigger phrases) and **Retire** (also strips trigger phrases from `description` so the harness stops suggesting the skill). Deprecated skills are struck through in the README Skills table and recorded in the CHANGELOG. Rationale and the two-level model: [ADR-55](docs/adr/55-skill-deprecation-convention.md). ([#55](https://github.com/kompiro/hane/issues/55))
- `CONTRIBUTING.md` and `CODE_OF_CONDUCT.md` (Contributor Covenant v2.1) for the public OSS release — repo layout, the conventions each change follows (dogfooding, branch+PR, Conventional Commits, issue-based numbering), and how to propose or deprecate a skill. Linked from the README. ([#57](https://github.com/kompiro/hane/issues/57))

### Changed

- `start-dev` and `design-doc` now make a **past-decision conflict check mandatory before planning/designing** — scan `docs/adr/` (especially **rejected** decisions) for conflicts with the current request and fold the result into the plan. `ADR-TEMPLATE.md` promotes rejected reasoning to first-class (drops the "only if useful" hedge, documents standalone `ステータス: 却下` ADRs), and notes that a minimal record (decision + status) suffices and that the filename slug is the retrieval mechanism. Reflects the "spec accumulation effect" findings ([article](https://fukurou.kompiro.dev/ja/spec-accumulation-effect/)); rationale in [ADR-63](docs/adr/63-consult-past-decisions-before-design.md). ([#63](https://github.com/kompiro/hane/issues/63))

### Deprecated

- `qa` skill (generate a QA checklist from `docs/acceptance/` records) — **retired**. Superseded by the `qa` subagent (fills test gaps from a PR diff — more proactive) and the `acceptance-test` skill (owns the AT records). Trigger phrases were removed from its `description` so it no longer competes with the subagent; the `SKILL.md` body is kept for provenance. ([#55](https://github.com/kompiro/hane/issues/55))

## [0.11.0] — 2026-06-27

### Added

- `sync-worktrees` — new skill that brings the merged default branch into in-flight worktrees. After one PR lands on `main`, the remaining `.claude/worktrees/` branches fall behind; this skill `git fetch`es the default branch (auto-detected from `origin/HEAD`, fallback `main` → `master`), enumerates the live `git worktree list`, and `git merge`s the default branch (merge, not rebase) into each feature-branch worktree. It skips the main worktree, detached-HEAD worktrees, worktrees that are already up to date, and — importantly — worktrees with uncommitted changes or a merge/rebase in progress, which doubles as the safety guard for worktrees another session is actively working in. Conflicts stop on that worktree and are reported (files listed; resolve-or-abort guidance given) without auto-resolving. Local merge only — no push. An optional argument restricts the run to a single branch/worktree. ([#52](https://github.com/kompiro/hane/issues/52))

## [0.10.0] — 2026-06-16

### Added

- `pick-issue` — new skill that picks the next workable Issue and hands off to `start-dev`. Built for parallel Claude Code sessions: it **excludes in-progress Issues another session may already be on** — primarily `status: implementing` / `status: designing`, plus `status: in-review` (work essentially done) and `status: blocked` (cannot start). It treats `status: ready` / `status: designed` / **unlabeled** Issues as workable, ranks them (`ready` → `designed` → unlabeled, then priority labels / dependency hints / staleness), and surfaces a recommended shortlist while reporting how many in-progress Issues were filtered out. Because `status:*` labels are optional in hane, it also flags an Issue as in-progress when it has an assignee or an open linked PR/branch, so detection degrades gracefully in repos without the label set. The skill stays read-only — all state transitions (label updates, worktree creation) are left to `start-dev`. ([#49](https://github.com/kompiro/hane/issues/49))

### Notes

- Adoption rationale and design decisions for the `pick-issue` skill: [ADR-49](docs/adr/49-pick-issue-skill.md).

## [0.9.0] — 2026-06-12

### Added

- `open-pr` — new utility skill that opens the pull request for the branch you are working on in the browser via `gh pr view --web`. With no argument it resolves the target branch automatically: the current non-main branch, or — when invoked from main — the open PR among `.claude/worktrees/` worktrees (asking which one when several are open). A PR number or branch name argument is opened directly. Falls back to printing the PR URL when a browser cannot be launched.

## [0.8.0] — 2026-06-04

### Changed

- `ship`: added an optional CHANGELOG step — when the host repo maintains a Keep a Changelog–style `CHANGELOG.md` with an `## [Unreleased]` section, the skill now checks before pushing whether the branch records its change there and offers to add an entry. Generic and opt-in (skipped when no such CHANGELOG exists), following the skill's existing host-convention pattern; the release procedure itself stays out of scope.

### Added

- Documented the release process so it is no longer tribal knowledge: a new "Releasing" section in `README.md` (two-stage flow — record changes under `## [Unreleased]` per PR, then `chore(release)` version bump → tag → `gh release`), a `CHANGELOG`/release rule in `CLAUDE.md`, and a `.github/pull_request_template.md` whose checklist reminds contributors to update `[Unreleased]` in the same PR. Reinforced by the new `ship` CHANGELOG check above. Addresses changelog entries being forgotten on change PRs and picked up late at release time.

## [0.7.1] — 2026-06-04

### Changed

- `design-doc`: PR creation is now an explicit, dedicated step instead of a sub-bullet buried in the worktree-setup step. The skill stops at "create file + commit", then a separate step opens the PR (delegating to `ship`, or `gh pr create` for repos that don't adopt it) and writes the PR number back into the doc's `**PR**` meta field. Review is now requested on the created PR. Trailing label-update / ADR-promotion steps were renumbered. No behavior was removed — PR creation was always intended; this makes it reliable and ordered correctly (#43).

## [0.7.0] — 2026-05-31

### Added

- Plugin hook `sync-tab-title` (`hooks/hooks.json` + `hooks/sync-tab-title.sh`): keeps the terminal tab title in sync with the current git branch. Registered on `SessionStart` and `CwdChanged`, so the title follows you the moment a worktree is entered. Uses the `terminalSequence` hook field (Claude Code >= 2.1.141); degrades silently when `jq` is absent or input is malformed. Auto-discovered when the plugin is enabled — no `settings.json` change needed.

### Changed

- `start-dev`: dropped the manual `/rename` step for labeling the session. `/rename` is a UI command the model cannot invoke, so the step was always silently skipped; session identification is now automatic via the `sync-tab-title` hook above. The step is gone (not just rewritten) to keep the skill body — which is loaded into context on every run — free of dead instructions.

## [0.6.0] — 2026-05-20

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
