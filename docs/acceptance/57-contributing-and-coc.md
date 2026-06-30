---
type: tool
---

# AT-57: CONTRIBUTING and CODE_OF_CONDUCT for OSS release

- **日付**: 2026-06-30
- **Issue**: #57
- **PR**: なし
- **関連ADR**: ADR-55（skill deprecate 運用）, ADR-8（採番ルール）
- **Related TPLs**: なし（hane は `docs/test-perspectives/` を採用しないため）
- **対象**: `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `README.md`

## 概要

OSS 公開（#61）の前提として、コントリビューター向けの `CONTRIBUTING.md` と
`CODE_OF_CONDUCT.md` を追加し、README から辿れるようにする。

## 受け入れ条件

### AC-1: CONTRIBUTING.md が存在し、必須の規約に言及している

```bash
test -f CONTRIBUTING.md && echo "OK: CONTRIBUTING exists"
grep -qi 'dogfood' CONTRIBUTING.md && echo "OK: mentions dogfooding"
grep -q 'ADR-8' CONTRIBUTING.md && echo "OK: references issue-based numbering (ADR-8)"
grep -q 'ADR-55' CONTRIBUTING.md && echo "OK: references deprecation convention (ADR-55)"
grep -qi 'Conventional Commits' CONTRIBUTING.md && echo "OK: commit convention"
grep -q 'CODE_OF_CONDUCT.md' CONTRIBUTING.md && echo "OK: links Code of Conduct"
```

- [ ] 上記コマンドがすべて `OK:` を出力する

### AC-2: CODE_OF_CONDUCT.md が存在し、有効な連絡先を持つ

```bash
test -f CODE_OF_CONDUCT.md && echo "OK: CODE_OF_CONDUCT exists"
grep -qi 'Contributor Covenant' CODE_OF_CONDUCT.md && echo "OK: Contributor Covenant"
grep -q 'kompiro@gmail.com' CODE_OF_CONDUCT.md && echo "OK: enforcement contact present"
```

- [ ] 上記コマンドがすべて `OK:` を出力する

### AC-3: README から両ファイルへ辿れる

```bash
grep -q 'CONTRIBUTING.md' README.md && echo "OK: README links CONTRIBUTING"
grep -q 'CODE_OF_CONDUCT.md' README.md && echo "OK: README links Code of Conduct"
```

- [ ] 上記コマンドがすべて `OK:` を出力する
