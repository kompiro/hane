---
type: tool
---

# AT-28: init skill scaffolds host-repo conventions

- **日付**: 2026-05-17
- **Issue**: #28
- **PR**: なし
- **関連ADR**: ADR-8（採番ルール）, ADR-10（TPL 統合）
- **Related TPLs**: なし（hane は `docs/test-perspectives/` を採用しないため）
- **対象**: `skills/init/SKILL.md`, `README.md`, `CHANGELOG.md`

## 概要

hane の各 skill が前提とする host-repo の慣習（ドキュメントディレクトリ・テンプレート・`process.md`・任意の status ラベル・`.claude/rules/`）を、対話で scaffold する `init` skill を追加する。テンプレート抽出（#26/#27/#29）が済んだ前提で、各 `docs/*/TEMPLATE.md` を owning skill のアセットからコピーする。

## 受け入れ条件

### AC-1: init skill が存在し、起動できる

- [ ] `skills/init/SKILL.md` が存在し、frontmatter（`name: init`、トリガーフレーズ付き `description`）を持つ
- [ ] `/hane:init` として起動できる（skills はディレクトリ自動検出のため manifest 変更は不要）

### AC-2: 4 つの選択を対話で確認する

- [ ] 採用するドキュメントディレクトリ（`docs/design,adr,acceptance,test-perspectives`）をユーザーに確認する
- [ ] `docs/adr/` 採用時、ADR ファイル名規約（GitHub 番号ベース / 日付ベース）を確認する
- [ ] `status: *` ラベル運用の採用可否を確認する
- [ ] `.claude/rules/` ディレクトリの作成可否を確認する
- [ ] 既に存在するものは「採用済み」として質問から除く

### AC-3: 選択に応じてディレクトリとテンプレートを生成する

- [ ] 採用した各 doc ディレクトリに `TEMPLATE.md` が作られる
- [ ] 各 `TEMPLATE.md` は owning skill のアセットをコピーしたもの（`docs/design/TEMPLATE.md` ← `design-doc/TEMPLATE.md`、`docs/adr/TEMPLATE.md` ← `design-doc/ADR-TEMPLATE.md`、`docs/acceptance/TEMPLATE.md` ← `acceptance-test/TEMPLATE.md`、`docs/test-perspectives/TEMPLATE.md` ← `test-perspective/TEMPLATE.md`）。コピー元との内容一致を確認できる
- [ ] テンプレートを複製・再生成していない（コピー元は plugin 内 skill アセット）

### AC-4: process.md スケルトンを生成する

- [ ] いずれかの doc ディレクトリを採用した場合、`docs/process.md` が生成される
- [ ] process.md にドキュメントライフサイクル・branch/worktree ルール・選んだ ADR 採番規約・（採用時のみ）ラベル運用が反映されている
- [ ] process.md 冒頭に「host repo が育てる前提のスケルトン」である旨が明記されている

### AC-5: 冪等である

- [ ] 既存ファイル・ディレクトリ・ラベルは上書きせず skip する
- [ ] 2 回目の実行で既存物を壊さず、不足分だけを補う
- [ ] 実行のたびに created / skipped の内訳をレポートする

### AC-6: status ラベルを任意で作成する

- [ ] ラベル運用を採用した場合、`status: ready/blocked/designing/designed/implementing/in-review` の 6 種が `gh label create` で作られる
- [ ] 既存ラベルは skip される

### AC-7: README / CHANGELOG が更新され、スコープが守られている

- [ ] `README.md` の Skills 表に `init` が追加され、「Host repo prerequisites」節に `/hane:init` での scaffold が案内されている
- [ ] `CHANGELOG.md` の `[Unreleased]` に `init` skill 追加（#28）が記載されている
- [ ] host repo の `CLAUDE.md` の生成・編集は行わない（スコープ外。利用者に追記を促すのみ）

## 検証方法

hane はテスト・ビルドツールを持たない skills-only repo のため、自動テストは無い。上記 AC はすべて AI / 人間レビューによる手動確認とする。`init` skill の実挙動（対話・scaffold・冪等性）は、利用先 repo（karasu 等）または新規 repo での dogfooding で担保する。

> 未チェック項目について:
>
> - 全項目: hane に自動テストランナーが無いため、skill body の妥当性は dogfooding と利用先 repo での動作で担保する（`CLAUDE.md`「実装方針」）。レビューで内容を確認したらチェックする。
> - AC-2 〜 AC-6 の実挙動: skill を実際に新規 repo で走らせて確認する（人間検証）。
