---
type: tool
---

# AT-101: test-perspective skill の tpl-tools への移設と hane 側の引退

- **日付**: 2026-11-07
- **Issue**: #101
- **PR**: なし
- **関連ADR**: ADR-101（本決定）, ADR-55（deprecate 運用）, ADR-10（一部を改める）, ADR-103（#103 で AC-3 の検査を広げた）
- **Related TPLs**: なし（hane は `docs/test-perspectives/` を採用しないため）
- **対象**: `.claude-plugin/marketplace.json`, `skills/test-perspective/SKILL.md`, `skills/design-doc/SKILL.md`, `skills/init/SKILL.md`, `README.md`, `.github/ISSUE_TEMPLATE/bug_report.yml`, `CHANGELOG.md`, `docs/adr/10-tpl-integration-into-skills.md`, `docs/adr/101-move-test-perspective-to-tpl-tools.md`, `docs/acceptance/13-test-perspective-skill.md`, `docs/acceptance/14-design-doc-tpl-aware.md`, `docs/acceptance/28-init-skill.md`

## 概要

TPL を書く skill が tpl-tools plugin に移ったので、hane の `test-perspective` を ADR-55 の Retire
レベルで引退させ、hane の他の skill の参照を後継に向け、marketplace に tpl-tools を載せる。

## 受け入れ条件

### AC-1: marketplace が tpl-tools を載せている

```bash
python3 -c "import json; p=json.load(open('.claude-plugin/marketplace.json'))['plugins']; print('OK: tpl-tools listed' if [x['source']['url'] for x in p if x['name']=='tpl-tools']==['https://github.com/kompiro/tpl-tools.git'] else 'NG'); print('OK: hane listed' if any(x['name']=='hane' for x in p) else 'NG')"
```

- [ ] 上記コマンドがすべて `OK:` を出力する

### AC-2: `test-perspective` が Retire レベルで deprecate され、後継を示している

```bash
f=skills/test-perspective/SKILL.md
grep -q '^deprecated: true' $f && echo "OK: deprecated marker"
grep -q '^deprecated_reason:' $f && echo "OK: reason"
grep -q '^superseded_by: tpl-tools:test-perspective' $f && echo "OK: superseded_by"
grep -q '⚠️ Deprecated' $f && echo "OK: banner"
! grep -qi 'Trigger when the user says' $f && echo "OK: trigger phrases removed"
grep -q '^disable-model-invocation: true' $f && echo "OK: model invocation disabled"
grep -q '\[Deprecated\]' $f && echo "OK: description prefixed [Deprecated]"
grep -q '## 手順' $f && echo "OK: body kept for provenance"
```

- [ ] 上記コマンドがすべて `OK:` を出力する

### AC-3: 他の skill が hane の `test-perspective` を呼ばない

```bash
! grep -rnE '/hane:test-perspective|`test-perspective` (スキル|skill)|\.\./test-perspective/' skills --exclude-dir=test-perspective && echo "OK: no reference to hane's skill"
grep -q '/tpl-tools:test-perspective' skills/design-doc/SKILL.md && echo "OK: design-doc points to the successor"
grep -q '/tpl-tools:test-perspective' skills/init/SKILL.md && echo "OK: init points to the successor"
```

- [ ] 上記コマンドがすべて `OK:` を出力する

### AC-4: `design-doc` と `acceptance-test` の TPL を読む手順が残っている

```bash
grep -q '## Related TPLs' skills/design-doc/SKILL.md && echo "OK: design-doc cites TPLs"
grep -q 'Related TPLs' skills/acceptance-test/SKILL.md && echo "OK: acceptance-test cites TPLs"
```

- [ ] 上記コマンドがすべて `OK:` を出力する

### AC-5: 周知と決定の記録が更新されている

```bash
grep -q '~~`test-perspective`~~' README.md && echo "OK: struck through in README table"
grep -q 'tpl-tools@kompiro-hane' README.md && echo "OK: README shows the install"
! grep -q 'test-perspective$' .github/ISSUE_TEMPLATE/bug_report.yml && echo "OK: removed from bug template"
sed -n '/## \[Unreleased\]/,/## \[0\./p' CHANGELOG.md | grep -q '### Deprecated' && echo "OK: CHANGELOG Deprecated"
test -f docs/adr/101-move-test-perspective-to-tpl-tools.md && echo "OK: ADR exists"
grep -q 'ADR-101' docs/adr/10-tpl-integration-into-skills.md && echo "OK: ADR-10 links ADR-101"
```

- [ ] 上記コマンドがすべて `OK:` を出力する

## 手動確認

- [ ] Claude Code で worktree のパスを `/plugin marketplace add` に渡し、`/plugin install tpl-tools@kompiro-hane` が成功する
- [ ] 入れた後、`/tpl-tools:test-perspective` が呼べる
