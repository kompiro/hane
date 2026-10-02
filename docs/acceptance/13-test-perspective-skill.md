---
type: tool
---

# AT-13: test-perspective skill

- **日付**: 2026-05-12
- **Issue**: #13
- **PR**: なし
- **関連ADR**: なし（design doc `docs/design/tpl-acceptance-test-integration.md`、将来 ADR-10 へ昇格予定）
- **Related TPLs**: なし（hane は `docs/test-perspectives/` を採用しないため）
- **対象**: `skills/test-perspective/SKILL.md`, `README.md`, `CHANGELOG.md`

## 概要

Test Perspective Library（TPL）レコードの作成 / 更新 / deprecate を担う新スキル `test-perspective` を追加する。design doc の論点 C1（produce 側を独立スキルにする）/ B（ドキュメントの形・運用ルール・参照タイミングは汎化、tooling と `topic` 語彙は host ローカル）に対応。#10 の (2a)。

## 受け入れ条件

### AC-1: スキルファイルが存在する

- [ ] `skills/test-perspective/SKILL.md` が存在し、frontmatter に `name: test-perspective` とトリガー語（"テスト観点" / "TPL" / "test perspective" / "add TPL" / "deprecate TPL" 等）が定義されている

### AC-2: 新規作成手順が揃っている

- [ ] 起源の判定（retrospective = `bug`/`test-infra` Issue 起点 / proactive = 原則ファイル・ADR 起点で `discovered_from.root_cause_file` または `root_cause_adr` を追加）が説明され、`discovered_from.issue` は起源を問わず採番の起点として書く、と書かれている（#92 で改訂）
- [ ] 3-Yes ルール（横展開しうる / 構造的に再発しうる / 既存 TPL 未掲載）が説明されている
- [ ] ファイル名規約 `docs/test-perspectives/TPL-YYYYMMDD-NN-<slug>.md`（ゼロ埋めなし）と「ホスト repo が独自規約を持つ場合はそちら優先」のエスケープが書かれている
- [ ] frontmatter スキーマ（`id` / `title` / `status` / `date` / `applicable_to` / `known_consumers?` / `discovered_from` / `related_to` / `topic` / `scope.packages`）が示されている
- [ ] 本文 5 節（観点 / 想定される失敗モード / チェックリスト3〜5項目 / 既知の対処パターン / 関連テスト）が示されている

### AC-3: 更新・deprecate 手順が揃っている

- [ ] 既存 TPL の更新（`discovered_from` への追記、チェックリスト等の refresh）が書かれている
- [ ] deprecate は `status: deprecated` に変更し、エントリは**削除せず**末尾に rationale（`deprecated` の語を含む / `superseded by` の書き方）を追記する、と書かれている
- [ ] deprecate のトリガーは定期 deprecation レビューであることが書かれている

### AC-4: tooling と語彙が host ローカルとして扱われている

- [ ] `topic` の controlled vocabulary は「ホスト repo の ADR 語彙があればそれ、無ければ free-form」と書かれている
- [ ] `tpl:validate` / `tpl:related` 等は「ホスト repo が提供していれば使う、無ければ手動 grep / 手動確認」という条件付き参照になっており、hane に tooling を移植していない
- [ ] 定期 deprecation レビューの cadence・自動化はホスト repo に委ねる、と書かれている

### AC-5: ライフサイクルと他スキル連携が記述されている

- [ ] ライフサイクル図（concept → proactive TPL → development → bug → retrospective TPL）と proactive/retrospective の非対称性が記述されている
- [ ] 参照タイミング（DesignDoc 作成時 / 新機能実装時 / bug 修正時）と、`design-doc` / `acceptance-test` スキルとの連携ポイント（forward 運用での AC 転記など）が記述されている
- [ ] `topic`/`package` に紐付かないメタ観点は TPL に載せない、というスコープ外の注記がある

### AC-6: README / CHANGELOG が更新されている

- [ ] `README.md` の Skills 表に `test-perspective` 行が追加されている
- [ ] `README.md` の Host repo prerequisites に optional な `docs/test-perspectives/` が追記され、Per-skill customization 表に TPL 行が追加されている
- [ ] `CHANGELOG.md` の `[Unreleased]` に `test-perspective` 新設（#13）と `acceptance-test` の TPL-aware 化（#12）が記載されている

### AC-7: hane 自身では no-op であること

- [ ] hane リポジトリには `docs/test-perspectives/` が存在せず、この新スキルを hane 内で起動すると「ディレクトリを新設するか」をユーザーに確認する動作になる（既存スキルの挙動には影響しない）

## 検証方法

hane はテスト・ビルドツールを持たない skills-only repo のため、自動テストは無い。上記 AC はすべて AI / 人間レビューによる手動確認とする（`skills/test-perspective/SKILL.md` / `README.md` / `CHANGELOG.md` の差分を本 AT と突き合わせる）。

> 未チェック項目について:
>
> - 全項目: hane に自動テストランナーが無いため、skill body の妥当性は dogfooding と利用先 repo（karasu 等）での動作で担保する（`CLAUDE.md`「実装方針」）。レビューで内容を確認したらチェックする。
