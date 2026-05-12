---
type: tool
---

# AT-14: design-doc skill TPL-aware

- **日付**: 2026-05-12
- **Issue**: #14
- **PR**: なし
- **関連ADR**: なし（design doc `docs/design/tpl-acceptance-test-integration.md`、将来 ADR-10 へ昇格予定）
- **Related TPLs**: なし（hane は `docs/test-perspectives/` を採用しないため）
- **対象**: `skills/design-doc/SKILL.md`, `CHANGELOG.md`

## 概要

`/hane:design-doc` skill を、ホスト repo が `docs/test-perspectives/`（TPL）を採用している場合に関連 TPL を参照・引用し、原則違反を予見したら proactive TPL を同じ PR で起こすよう拡張する。design doc の論点 D(2b) と karasu README「参照タイミング — DesignDoc 作成時」の 2 段階に対応。#10 の (2b)。

## 受け入れ条件

### AC-1: TPL 参照ステップが条件付きで追加されている

- [ ] `skills/design-doc/SKILL.md` の「手順」に TPL を確認するステップが追加されている（既存ドキュメント確認の直後）
- [ ] そのステップは「ホスト repo が `docs/test-perspectives/` を採用している場合のみ」と明記され、ディレクトリが無ければスキップすると書かれている
- [ ] 後続ステップの番号が繰り下げられ、番号の重複・欠落がない

### AC-2: 2 段階の取り込みが記述されている

- [ ] 段階1: 既存 TPL の一覧（ホスト repo の `tpl:related` 等があればそれ、無ければ frontmatter を grep）→ `## Related TPLs` 節に列挙する、と書かれている
- [ ] 段階2: 同じ topic の `concepts*` 等の原則ファイルと関連 ADR を読み、まだ TPL になっていない原則で設計が違反しうるものを確認する、と書かれている
- [ ] 違反を予見した場合は 3-Yes ルールに照らし、満たすなら**同じ PR で** proactive TPL を起こす（`test-perspective` スキルを呼び `discovered_from.root_cause_file` / `root_cause_adr` を設定）、と書かれている
- [ ] 起こした proactive TPL は `## Related TPLs` 節に記載し DesignDoc と相互リンクする、と書かれている

### AC-3: ファイル形式・ガイドラインが更新されている

- [ ] 「ファイル形式」テンプレートに `## Related TPLs` 節が追加され、不採用 repo では節ごと省略してよいと書かれている
- [ ] 「壁打ちの進め方ガイドライン」に TPL の取り込みに関する一行が追記されている

### AC-4: CHANGELOG が更新されている

- [ ] `CHANGELOG.md` の `[Unreleased]` に `design-doc` の TPL-aware 化（#14）が記載されている

### AC-5: hane 自身では no-op であること

- [ ] hane リポジトリには `docs/test-perspectives/` が存在せず、この変更によって既存の `/hane:design-doc` の挙動は変わらない

## 検証方法

hane はテスト・ビルドツールを持たない skills-only repo のため、自動テストは無い。上記 AC はすべて AI / 人間レビューによる手動確認とする（`skills/design-doc/SKILL.md` / `CHANGELOG.md` の差分を本 AT と突き合わせる）。

> 未チェック項目について:
>
> - 全項目: hane に自動テストランナーが無いため、skill body の妥当性は dogfooding と利用先 repo（karasu 等）での動作で担保する（`CLAUDE.md`「実装方針」）。レビューで内容を確認したらチェックする。
