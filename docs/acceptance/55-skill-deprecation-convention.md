---
type: tool
---

# AT-55: skill deprecation convention and qa retirement

- **日付**: 2026-06-30
- **Issue**: #55
- **PR**: なし
- **関連ADR**: ADR-55（deprecate 運用）, ADR-8（採番ルール）
- **Related TPLs**: なし（hane は `docs/test-perspectives/` を採用しないため）
- **対象**: `skills/qa/SKILL.md`, `docs/adr/55-skill-deprecation-convention.md`, `README.md`, `CHANGELOG.md`

## 概要

skill を引退させる運用が無かったため、frontmatter マーカー（`deprecated: true` +
理由 + 後継）と 2 段階の引退レベル（Soft-deprecate / Retire）を定め、最初の適用先
として `qa` skill を Retire する。

## 受け入れ条件

### AC-1: deprecate 運用が ADR に記録されている

- [ ] `docs/adr/55-skill-deprecation-convention.md` が存在する
- [ ] frontmatter マーカー（`deprecated: true` / `deprecated_reason:` / `superseded_by:`）が定義されている
- [ ] 「マークしてもトリガー集合から外れない」ことと、Soft-deprecate / Retire の 2 段階が説明されている

### AC-2: `qa` skill が Retire レベルで deprecate されている

`skills/qa/SKILL.md` の frontmatter にマーカーがあり、トリガー語が除去されている。

```bash
# deprecated マーカーが付いている
grep -q '^deprecated: true' skills/qa/SKILL.md && echo "OK: deprecated marker"
grep -q '^deprecated_reason:' skills/qa/SKILL.md && echo "OK: reason"
grep -q '^superseded_by:' skills/qa/SKILL.md && echo "OK: superseded_by"

# トリガー語が description から除去されている（Retire レベル）
! grep -qi 'Trigger when the user says' skills/qa/SKILL.md && echo "OK: trigger phrases removed"
grep -q '\[Deprecated\]' skills/qa/SKILL.md && echo "OK: description prefixed [Deprecated]"

# 本文（手順）は provenance として残っている
grep -q '## 手順' skills/qa/SKILL.md && echo "OK: body kept for provenance"
```

- [ ] 上記コマンドがすべて `OK:` を出力する

### AC-3: 周知（README / CHANGELOG）が更新されている

```bash
# README の skills 表で qa が取り消し線になっている
grep -q '~~`qa`~~' README.md && echo "OK: qa struck through in README table"
# deprecation policy が README に記載されている
grep -qi 'Deprecating a skill' README.md && echo "OK: deprecation policy documented"
# CHANGELOG の Unreleased に Deprecated 節がある
grep -q '## \[Unreleased\]' CHANGELOG.md && echo "OK: Unreleased section"
grep -q '### Deprecated' CHANGELOG.md && echo "OK: Deprecated subsection"
```

- [ ] 上記コマンドがすべて `OK:` を出力する

## 手動確認

- [ ] Claude Code を再読み込みし、「qa」と発話しても `qa` skill が候補に出ない（`acceptance-test` / `qa` subagent に流れる）ことを確認
