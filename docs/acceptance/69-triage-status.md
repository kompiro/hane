---
type: tool
---

# AT-69: triage-status skill が status 空白の Issue に初期 status を付与する

- **日付**: 2026-07-11
- **Issue**: #69
- **PR**: なし
- **関連ADR**: ADR-69（triage-status skill 追加）, ADR-49（status を読む pick-issue / gating の先例）
- **Related TPLs**: なし（hane は `docs/test-perspectives/` を採用しないため）
- **対象**: `skills/triage-status/SKILL.md`, `README.md`, `CHANGELOG.md`

## 概要

`status: *` ラベルがまだ付いていない open Issue に、内容から推論した初期 status
（ready / blocked / designed）を提案し、ユーザー確認のうえ付与する `triage-status`
skill を追加する。active な状態（designing / implementing / in-review）は付与せず、
既に status がある Issue は触らないことを主要件とする。

## 受け入れ条件

### AC-1: triage-status skill が存在し、起動できる

- [ ] `skills/triage-status/SKILL.md` が存在し、frontmatter（`name: triage-status`、トリガーフレーズ付き `description`）を持つ
- [ ] `/hane:triage-status` として起動できる（skills はディレクトリ自動検出のため manifest 変更は不要）

### AC-2: 対象 Issue を解決する

- [ ] 引数で Issue 番号が指定されていればそれ（複数可）を対象にする
- [ ] 指定が無ければ、`status: *` ラベルが 1 つも付いていない open Issue を対象にする
- [ ] 引数指定に既に status が付いた Issue が含まれていたら「既に status あり」として skip する（上書きしない）
- [ ] 対象が多い場合、件数を伝えて全件処理するか番号を絞るかを確認する（黙って一部だけ処理しない）

### AC-3: status ラベルの存在で gating する

- [ ] `gh label list` で repo の `status: *` family を洗い出す
- [ ] `status: *` が 1 つも定義されていない repo では、ラベルを捏造せず「定義してください（/hane:init）」と伝えて終了する
- [ ] repo で定義されている status 名の中から ready / blocked / designed 相当を対応付ける

### AC-4: 初期 status を内容から推論する

- [ ] 本文に open な依存の記述（`depends on #X` / `blocked by #X` 等で `#X` が open）があれば `status: blocked` を提案する
- [ ] 依存先 `#X` が既に closed なら blocked にしない
- [ ] 承認済み design doc の存在（リンク／`docs/design/` の該当ファイル／「設計完了」等）があれば `status: designed` を提案する
- [ ] 上記いずれでもなければ既定で `status: ready` を提案する
- [ ] 各提案に 1 行の根拠を添える／判定に迷う場合は安全側の `ready` に倒す

### AC-5: active な状態を付与しない

- [ ] `status: designing` / `status: implementing` / `status: in-review` を初期付与の候補にしない

### AC-6: 確認のうえ付与する

- [ ] AskUserQuestion で付与内容を確認してから適用する（複数件でも承認を得てから適用する）
- [ ] 承認された内容を `gh issue edit <N> --add-label "status: <ready|blocked|designed>"` で付与する
- [ ] 既に status がある Issue を上書き・遷移しない

### AC-7: 結果の報告

- [ ] 付与した Issue と status を報告する
- [ ] skip した対象（既に status あり・判断不能）があれば件数と理由を添える

### AC-8: README / CHANGELOG が更新され、スコープが守られている

- [ ] `README.md` の Skills 表に `triage-status` が追加されている
- [ ] `README.md` の「Per-skill customization points」に triage-status の gating（`status: *` 存在依存・active 状態と既存 status は対象外）が記載されている
- [ ] `CHANGELOG.md` の `[Unreleased]` に `triage-status` skill 追加（#69）が記載されている
- [ ] host repo の `CLAUDE.md` の生成・編集は行わない（スコープ外）

## 検証方法

hane はテスト・ビルドツールを持たない skills-only repo のため、自動テストは無い。
上記 AC はすべて AI / 人間レビューによる手動確認とする。`triage-status` skill の実挙動
（status 推論・active 状態の除外・確認付き付与）は、利用先 repo（karasu 等）での
dogfooding で担保する。

> 未チェック項目について:
>
> - 全項目: hane に自動テストランナーが無いため、skill body の妥当性は dogfooding と利用先 repo での動作で担保する（`CLAUDE.md`「実装方針」）。レビューで内容を確認したらチェックする。
> - AC-2 〜 AC-7 の実挙動: status 空白／既存 status／open な依存を持つ Issue が混在する repo で skill を実際に走らせて確認する（人間検証）。
