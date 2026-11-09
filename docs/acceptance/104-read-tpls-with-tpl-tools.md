---
type: tool
---

# AT-104: `acceptance-test` / `design-doc` が tpl-tools の定義どおりに TPL を読む

- **日付**: 2026-11-09
- **Issue**: #104
- **PR**: なし
- **関連ADR**: ADR-92（proactive の判定は `root_cause_file` / `root_cause_adr`）, ADR-101（TPL を書く skill と CLI は tpl-tools）, ADR-10（tooling は host にあれば使う）
- **Related TPLs**: なし（hane は `docs/test-perspectives/` を採用しないため）
- **対象**: `skills/acceptance-test/SKILL.md`, `skills/design-doc/SKILL.md`, `CHANGELOG.md`

## 概要

`acceptance-test` は `issue:` を持つ TPL を retrospective と読んでいたので、Issue の下で起こした proactive TPL
（`design-doc` から起こす通常の形）のチェックリストを AT に転記しなかった。また両 skill は関連 TPL を
`tpl:related` のような host の script と frontmatter の grep で探しており、本文だけがファイルを名指す TPL を
取りこぼした。proactive の判定を ADR-92 に合わせ、関連 TPL は `tpl related` で引き、CLI が無いときは本文も grep する。

## 受け入れ条件

### AC-1: proactive を `root_cause_file` / `root_cause_adr` で判定する

```bash
f=skills/acceptance-test/SKILL.md
grep -q '`root_cause_file`（`concepts\*` 等の原則ファイル）か `root_cause_adr` があるかで決める' $f && echo "OK: proactive is decided by root_cause_*"
grep -q '`issue:` の有無では決めない' $f && echo "OK: issue: does not decide the origin"
! grep -q 'を指すものは retrospective' $f && echo "OK: the old issue-means-retrospective rule is gone"
```

- [ ] 上記コマンドがすべて `OK:` を出力する

### AC-2: 関連 TPL を `tpl related` で引き、CLI が無ければ本文も grep する

```bash
for f in skills/acceptance-test/SKILL.md skills/design-doc/SKILL.md; do
  grep -q '`@kompiro/tpl-tools` が devDependency にあれば `pnpm exec tpl` / `npx tpl`' $f && echo "OK: $f finds the tpl CLI"
  grep -q 'tpl related <topic>' $f && echo "OK: $f looks up by topic"
  grep -q 'TPL の本文' $f && echo "OK: $f greps TPL bodies without the CLI"
  ! grep -q 'tpl:related <topic>` 等のスクリプト' $f && echo "OK: $f no longer points to tpl:related scripts"
done
grep -q 'tpl related --base <base ブランチ> --limit 0' skills/acceptance-test/SKILL.md && echo "OK: acceptance-test looks up by changed files"
grep -q 'tpl related --changed-files --limit 0' skills/design-doc/SKILL.md && echo "OK: design-doc looks up by the files the design touches"
```

- [ ] 上記コマンドがすべて `OK:` を出力する（10 行）

### AC-3: 記録

```bash
sed -n '/## \[Unreleased\]/,/## \[0\./p' CHANGELOG.md | grep -q '(#104)' && echo "OK: CHANGELOG has the fix"
```

- [ ] 上記コマンドが `OK:` を出力する

## 手動確認

なし（skill の文言の変更で、上のコマンドで確かめられる）
