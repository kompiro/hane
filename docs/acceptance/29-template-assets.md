---
type: tool
---

# AT-29: AT / ADR / TPL templates extracted into TEMPLATE.md assets

- **日付**: 2026-05-17
- **Issue**: #29
- **PR**: なし
- **関連ADR**: ADR-8（採番ルール）, ADR-10（TPL 統合・命名）
- **Related TPLs**: なし（hane は `docs/test-perspectives/` を採用しないため）
- **対象**: `skills/acceptance-test/TEMPLATE.md`, `skills/acceptance-test/SKILL.md`, `skills/test-perspective/TEMPLATE.md`, `skills/test-perspective/SKILL.md`, `skills/design-doc/ADR-TEMPLATE.md`, `skills/design-doc/SKILL.md`, `skills/start-dev/SKILL.md`, `README.md`, `CHANGELOG.md`

## 概要

`design-doc` skill が `TEMPLATE.md` アセットを持つようになった先例（#26/#27）に倣い、AT / TPL / ADR の雛形を独立した `TEMPLATE.md` アセットに切り出す。AT / TPL は各 skill のインライン定義を抽出、ADR は専用 skill が無いため `design-doc` 配下に配置する。`init` skill（#28）が各 `docs/*/TEMPLATE.md` を複製なしで seed できる状態を作るのが目的。

## 受け入れ条件

### AC-1: AT テンプレートが独立アセットになっている

- [ ] `skills/acceptance-test/TEMPLATE.md` が存在し、コピー可能な AT 記録 skeleton（メタ欄 / 概要 / 受け入れ条件 / 検証方法）になっている
- [ ] 冒頭 HTML コメントにファイル名規約（GitHub 番号ベース）・言語・`type:` frontmatter の任意性が書かれている
- [ ] `skills/acceptance-test/SKILL.md` の `## ファイル形式` がインライン定義を撤去し `TEMPLATE.md` への参照に縮小されている

### AC-2: TPL テンプレートが独立アセットになっている

- [ ] `skills/test-perspective/TEMPLATE.md` が存在し、frontmatter + 本文 5 節（観点 / 想定される失敗モード / チェックリスト / 既知の対処パターン / 関連テスト）の skeleton になっている
- [ ] `skills/test-perspective/SKILL.md` の `### 2-3.` がインラインの frontmatter / 本文定義を撤去し `TEMPLATE.md` への参照に縮小されている
- [ ] 前提条件節の「host repo に `TEMPLATE.md` も用意する」記述が、この skill の `TEMPLATE.md` をコピーする旨に更新されている

### AC-3: ADR テンプレートが追加され、昇格手順から参照されている

- [ ] `skills/design-doc/ADR-TEMPLATE.md` が存在し、hane の既存 ADR 形式（frontmatter 無し・prose ヘッダ・GitHub 番号ベース ID・本文 背景/決定/理由/却下した案）の skeleton になっている
- [ ] `skills/design-doc/SKILL.md` の ADR 化ステップ（手順 9）が `ADR-TEMPLATE.md` を参照している
- [ ] `skills/start-dev/SKILL.md` のクリーンアップ手順（Design Doc → ADR 昇格）が `ADR-TEMPLATE.md` を参照している

### AC-4: 抽出が忠実で、ワークフロー挙動が変わっていない

- [ ] AT / TPL の `TEMPLATE.md` の節構成・frontmatter は、抽出前のインライン定義と等価（節の追加・削除・改名が無い）
- [ ] 各 skill の手順・ガイドライン・命名規則の節は SKILL.md に残っており、移動したのは雛形の literal な定義のみ

### AC-5: テンプレートが hane 規約にジェネリック化されている

- [ ] ADR テンプレートに karasu 固有の frontmatter スキーマ（`topic` controlled vocabulary、関係性メタデータ、`pnpm adr:validate` 等のツール連携）が持ち込まれていない。host repo が ADR frontmatter を運用する場合は host 規約優先、と注記されている
- [ ] TPL テンプレートの ID / ファイル名が GitHub 番号ベース（`TPL-<番号>`）であり、karasu の日付ベース（`TPL-YYYYMMDD-NN`）を焼き込んでいない。host 独自規約優先の注記がある

### AC-6: README / CHANGELOG が更新されている

- [ ] `README.md` に、doc 記録系 skill が `TEMPLATE.md` アセットを持つことが追記されている
- [ ] `CHANGELOG.md` の `[Unreleased]` に本変更（#29）が記載されている

## 検証方法

hane はテスト・ビルドツールを持たない skills-only repo のため、自動テストは無い。上記 AC はすべて AI / 人間レビューによる手動確認とする（各ファイルの差分を本 AT と突き合わせる）。

> 未チェック項目について:
>
> - 全項目: hane に自動テストランナーが無いため、skill body / アセットの妥当性は dogfooding と利用先 repo（karasu 等）での動作で担保する（`CLAUDE.md`「実装方針」）。レビューで内容を確認したらチェックする。
