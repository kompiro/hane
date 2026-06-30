# hane

Reusable [Claude Code](https://claude.com/claude-code) skills for a branch/worktree-based PR workflow, design docs, acceptance tests, and documentation maintenance.

The name comes from 羽 (*hane*, "feather") — these skills were originally extracted from [kompiro/karasu](https://github.com/kompiro/karasu) (鴉, *karasu*, "crow"), so the bundle is named after the bird's feathers.

## Skills

| Skill | What it does |
|---|---|
| `init` | Scaffold the host-repo conventions the other skills expect (doc directories, templates, `process.md`, optional status labels). |
| `commit` | Generate Conventional Commits messages from staged changes and commit. |
| `ship` | Push, open a PR, watch CI, then clean up. |
| `open-pr` | Open the PR for the branch you are working on in the browser (`gh pr view --web`). |
| `pick-issue` | Pick the next workable Issue — excluding in-progress ones another session may be on — and hand off to `start-dev`. |
| `start-dev` | Issue → worktree → plan → implement → commit → PR workflow. |
| `sync-worktrees` | After PRs merge, merge the default branch into every in-flight worktree (local merge only; dirty/in-progress worktrees are skipped). |
| `design-doc` | Create `docs/design/` brainstorm/exploration documents. |
| `acceptance-test` | Create `docs/acceptance/NNNN-*.md` records. |
| ~~`qa`~~ | _Deprecated (retired) — superseded by the `qa` subagent + `acceptance-test`. See [ADR-55](docs/adr/55-skill-deprecation-convention.md)._ |
| `test-perspective` | Create / update / deprecate Test Perspective Library (TPL) records under `docs/test-perspectives/`. |
| `dependabot` | Batch-triage open Dependabot update PRs with a mandatory upstream risk analysis, route the go/no-go decision through a Design Doc, and record the outcome in an ADR. |
| `security-alert` | Triage open Dependabot security alerts: collect them from the alerts API, route by direct/transitive, fix (merge PR / bump / package-manager override), and record the decision in an ADR. |
| `review-docs` | Find broken links and cross-document inconsistencies in `docs/`. |
| `sync-docs` | Sync reference docs with the current code (CLAUDE.md doc-table driven). |

## Install

```
/plugin marketplace add kompiro/hane
/plugin install hane@kompiro-hane
```

Skills are then invoked as `/hane:commit`, `/hane:ship`, etc.

## Host repo prerequisites

Run `/hane:init` to scaffold the items below interactively — it asks which doc directories to adopt, the ADR filename scheme, and whether to use status labels, then creates the directories, copies the document templates, and writes a `process.md` skeleton. It is idempotent, so it is also safe to run later to fill gaps.

- **Add `.claude/worktrees/` to `.gitignore`.** `start-dev`, `ship`, and `design-doc` create persistent worktrees there. Without the ignore entry, hooks that detect untracked files may misfire.
- **Optional**: `status: ready / blocked / implementing / designing / designed / in-review` label set if you want the skills to update Issue status as work progresses. Skipped silently if labels are absent.
- **Optional**: `docs/design/` and `docs/adr/` directories if you want Design Doc and ADR-promotion workflows. Each skill checks for the relevant directory at runtime.
- **Optional**: `docs/test-perspectives/` directory if you want the Test Perspective Library workflow. The `test-perspective` skill creates/updates records there; `acceptance-test` and `design-doc` cite matching records when the directory exists. Skipped silently if absent.

## Conventions adopted by these skills

- Worktrees: `.claude/worktrees/<branch-name>` (coexists safely with Claude Code's Agent auto-worktrees — see [karasu#1116](https://github.com/kompiro/karasu/pull/1116)).
- Branches: `feat/`, `fix/`, `docs/`, `chore/`, `refactor/` + kebab-case.
- Commits: Conventional Commits with English subjects.
- PR template: falls back to a built-in minimal template if `.github/PULL_REQUEST_TEMPLATE.md` is absent.
- Doc files (`docs/{acceptance,adr,test-perspectives}/`) are numbered from the linked GitHub Issue, then PR, then a local sequence — no zero-padding (see [ADR-8](docs/adr/8-issue-based-doc-numbering.md), [ADR-10](docs/adr/10-tpl-integration-into-skills.md)); a host repo's own naming convention takes precedence. ADRs are written in the language of the repo's existing ADRs / project rules — in this repo, Japanese (like the design docs and skill bodies). Promoting a design doc to an ADR condenses it into the ADR and removes the original `docs/design/` file in the same PR.
- Document skeletons are shipped as standalone `TEMPLATE.md` assets next to the skill that owns them — `design-doc/TEMPLATE.md` (design doc), `acceptance-test/TEMPLATE.md` (AT record), `test-perspective/TEMPLATE.md` (TPL record), and `design-doc/ADR-TEMPLATE.md` (ADR). Each skill copies its template rather than re-deriving the shape.
- Deprecating a skill: mark its `SKILL.md` frontmatter with `deprecated: true` + `deprecated_reason:` (and `superseded_by:` when there is a successor), and add a `> **⚠️ Deprecated.**` banner to the body. The marker alone does **not** stop the harness from triggering the skill — triggering is driven by `description`. So there are two levels: **Soft-deprecate** keeps the trigger phrases (skill still fires, but is recorded as deprecated); **Retire** also strips the "Trigger when the user says …" phrases from `description` (prefixed with `[Deprecated]`) so it is no longer suggested. The body is kept either way for provenance. Deprecated skills are struck through in the Skills table above. See [ADR-55](docs/adr/55-skill-deprecation-convention.md).

## Per-skill customization points

Each skill reads from host-repo conventions when present and skips related steps when absent. Concrete extension points:

| Skill | Customization point |
|---|---|
| `pick-issue` | `status: *` label set is used to detect in-progress Issues (`implementing` / `designing` / `in-review` / `blocked`) when present; without labels it falls back to assignee + open-linked-PR signals. Hands off the chosen Issue to `start-dev` |
| `start-dev`, `ship` | `status: *` label set (used for Issue progress tracking) — opt-in by defining the labels |
| `start-dev` cleanup | ADR promotion runs only when `docs/adr/` exists; ADR filename convention is host-defined |
| `start-dev`, `ship` | Package manager auto-detected from `packageManager` field or lockfile (`pnpm-lock.yaml` / `package-lock.json` / `yarn.lock`); install step skipped when `package.json` absent |
| `start-dev`, `ship` | Test/lint/format commands picked up from host `package.json` `scripts`; missing scripts are skipped |
| `start-dev`, `ship` | PR body template read from `.github/PULL_REQUEST_TEMPLATE.md` if present, otherwise a built-in minimal template is used |
| `acceptance-test`, `qa` | `type: product / tool` frontmatter is honored if existing AT files use it; otherwise all AT files are treated as in-scope |
| `test-perspective`, `acceptance-test`, `design-doc` | TPL workflow runs only when `docs/test-perspectives/` exists; the `topic` controlled vocabulary, TPL filename convention, `tpl:validate` / `tpl:related` tooling, and deprecation-review cadence are all host-defined |
| `sync-worktrees` | Operates on the live `git worktree list`, so it is independent of the `.claude/worktrees/` convention; the default branch is auto-detected from `origin/HEAD` (fallback `main` → `master`). Worktrees with uncommitted changes or a merge/rebase already in progress are skipped, which doubles as the guard for worktrees another session is actively working in |
| `review-docs` | Each consistency check runs only when its target directory exists (`docs/adr/`, `docs/design/`, `docs/acceptance/`) |
| `sync-docs` | Subagent A inspects the source roots reported by host `package.json`; subagent B reads the document table in host `CLAUDE.md` to learn what to keep in sync |
| `dependabot` | Triage report is written as a Design Doc only when `docs/design/` exists, and the outcome is recorded as an ADR only when `docs/adr/` exists; without either, results are returned in-conversation and as PR comments. ADR/Design Doc filename and language follow host conventions |
| `security-alert` | Package manager auto-detected (pnpm `overrides` / npm `overrides` / yarn `resolutions`); the decision is recorded as an ADR only when `docs/adr/` exists; ADR filename, language, and ADR-only PR auto-merge follow host conventions |

## Versioning policy

`hane` follows [Semantic Versioning 2.0](https://semver.org/) at the **plugin level**:

- **MAJOR** (`X.0.0`): a breaking change in any bundled skill — e.g. removing a skill, renaming a skill, or changing default behavior in a way that requires host-repo action.
- **MINOR** (`0.X.0`): adding a new skill, adding a new optional gate, or adding new instructions to an existing skill that remain backward compatible.
- **PATCH** (`0.0.X`): clarifications, documentation tweaks, prompt refinements that don't change observable behavior.

Breaking changes are called out at the top of each release entry in [CHANGELOG.md](CHANGELOG.md). Skill bodies use comments or "Note:" blocks to flag deprecations one minor version before removal where feasible.

## Releasing

Releases are cut manually through PRs — there is no release automation. The flow has two stages:

1. **Per change PR (every PR that alters skill behavior or docs):** add your change to the `## [Unreleased]` section of [CHANGELOG.md](CHANGELOG.md) **in the same PR**. If no `[Unreleased]` section exists (the previous release consumed it), create one at the top. This is the step most often forgotten, so it is reinforced in two places: the `/hane:ship` skill checks for it before pushing, and the PR checklist in [`.github/pull_request_template.md`](.github/pull_request_template.md).
2. **Release PR (`chore(release): X.Y.Z`):**
   - Rename `## [Unreleased]` → `## [X.Y.Z] — YYYY-MM-DD` (JST). Pick `X.Y.Z` per the Versioning policy above.
   - Open the PR, get it merged into `main`.
   - Tag the merge commit and publish the GitHub release:
     ```sh
     gh release create vX.Y.Z --target main \
       --title "vX.Y.Z — <short summary>" \
       --notes "<paste the CHANGELOG section + Full Changelog compare link>"
     ```
   - Release title convention: `vX.Y.Z — <short summary>`. Notes = the CHANGELOG section followed by `**Full Changelog**: https://github.com/kompiro/hane/compare/v<prev>...vX.Y.Z`.

The plugin has no version field in `.claude-plugin/plugin.json`; the git tag + CHANGELOG entry + GitHub release together are the version of record.

## License

MIT
