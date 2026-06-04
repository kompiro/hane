# hane — CLAUDE.md

`hane`（羽）は Claude Code 向けの再利用可能 skill 群を束ねる plugin リポジトリ。

PR ワークフロー、Design Doc、受け入れテスト記録、ドキュメント保守などを `/hane:start-dev` `/hane:commit` `/hane:ship` 等として提供する。詳細は [`README.md`](README.md) を参照。

## ドキュメント

| ドキュメント | 場所 |
|---|---|
| Plugin 概要・install 手順 | `README.md` |
| Plugin manifest | `.claude-plugin/plugin.json` |
| Marketplace manifest | `.claude-plugin/marketplace.json` |
| 各 skill の実装 | `skills/<name>/SKILL.md` |

## 実装方針

このリポジトリ自体は plugin の skill ファイル群と manifest しか持たない。テスト・ビルドツールは導入していない。コード品質チェックは行わず、skill body の妥当性は dogfooding と利用先 repo（[`kompiro/karasu`](https://github.com/kompiro/karasu) など）の動作で担保する。

## 開発ワークフロー

このリポジトリで開発する際は **`hane` plugin 自身の skill** を使う（dogfooding）。

### ブランチ・worktree ルール

- `main` への直接コミット・push は禁止（初期ブートストラップを除く）— 必ずブランチ + PR 経由でマージする
- worktree の作成先は必ず `.claude/worktrees/<branch-name>` とする
- ブランチ命名規則: `feat/`, `fix/`, `docs/`, `chore/`, `refactor/` + kebab-case

### Issue・PR 記述ルール

- Issue のタイトル・本文・コメントは英語で書く
- PR のタイトル・description（本文）は英語で書く
- commit メッセージも英語（subject）

### CHANGELOG・リリース

- skill の挙動やドキュメントを変える PR は、**同じ PR で** `CHANGELOG.md` の `## [Unreleased]` 節に変更を追記する（節が無ければ先頭に作る）。後追いの版上げ PR で拾い直すのは漏れの温床
- リリース手順（Unreleased の版上げ → tag → `gh release`）の詳細は [`README.md`](README.md) の「Releasing」節が唯一の正

## 由来

`kompiro/karasu`（鴉）プロジェクトの開発で育てた skill 群を切り出して plugin 化した。`hane`（羽）は karasu の羽の意。
