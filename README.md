# claude-skills

Reusable [Claude Code](https://claude.com/claude-code) skills for a branch/worktree-based PR workflow, design docs, acceptance tests, and documentation maintenance.

> **Status**: bootstrap / pre-release. Initial extraction from `kompiro/karasu` (see [karasu#1075](https://github.com/kompiro/karasu/issues/1075)). Documentation and v0.1.0 release are tracked separately.

## Skills

| Skill | What it does |
|---|---|
| `commit` | Generate Conventional Commits messages from staged changes and commit. |
| `ship` | Push, open a PR, watch CI, then clean up. |
| `start-dev` | Issue → worktree → plan → implement → commit → PR workflow. |
| `design-doc` | Create `docs/design/` brainstorm/exploration documents. |
| `acceptance-test` | Create `docs/acceptance/NNNN-*.md` records. |
| `qa` | Generate a QA checklist from acceptance test records. |
| `review-docs` | Find broken links and cross-document inconsistencies in `docs/`. |
| `sync-docs` | Sync reference docs with the current code (CLAUDE.md doc-table driven). |

## Install

```
/plugin marketplace add kompiro/claude-skills
/plugin install claude-skills@kompiro-claude-skills
```

Skills are then invoked as `/claude-skills:commit`, `/claude-skills:ship`, etc.

## Host repo prerequisites

- **Add `.claude/worktrees/` to `.gitignore`.** `start-dev`, `ship`, and `design-doc` create persistent worktrees there. Without the ignore entry, hooks that detect untracked files may misfire.
- **Optional**: `status: ready / blocked / implementing / designing / designed / in-review` label set if you want the skills to update Issue status as work progresses. Skipped silently if labels are absent.
- **Optional**: `docs/design/` and `docs/adr/` directories if you want Design Doc and ADR-promotion workflows. Each skill checks for the relevant directory at runtime.

## Conventions adopted by these skills

- Worktrees: `.claude/worktrees/<branch-name>` (coexists safely with Claude Code's Agent auto-worktrees — see [karasu#1116](https://github.com/kompiro/karasu/pull/1116)).
- Branches: `feat/`, `fix/`, `docs/`, `chore/`, `refactor/` + kebab-case.
- Commits: Conventional Commits with English subjects.
- PR template: falls back to a built-in minimal template if `.github/PULL_REQUEST_TEMPLATE.md` is absent.

## License

MIT
