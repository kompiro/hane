---
type: tool
---

# AT-60: README readable standalone + repo metadata for the public OSS release

- **日付**: 2026-07-11
- **Issue**: #60
- **PR**: なし
- **関連ADR**: ADR-63（着手前の過去決定確認）
- **Related TPLs**: なし（hane は `docs/test-perspectives/` を採用しないため）
- **対象**: `README.md`, リポジトリ設定（topics / homepage）

## 概要

OSS 公開（#61）に向けて、README を karasu 前提なしで読めるようにし（"What it is" /
adapts-to-repo / typical-loop / license badge を冒頭に）、リポジトリの topics を設定する。
homepage は別サイトが無いため N/A と決定（README が正典）。

## 受け入れ条件

### AC-1: README が単体で導入として読める（karasu 知識を前提にしない）

```bash
grep -q 'What it is' README.md && echo "OK: value proposition up top"
grep -qi 'adapts to your repo' README.md && echo "OK: explains optional gating"
grep -q '/hane:start-dev' README.md && grep -qi 'typical loop' README.md && echo "OK: quickstart loop"
grep -q 'license-MIT' README.md && echo "OK: license badge"
# karasu は「起源の補足」としてのみ登場し、getting started の前提にしていない
grep -qi 'No prior knowledge of' README.md && echo "OK: karasu not a prerequisite"
```

- [ ] 上記コマンドがすべて `OK:` を出力する

### AC-2: install / prerequisites が README 内で自己完結している

```bash
grep -q '/plugin marketplace add kompiro/hane' README.md && echo "OK: install command"
grep -qi 'Host repo prerequisites' README.md && echo "OK: prerequisites section"
```

- [ ] 上記コマンドがすべて `OK:` を出力する

### AC-3: リポジトリ topics が設定されている

```bash
gh repo view kompiro/hane --json repositoryTopics -q '.repositoryTopics[].name' | sort | tr '\n' ' '
# 期待: ai-agents claude-code claude-code-plugin claude-skills developer-tools git-worktree
```

- [ ] `claude-code` を含む関連 topics が設定されている

## 手動確認

- [ ] GitHub のリポジトリページで About パネルに topics が表示される
- [ ] Homepage は N/A（別サイトを持たない方針。設定する場合は About パネルに反映される）
