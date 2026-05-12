---
type: tool
---

# AT-21: ADR / design-doc / TPL conventions codified

- **日付**: 2026-05-12
- **Issue**: #21
- **PR**: なし
- **関連ADR**: ADR-8（採番ルール）, ADR-10（TPL 統合・命名）
- **Related TPLs**: なし（hane は `docs/test-perspectives/` を採用しないため）
- **対象**: `.claude/rules/adr-language.md`, `docs/adr/8-issue-based-doc-numbering.md`, `skills/start-dev/SKILL.md`, `skills/design-doc/SKILL.md`, `skills/test-perspective/SKILL.md`, `README.md`, `CHANGELOG.md`

## 概要

ADR / Design Doc / TPL に関する慣習を明文化し、skill 群とドキュメントを整合させる: ADR は日本語で書く（`.claude/rules/` に明文化）、Design Doc は ADR 昇格時に削除する、ADR-8 を日本語に翻訳、TPL のファイル名を GitHub 番号ベースに統一。PR #20 のレビュー議論から派生（Issue #21）。

## 受け入れ条件

### AC-1: ADR 言語ルールが明文化されている

- [ ] `.claude/rules/adr-language.md` が存在し、「`docs/adr/` の ADR は日本語で書く」「Design Doc は ADR 昇格時に同じ PR で削除する（ステータス更新+リンクだけ残す運用はしない）」「ADR/AT/TPL のファイル名は GitHub 番号ベース（Issue → PR → ローカル）、host 独自規約優先」が書かれている

### AC-2: ADR-8 が日本語に翻訳されている

- [ ] `docs/adr/8-issue-based-doc-numbering.md` の本文が日本語になっている
- [ ] ファイル名は `8-issue-based-doc-numbering.md` のまま、見出しは `# ADR-8: ...`（番号 8 は不変）
- [ ] 翻訳後も ADR-8 の決定事項（Issue → PR → ローカルの優先順位、ゼロ埋めなし、リネーム禁止、ドキュメント種別ごとの詳細、却下した案）が保持されている

### AC-3: skill 群が「ADR 昇格 = design doc 削除」「ADR は日本語」に追従している

- [ ] `skills/start-dev/SKILL.md` のクリーンアップ手順（Design Doc → ADR 昇格）が「Design Doc の内容を ADR に集約し、同じ PR で `docs/design/` の元ファイルを削除する」「ADR は日本語で書く」「元 Design Doc を参照していたリンクを ADR に張り替える」になっている（ステータスを「決定済み」に更新する旧記述が削除されている）
- [ ] `skills/design-doc/SKILL.md` の「ADR との違い」表・ADR化のステップ・ファイル形式の「ステータス」欄が、ADR化したら元ファイルを削除する／ADR は日本語、に追従している

### AC-4: TPL のファイル名規約が GitHub 番号ベースになっている

- [ ] `skills/test-perspective/SKILL.md` のファイル名規約が `TPL-<番号>-<slug>.md`（見出し `TPL-<番号>`、ゼロ埋めなし）になり、番号の優先順位が **Issue 番号（retrospective は起点 Issue）→ PR 番号（proactive は DesignDoc PR）→ ローカル採番** と書かれている
- [ ] 1 番号複数 TPL は slug で区別／採番後リネームしない／host 独自規約（karasu の `TPL-YYYYMMDD-NN`）優先、が書かれている
- [ ] frontmatter 例（`id: TPL-<番号>`）・本文テンプレ見出し（`# TPL-<番号>: ...`）・`related_to` 例・`superseded by` 例・「ホスト依存の慣習」のファイル名規約の項が追従している

### AC-5: README / CHANGELOG が更新されている

- [ ] `README.md` の「Conventions adopted by these skills」に、doc ファイルの GitHub 番号採番・ADR は日本語・design doc は ADR 昇格時に削除、が追記されている
- [ ] `CHANGELOG.md` の `[Unreleased]` に本変更（#21）が記載され、`test-perspective` の行が新しい TPL 命名に更新されている

### AC-6: hane への影響が文言の範囲に収まっている

- [ ] ADR-8 の翻訳でファイル名・見出し番号は不変なので外部参照（`ADR-8`）は壊れない
- [ ] hane は `docs/test-perspectives/` を採用していないので `test-perspective` skill の挙動変更は hane 内では no-op
- [ ] hane に現存する Design Doc は無い（ADR-10 昇格時に削除済み）ので、skill の「昇格時に削除」変更は既存ファイルに影響しない

## 検証方法

hane はテスト・ビルドツールを持たない skills-only repo のため、自動テストは無い。上記 AC はすべて AI / 人間レビューによる手動確認とする（各ファイルの差分を本 AT と突き合わせる）。

> 未チェック項目について:
>
> - 全項目: hane に自動テストランナーが無いため、skill body / ルールの妥当性は dogfooding と利用先 repo（karasu 等）での動作で担保する（`CLAUDE.md`「実装方針」）。レビューで内容を確認したらチェックする。
