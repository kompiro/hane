---
type: tool
---

# AT-92: proactive TPL も作業の Issue で採番し `discovered_from.issue` を持つ

- **日付**: 2026-10-02
- **Issue**: #92
- **PR**: なし
- **関連ADR**: ADR-92（本変更）, ADR-10（TPL 採番規約の元）
- **Related TPLs**: なし（hane は `docs/test-perspectives/` を採用しないため）
- **対象**: `skills/test-perspective/SKILL.md`, `skills/test-perspective/TEMPLATE.md`, `skills/design-doc/SKILL.md`, `CHANGELOG.md`

## 概要

`test-perspective` skill と `TEMPLATE.md` が、proactive TPL を PR 番号に落とし `issue:` を
省くよう読める記述をしていた。採番の判定基準を「TPL を起こした作業に Issue があるか」の
1 つにし、`discovered_from.issue` を起源を問わない採番の起点にする。

## 受け入れ条件

### AC-1: 採番の判定基準が 1 つになっている

- [ ] `skills/test-perspective/SKILL.md` 2-3 が「その TPL を起こした作業に Issue があるか」を唯一の判定基準として示し、起源で分けないと書いている
- [ ] 優先順位 1 が retrospective・proactive の両方について作業の Issue を指している
- [ ] PR 番号は「作業に Issue が無い、または Issue 番号を別の TPL が使っている」ときだけ、と書かれている
- [ ] 「proactive TPL は Issue が無いことが多い」に当たる記述が skill・template に残っていない（`grep -rn "Issue が無いことが多い" skills/` が 0 件）

### AC-2: `discovered_from.issue` が起源を問わない採番の起点になっている

- [ ] 2-1 が、`issue:` は起源を問わず先頭に書く採番の起点で、proactive は `root_cause_file` / `root_cause_adr` の有無で判定すると書いている
- [ ] `TEMPLATE.md` の `issue:` 行の注記が「採番の起点。proactive でも、その TPL を起こした作業の Issue を書く」趣旨で、`root_cause_*` 行は proactive の場合に「追加」する行になっている
- [ ] `TEMPLATE.md` 冒頭の使い方が「該当行だけ残す」（二者択一）ではなく `issue:` を残す指示になっている

### AC-3: design-doc から起こす proactive TPL が Issue を先頭に持つ

- [ ] `skills/design-doc/SKILL.md` step 3 が、proactive TPL の `discovered_from` の先頭に DesignDoc の Issue を書き、番号もそこから採ると書いている

### AC-4: karasu#3025 の事例で正しい記録が得られる（手動・dry-run）

- [ ] Issue #3022 の DesignDoc から proactive TPL を起こす想定で skill を読み通すと、ファイル名 `TPL-3022-<slug>.md`、`discovered_from` が `issue: "#3022"` に続けて `root_cause_file` / `root_cause_adr` の形になる

### AC-5: 記録の整合

- [ ] `docs/adr/92-tpl-issue-anchor-for-proactive.md` が存在し、ADR-10 の「関連」から ADR-92 にリンクしている
- [ ] AT-13 / AT-14 の該当 AC が新しい規則に合わせて改訂されている
- [ ] `CHANGELOG.md` の `## [Unreleased]` に `### Fixed` として本変更が載っている
