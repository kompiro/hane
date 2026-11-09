---
type: tool
---

# AT-104: `acceptance-test` / `design-doc` が tpl-tools の定義どおりに TPL を読む

- **日付**: 2026-11-09
- **Issue**: #104
- **PR**: なし
- **関連ADR**: ADR-104（本決定）, ADR-92（proactive も `issue:` を持つ。ADR-104 が判定を絞る）, ADR-101（TPL を書く skill と CLI は tpl-tools）, ADR-10（tooling は host にあれば使う）
- **Related TPLs**: なし（hane は `docs/test-perspectives/` を採用しないため）
- **対象**: `skills/acceptance-test/SKILL.md`, `skills/design-doc/SKILL.md`, `docs/adr/104-proactive-tpl-by-principle-root-cause.md`, `docs/adr/92-tpl-issue-anchor-for-proactive.md`, `README.md`, `CHANGELOG.md`, `docs/acceptance/12-acceptance-test-tpl-aware.md`, `docs/acceptance/14-design-doc-tpl-aware.md`

## 概要

`acceptance-test` は `issue:` を持つ TPL を retrospective と読んでいたので、Issue の下で起こした proactive TPL
（`design-doc` から起こす通常の形）のチェックリストを AT に転記しなかった。また両 skill は関連 TPL を
`tpl:related` のような host の script と frontmatter の grep で探しており、本文だけがファイルを名指す TPL を
取りこぼした。proactive の判定を tpl-tools の起源の定義（`root_cause_adr`、または原則ファイルを指す `root_cause_file`）に
合わせ（ADR-104）、関連 TPL は topic・変更対象モジュール・変更ファイルの 3 つの手がかりで引く。

## 受け入れ条件

### AC-1: proactive を `root_cause_adr` と原則を指す `root_cause_file` で判定する

```bash
f=skills/acceptance-test/SKILL.md
grep -q '`root_cause_adr` があるか、`root_cause_file` が原則を書いた文書' $f && echo "OK: proactive is decided by root_cause_adr or a principle-document root_cause_file"
grep -q '`root_cause_file` があるだけでは proactive としない' $f && echo "OK: a source root_cause_file alone is not proactive"
grep -q '`issue:` の Issue のラベルで決める' $f && echo "OK: an ambiguous document falls back to the Issue label"
grep -q '`issue:` があること自体では決めない' $f && echo "OK: issue: does not decide the origin"
grep -q 'docs/adr/104-proactive-tpl-by-principle-root-cause.md' $f && echo "OK: the rule links ADR-104"
! grep -q 'を指すものは retrospective' $f && echo "OK: the old issue-means-retrospective rule is gone"
grep -q '違反しうる原則を書いた文書を指す `root_cause_file`' skills/design-doc/SKILL.md && echo "OK: design-doc writes a principle-pointing root_cause_file"
```

- [ ] 上記コマンドがすべて `OK:` を出力する（7 行）

### AC-2: 関連 TPL を 3 つの手がかりで引く

```bash
for f in skills/acceptance-test/SKILL.md skills/design-doc/SKILL.md; do
  grep -q '`@kompiro/tpl-tools` が devDependency にあれば `pnpm exec tpl` / `npx tpl`' $f && echo "OK: $f finds the tpl CLI"
  grep -q 'script は用途ごとに選' $f && echo "OK: $f picks a host script per lookup"
  grep -q 'host の script が渡している `--config` を同じく渡す' $f && echo "OK: $f keeps the host config on a direct call"
  grep -q 'tpl related <topic>' $f && echo "OK: $f looks up by topic"
  grep -q 'CLI があってもこの grep は行う' $f && echo "OK: $f keeps the frontmatter grep alongside the CLI"
  grep -q '`scope.packages` / `applicable_to` / `known_consumers`' $f && echo "OK: $f greps all module fields"
  grep -q '拡張子を除いたパス' $f && echo "OK: $f greps TPL bodies by path without the CLI"
  grep -q '`scope.paths` の glob と照らす' $f && echo "OK: $f matches scope.paths without the CLI"
  grep -q 'v0.0.13 以前なら' $f && echo "OK: $f falls back on an old CLI"
  ! grep -q 'tpl:related' $f && echo "OK: $f no longer points to tpl:related scripts"
done
f=skills/acceptance-test/SKILL.md
grep -q 'tpl related --base origin/<base ブランチ> --limit 0' $f && echo "OK: acceptance-test looks up by the committed diff"
grep -q 'まだ実装していないときは' $f && echo "OK: acceptance-test passes planned files before implementation"
grep -q '`--base` と `--changed-files` は同時に渡せない' $f && echo "OK: acceptance-test does not combine --base and --changed-files"
grep -q 'git ls-files --others --exclude-standard' $f && echo "OK: acceptance-test says how to collect uncommitted files"
grep -q 'tpl related --changed-files --limit 0' skills/design-doc/SKILL.md && echo "OK: design-doc looks up by the files the design touches"
```

- [ ] 上記コマンドがすべて `OK:` を出力する（25 行）

### AC-3: 記録

```bash
test -f docs/adr/104-proactive-tpl-by-principle-root-cause.md && echo "OK: ADR-104 exists"
grep -q 'ADR-104' docs/adr/92-tpl-issue-anchor-for-proactive.md && echo "OK: ADR-92 links ADR-104"
sed -n '/## \[Unreleased\]/,/## \[0\./p' CHANGELOG.md | grep -q '(#104)' && echo "OK: CHANGELOG has the fix"
! grep -q 'tpl:related' README.md && echo "OK: README no longer names tpl:related tooling"
grep -q 'module fields in the frontmatter are always grepped' README.md && echo "OK: README describes the frontmatter grep"
! grep -q 'tpl:related' docs/acceptance/12-acceptance-test-tpl-aware.md docs/acceptance/14-design-doc-tpl-aware.md && echo "OK: AT-12 and AT-14 match the skills"
grep -q '`issue:` の有無を使わない' docs/acceptance/12-acceptance-test-tpl-aware.md && echo "OK: AT-12 no longer reads issue: as retrospective"
```

- [ ] 上記コマンドがすべて `OK:` を出力する（7 行）

## 手動確認

なし（skill の文言の変更で、上のコマンドで確かめられる）
