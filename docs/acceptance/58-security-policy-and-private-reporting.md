---
type: tool
---

# AT-58: security policy for the public OSS release

- **日付**: 2026-07-09
- **Issue**: #58
- **PR**: なし
- **関連ADR**: ADR-58（SECURITY.md 先行 / PVR 有効化は #61 へ）, ADR-63（着手前の過去決定確認）
- **Related TPLs**: なし（hane は `docs/test-perspectives/` を採用しないため）
- **対象**: `SECURITY.md`, `CONTRIBUTING.md`, `README.md`, `docs/adr/58-security-policy-and-private-reporting.md`

## 概要

OSS 公開（#61）の前提として `SECURITY.md` を整備する。GitHub の private
vulnerability reporting は public repo 限定のため、有効化そのものは #61 の
フリップ後チェックリストへ移す。

## 受け入れ条件

### AC-1: SECURITY.md が存在し、必要な節を持つ

```bash
test -f SECURITY.md && echo "OK: SECURITY.md exists"
grep -q 'security/advisories/new' SECURITY.md && echo "OK: private reporting route"
grep -q 'kompiro@gmail.com' SECURITY.md && echo "OK: fallback contact"
grep -qi 'Supported versions' SECURITY.md && echo "OK: supported versions"
grep -qi 'Coordinated disclosure' SECURITY.md && echo "OK: disclosure policy"
grep -qi 'do not' SECURITY.md && echo "OK: warns against public issues"
```

- [ ] 上記コマンドがすべて `OK:` を出力する

### AC-2: hane 固有の攻撃面が scope に明記されている

```bash
grep -qi 'host repository' SECURITY.md && echo "OK: skills run in host repo"
grep -qi 'hooks' SECURITY.md && echo "OK: hooks in scope"
grep -qi 'Supply chain' SECURITY.md && echo "OK: distribution path"
grep -qi 'injection' SECURITY.md && echo "OK: prompt-injection paths"
grep -qi 'Out of scope' SECURITY.md && echo "OK: out-of-scope stated"
```

- [ ] 上記コマンドがすべて `OK:` を出力する

### AC-3: 導線が張られ、dead なプレースホルダが残っていない

```bash
grep -q 'SECURITY.md' CONTRIBUTING.md && echo "OK: CONTRIBUTING links SECURITY"
grep -q 'SECURITY.md' README.md && echo "OK: README links SECURITY"
# #57 で置いた「SECURITY.md は #58 で追加予定」のプレースホルダが消えている
! grep -q 'tracked in \[#58\]' CONTRIBUTING.md && echo "OK: placeholder removed"
```

- [ ] 上記コマンドがすべて `OK:` を出力する

### AC-4: 却下案（PVR 即時有効化）が ADR に記録されている

```bash
test -f docs/adr/58-security-policy-and-private-reporting.md && echo "OK: ADR-58 exists"
grep -q '## 却下した案' docs/adr/58-security-policy-and-private-reporting.md && echo "OK: rejected section"
grep -q 'いま PVR を有効化する' docs/adr/58-security-policy-and-private-reporting.md && echo "OK: records the infeasible option"
```

- [ ] 上記コマンドがすべて `OK:` を出力する

## 手動確認

- [ ] #61 の公開フリップ後、`gh api -X PUT repos/kompiro/hane/private-vulnerability-reporting` が成功し、リポジトリの Security タブに "Report a vulnerability" が出る
