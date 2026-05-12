# hane

Reusable [Claude Code](https://claude.com/claude-code) skills for a branch/worktree-based PR workflow, design docs, acceptance tests, and documentation maintenance.

The name comes from 羽 (*hane*, "feather") — these skills were originally extracted from [kompiro/karasu](https://github.com/kompiro/karasu) (鴉, *karasu*, "crow"), so the bundle is named after the bird's feathers.

## Skills

| Skill | What it does |
|---|---|
| `commit` | Generate Conventional Commits messages from staged changes and commit. |
| `ship` | Push, open a PR, watch CI, then clean up. |
| `start-dev` | Issue → worktree → plan → implement → commit → PR workflow. |
| `design-doc` | Create `docs/design/` brainstorm/exploration documents. |
| `acceptance-test` | Create `docs/acceptance/NNNN-*.md` records. |
| `qa` | Generate a QA checklist from acceptance test records. |
| `test-perspective` | Create / update / deprecate Test Perspective Library (TPL) records under `docs/test-perspectives/`. |
| `review-docs` | Find broken links and cross-document inconsistencies in `docs/`. |
| `sync-docs` | Sync reference docs with the current code (CLAUDE.md doc-table driven). |

## Install

```
/plugin marketplace add kompiro/hane
/plugin install hane@kompiro-hane
```

Skills are then invoked as `/hane:commit`, `/hane:ship`, etc.

## Host repo prerequisites

- **Add `.claude/worktrees/` to `.gitignore`.** `start-dev`, `ship`, and `design-doc` create persistent worktrees there. Without the ignore entry, hooks that detect untracked files may misfire.
- **Optional**: `status: ready / blocked / implementing / designing / designed / in-review` label set if you want the skills to update Issue status as work progresses. Skipped silently if labels are absent.
- **Optional**: `docs/design/` and `docs/adr/` directories if you want Design Doc and ADR-promotion workflows. Each skill checks for the relevant directory at runtime.
- **Optional**: `docs/test-perspectives/` directory if you want the Test Perspective Library workflow. The `test-perspective` skill creates/updates records there; `acceptance-test` and `design-doc` cite matching records when the directory exists. Skipped silently if absent.

## Conventions adopted by these skills

- Worktrees: `.claude/worktrees/<branch-name>` (coexists safely with Claude Code's Agent auto-worktrees — see [karasu#1116](https://github.com/kompiro/karasu/pull/1116)).
- Branches: `feat/`, `fix/`, `docs/`, `chore/`, `refactor/` + kebab-case.
- Commits: Conventional Commits with English subjects.
- PR template: falls back to a built-in minimal template if `.github/PULL_REQUEST_TEMPLATE.md` is absent.

## Per-skill customization points

Each skill reads from host-repo conventions when present and skips related steps when absent. Concrete extension points:

| Skill | Customization point |
|---|---|
| `start-dev`, `ship` | `status: *` label set (used for Issue progress tracking) — opt-in by defining the labels |
| `start-dev` cleanup | ADR promotion runs only when `docs/adr/` exists; ADR filename convention is host-defined |
| `start-dev`, `ship` | Package manager auto-detected from `packageManager` field or lockfile (`pnpm-lock.yaml` / `package-lock.json` / `yarn.lock`); install step skipped when `package.json` absent |
| `start-dev`, `ship` | Test/lint/format commands picked up from host `package.json` `scripts`; missing scripts are skipped |
| `start-dev`, `ship` | PR body template read from `.github/PULL_REQUEST_TEMPLATE.md` if present, otherwise a built-in minimal template is used |
| `acceptance-test`, `qa` | `type: product / tool` frontmatter is honored if existing AT files use it; otherwise all AT files are treated as in-scope |
| `test-perspective`, `acceptance-test`, `design-doc` | TPL workflow runs only when `docs/test-perspectives/` exists; the `topic` controlled vocabulary, TPL filename convention, `tpl:validate` / `tpl:related` tooling, and deprecation-review cadence are all host-defined |
| `review-docs` | Each consistency check runs only when its target directory exists (`docs/adr/`, `docs/design/`, `docs/acceptance/`) |
| `sync-docs` | Subagent A inspects the source roots reported by host `package.json`; subagent B reads the document table in host `CLAUDE.md` to learn what to keep in sync |

## Versioning policy

`hane` follows [Semantic Versioning 2.0](https://semver.org/) at the **plugin level**:

- **MAJOR** (`X.0.0`): a breaking change in any bundled skill — e.g. removing a skill, renaming a skill, or changing default behavior in a way that requires host-repo action.
- **MINOR** (`0.X.0`): adding a new skill, adding a new optional gate, or adding new instructions to an existing skill that remain backward compatible.
- **PATCH** (`0.0.X`): clarifications, documentation tweaks, prompt refinements that don't change observable behavior.

Breaking changes are called out at the top of each release entry in [CHANGELOG.md](CHANGELOG.md). Skill bodies use comments or "Note:" blocks to flag deprecations one minor version before removal where feasible.

## License

MIT
