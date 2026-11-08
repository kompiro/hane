---
type: tool
---

# AT-103: #102 のレビューを受けた補正（Retire の定義、`init` の TPL id 形式、古い記録）

- **日付**: 2026-11-08
- **Issue**: #103
- **PR**: なし
- **関連ADR**: ADR-103（本決定）, ADR-101（補正の対象）, ADR-55（Retire の定義）, ADR-92（AT-92 の改訂）
- **Related TPLs**: なし（hane は `docs/test-perspectives/` を採用しないため）
- **対象**: `skills/init/SKILL.md`, `skills/design-doc/SKILL.md`, `skills/test-perspective/SKILL.md`, `skills/qa/SKILL.md`, `README.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, `docs/adr/55-skill-deprecation-convention.md`, `docs/adr/92-tpl-issue-anchor-for-proactive.md`, `docs/adr/101-move-test-perspective-to-tpl-tools.md`, `docs/adr/103-retire-disables-model-invocation-and-init-writes-tpl-config.md`, `docs/acceptance/28-init-skill.md`, `docs/acceptance/92-tpl-proactive-issue-anchor.md`, `docs/acceptance/101-retire-test-perspective.md`

## 概要

#102 にローカルの `/code-review` を当てて見つかった問題を直す。Retire でモデルからの呼び出しも止め、
`init` が TPL の id 形式を訊いて `tpl.config.json` に書き、古くなった記録を更新する。

## 受け入れ条件

### AC-1: `init` が TPL の id 形式を訊き、config を書く

```bash
f=skills/init/SKILL.md
grep -q '\*\*TPL の id 形式\*\*' $f && echo "OK: asks for the id format"
grep -q '"idFormat": "issue-number"' $f && echo "OK: writes issue-number by default"
grep -q 'ディレクトリが無いか空のときだけ' $f && echo "OK: .gitkeep and config only for a new or empty directory"
grep -q '`tpl init` は使わない' $f && echo "OK: does not use tpl init"
grep -q '/plugin marketplace update kompiro-hane' $f && echo "OK: init mentions the marketplace refresh"
```

- [ ] 上記コマンドがすべて `OK:` を出力する

### AC-2: Retire がモデルからの呼び出しも止める

```bash
for f in $(grep -l '^deprecated: true' skills/*/SKILL.md); do
  grep -q '^disable-model-invocation: true' $f && echo "OK: $f disables model invocation" || echo "NG: $f"
done
grep -q 'disable-model-invocation: true' README.md && echo "OK: README states the Retire level"
grep -q 'disable-model-invocation: true' CONTRIBUTING.md && echo "OK: CONTRIBUTING states the Retire level"
grep -q 'Do not follow the steps below' skills/test-perspective/SKILL.md && echo "OK: banner says not to follow the body"
```

- [ ] 上記コマンドがすべて `OK:` を出力し、`NG:` を出力しない

### AC-3: plugin が無いときの `design-doc` の手順と、marketplace の更新の案内がある

```bash
grep -q '未 TPL 化' skills/design-doc/SKILL.md && echo "OK: design-doc records the perspective when the plugin is not installed"
grep -q '/plugin marketplace update kompiro-hane' README.md && echo "OK: README mentions the marketplace refresh"
```

- [ ] 上記コマンドがすべて `OK:` を出力する

### AC-4: 記録の整合

```bash
test -f docs/adr/103-retire-disables-model-invocation-and-init-writes-tpl-config.md && echo "OK: ADR exists"
grep -q 'ADR-103' docs/adr/55-skill-deprecation-convention.md && echo "OK: ADR-55 links ADR-103"
grep -q 'ADR-103' docs/adr/101-move-test-perspective-to-tpl-tools.md && echo "OK: ADR-101 links ADR-103"
grep -q 'ADR-101' docs/adr/92-tpl-issue-anchor-for-proactive.md && echo "OK: ADR-92 links ADR-101"
! grep -q '番号もそこから採る' docs/acceptance/92-tpl-proactive-issue-anchor.md && echo "OK: AT-92 AC-3 no longer requires the Issue number"
grep -q 'idFormat: issue-number' docs/acceptance/92-tpl-proactive-issue-anchor.md && echo "OK: AT-92 AC-4 depends on idFormat"
! grep -q 'exclude-dir=qa' docs/acceptance/101-retire-test-perspective.md && echo "OK: AT-101 AC-3 covers qa"
sed -n '/## \[Unreleased\]/,/## \[0\./p' CHANGELOG.md | grep -q '"idFormat": "issue-number"' && echo "OK: CHANGELOG tells existing TPL repos to set idFormat"
```

- [ ] 上記コマンドがすべて `OK:` を出力する
- [ ] AT-101 の AC-3 のコマンドが `OK:` を出力する

## 手動確認

- [ ] tpl-tools が載る前に追加した `kompiro-hane` marketplace がある Claude Code で、`/plugin marketplace update kompiro-hane` の後に `/plugin install tpl-tools@kompiro-hane` が成功する
- [ ] hane をこのブランチの checkout から入れた Claude Code のセッションで、モデルが見る skill 一覧に `hane:qa` と `hane:test-perspective` が出ない
