---
type: tool
---

# AT-63: spec-accumulation-effect learnings reflected into the design/planning skills

- **日付**: 2026-07-09
- **Issue**: #63
- **PR**: なし
- **関連ADR**: ADR-63（過去決定確認の埋め込み）, ADR-8（採番）, ADR-55（deprecate 運用）
- **Related TPLs**: なし（hane は `docs/test-perspectives/` を採用しないため）
- **対象**: `skills/start-dev/SKILL.md`, `skills/design-doc/SKILL.md`, `skills/design-doc/ADR-TEMPLATE.md`, `docs/adr/63-consult-past-decisions-before-design.md`

## 概要

「仕様蓄積効果」の 4 つの学び（①確認の手続き化が最大レバー / ②却下決定を優先記録 /
③最小記録で十分 / ④説明的ファイル名が検索の入口）を、hane の設計・計画 skill に
反映する。

## 受け入れ条件

### AC-1: 計画/設計ステップが「過去決定（却下）の衝突確認」を必須化している（学び①②）

```bash
# start-dev の計画ステップに必須の衝突確認がある
grep -q '過去決定の衝突確認（必須' skills/start-dev/SKILL.md && echo "OK: start-dev mandatory check"
grep -q '却下された決定' skills/start-dev/SKILL.md && echo "OK: start-dev targets rejected decisions"
# design-doc の確認ステップが必須化され却下を狙う
grep -q '過去決定の確認（必須' skills/design-doc/SKILL.md && echo "OK: design-doc mandatory check"
grep -q '却下された決定' skills/design-doc/SKILL.md && echo "OK: design-doc targets rejected decisions"
# 両者が ADR-63 を典拠にリンクしている
grep -q 'ADR-63' skills/start-dev/SKILL.md && echo "OK: start-dev cites ADR-63"
grep -q 'ADR-63' skills/design-doc/SKILL.md && echo "OK: design-doc cites ADR-63"
```

- [ ] 上記コマンドがすべて `OK:` を出力する

### AC-2: ADR-TEMPLATE が却下決定ファースト + 最小記録 + 説明的ファイル名を反映（学び②③④）

```bash
# 「却下した案」から "有用な場合のみ" のヘッジが消え、最優先で埋める節になっている
! grep -q '有用な場合のみ記述' skills/design-doc/ADR-TEMPLATE.md && echo "OK: hedge removed"
grep -q 'この節を最優先で埋める' skills/design-doc/ADR-TEMPLATE.md && echo "OK: rejected reasoning first-class"
# 独立した却下 ADR（ステータス: 却下）の運用が明記されている
grep -q 'ステータス: 却下' skills/design-doc/ADR-TEMPLATE.md && echo "OK: standalone rejection ADR"
# 最小記録・説明的ファイル名の規約がある
grep -q '最小限で始めてよい' skills/design-doc/ADR-TEMPLATE.md && echo "OK: minimal record"
grep -q 'slug が検索の入口' skills/design-doc/ADR-TEMPLATE.md && echo "OK: descriptive filename"
```

- [ ] 上記コマンドがすべて `OK:` を出力する

### AC-3: 反映判断が ADR として記録され、典拠記事にリンクしている（dogfooding）

```bash
test -f docs/adr/63-consult-past-decisions-before-design.md && echo "OK: ADR-63 exists"
grep -q 'fukurou.kompiro.dev/ja/spec-accumulation-effect' docs/adr/63-consult-past-decisions-before-design.md && echo "OK: cites source article"
grep -q '## 却下した案' docs/adr/63-consult-past-decisions-before-design.md && echo "OK: ADR-63 records rejected alternatives"
```

- [ ] 上記コマンドがすべて `OK:` を出力する
