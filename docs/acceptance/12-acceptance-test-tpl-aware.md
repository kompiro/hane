---
type: tool
---

# AT-12: acceptance-test skill TPL-aware

- **日付**: 2026-05-12
- **Issue**: #12
- **PR**: なし
- **関連ADR**: なし（design doc `docs/design/tpl-acceptance-test-integration.md`、将来 ADR-10 へ昇格予定）
- **Related TPLs**: なし（hane は `docs/test-perspectives/` を採用しないため）
- **対象**: `skills/acceptance-test/SKILL.md`

## 概要

`/hane:acceptance-test` skill を、ホスト repo が `docs/test-perspectives/`（Test Perspective Library, TPL）を採用している場合に関連 TPL を参照・引用するよう拡張する。design doc の論点 A1（ディレクトリの存在で gating）/ B（ドキュメントの形は汎化・tooling は host ローカル）/ D の (1) に対応する。これは hane 内 dogfood 用の AT であり、`docs/acceptance/` ディレクトリの初出でもある。

## 受け入れ条件

### AC-1: TPL 参照ステップが条件付きで追加されている

- [ ] `skills/acceptance-test/SKILL.md` の「手順」に、AC を記述する前に TPL を確認するステップが追加されている
- [ ] そのステップは「ホスト repo が `docs/test-perspectives/` を採用している場合のみ」と明記され、ディレクトリが無ければスキップすると書かれている（skip パス）
- [ ] 関連 TPL の探索はホスト repo の `tpl:related` 等のスクリプトを使い、無ければ frontmatter（`topic` / `scope.packages` 等）を grep する、という二段構えになっている（tooling を hane に移植していない）
- [ ] マッチした TPL の ID を AT 本文の `**Related TPLs**:` メタ欄に列挙すると書かれている
- [ ] proactive な TPL（`discovered_from` が原則ファイル / ADR を指すもの）のチェックリスト項目を AC として転記する、と書かれている（forward 運用）
- [ ] retrospective（`discovered_from.issue`）と proactive の区別が説明されている

### AC-2: ファイル形式・ガイドラインが更新されている

- [ ] 「ファイル形式」のメタブロックに `- **Related TPLs**: …` 行が追加され、不採用 repo では `なし` か欄ごと省略してよいと書かれている
- [ ] 「受け入れ条件の書き方ガイドライン」に、proactive TPL から転記した AC には出所の TPL ID を併記する旨が追記されている

### AC-3: hane 自身では no-op であること

- [ ] hane リポジトリには `docs/test-perspectives/` が存在せず、この変更によって既存の `/hane:acceptance-test` の挙動（hane 内での AT 作成手順）は変わらない

## 検証方法

hane はテスト・ビルドツールを持たない skills-only repo のため、自動テストは無い。上記 AC はすべて AI / 人間レビューによる手動確認とする（`skills/acceptance-test/SKILL.md` の差分と本 AT を突き合わせる）。

> 未チェック項目について:
>
> - 全項目: hane に自動テストランナーが無いため、skill body の妥当性は dogfooding と利用先 repo（karasu 等）での動作で担保する（`CLAUDE.md`「実装方針」）。レビューで内容を確認したらチェックする。
