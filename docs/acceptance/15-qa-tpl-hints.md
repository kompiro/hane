---
type: tool
---

# AT-15: qa skill TPL coverage hints

- **日付**: 2026-05-12
- **Issue**: #15
- **PR**: なし
- **関連ADR**: なし（design doc `docs/design/tpl-acceptance-test-integration.md`、将来 ADR-10 へ昇格予定）
- **Related TPLs**: なし（hane は `docs/test-perspectives/` を採用しないため）
- **対象**: `skills/qa/SKILL.md`, `CHANGELOG.md`

## 概要

`/hane:qa` skill を、ホスト repo が `docs/test-perspectives/`（TPL）を採用している場合に TPL カバレッジヒント（未引用 TPL / proactive TPL の転記漏れ）を生成チェックリストに surface するよう拡張する。design doc の論点 D(2c)（"lower priority"、最低でも regress させない）に対応。#10 の (2c)。

## 受け入れ条件

### AC-1: TPL ヒントステップが条件付きで追加されている

- [ ] `skills/qa/SKILL.md` の「手順」に TPL カバレッジヒントを収集するステップが追加されている（手動確認項目の収集の後、チェックリスト生成の前）
- [ ] そのステップは「ホスト repo が `docs/test-perspectives/` を採用している場合のみ」と明記され、ディレクトリが無ければスキップすると書かれている
- [ ] 後続ステップの番号が繰り下げられ、番号の重複・欠落がない
- [ ] `docs/test-perspectives/` の有無にかかわらず Automated Checks / Manual Checks の既存出力は変えない（no regression）旨が明記されている

### AC-2: ヒントの内容が記述されている

- [ ] 収集した対象 AT の `**Related TPLs**:` メタ欄から引用済み TPL 集合を作る、と書かれている
- [ ] `active` な TPL のうち、対象 AT の `type` / 対象モジュールに `scope.packages` / `topic` / `applicable_to` が重なるのにどの対象 AT からも引用されていないものを「未引用 TPL」として挙げる、と書かれている
- [ ] 引用済み proactive TPL のチェックリスト項目が対象 AT の AC に転記されているかを突き合わせ、漏れがあれば挙げる、と書かれている
- [ ] 何も挙がらなければ「該当なし」とする、と書かれている

### AC-3: tooling とスコープが明示されている

- [ ] ホスト repo が `tpl:related` 等を提供していればそれで候補を絞る、という条件付き参照になっている
- [ ] 完全な Fit/Gap 分析（TPL チェックリスト × test/AT の網羅 matrix）はホスト repo 側の別ワークフローに委ねる、と明記されている

### AC-4: 生成チェックリスト形式が更新されている

- [ ] 生成形式に `## TPL Coverage Hints` 節が追加され、ステップを実行した場合のみ出力する／不在 repo では節ごと省略／ヒントなしなら「該当なし」と書かれている
- [ ] 結果の報告で、ヒントを出力した場合は未引用 TPL / 転記漏れの件数も伝える、と書かれている

### AC-5: CHANGELOG が更新されている

- [ ] `CHANGELOG.md` の `[Unreleased]` に `qa` の TPL coverage hints（#15）が記載されている

### AC-6: hane 自身では no-op であること

- [ ] hane リポジトリには `docs/test-perspectives/` が存在せず、この変更によって既存の `/hane:qa` の出力（Automated / Manual）は変わらない

## 検証方法

hane はテスト・ビルドツールを持たない skills-only repo のため、自動テストは無い。上記 AC はすべて AI / 人間レビューによる手動確認とする（`skills/qa/SKILL.md` / `CHANGELOG.md` の差分を本 AT と突き合わせる）。

> 未チェック項目について:
>
> - 全項目: hane に自動テストランナーが無いため、skill body の妥当性は dogfooding と利用先 repo（karasu 等）での動作で担保する（`CLAUDE.md`「実装方針」）。レビューで内容を確認したらチェックする。
