# ADR-104: proactive TPL は原則を指す `root_cause_file` か `root_cause_adr` で見分ける

- **日付**: 2026-11-09
- **ステータス**: 決定済み
- **Issue**: [#104](https://github.com/kompiro/hane/issues/104)
- **関連**: [ADR-92](92-tpl-issue-anchor-for-proactive.md)（proactive も `issue:` を持つ。本 ADR はその「proactive かどうかは `root_cause_file` / `root_cause_adr` の有無で判定する」を絞る）, [ADR-101](101-move-test-perspective-to-tpl-tools.md)（TPL の定義は tpl-tools が持つ）, [ADR-10](10-tpl-integration-into-skills.md)（tooling は host にあれば使う）, kompiro/tpl-tools#54（tpl-tools の skill の同じ文言）

## 背景

`acceptance-test` は proactive TPL のチェックリストを AT の AC に転記する。その見分け方は「`issue:` を持つものは
retrospective」のままで、ADR-92 以降は proactive も `issue:` を持つので、`design-doc` から起こした proactive TPL を
すべて取りこぼしていた（#104）。

ADR-92 の決定どおり「`root_cause_file` / `root_cause_adr` の有無」に直すと、今度は逆に外れる。retrospective の TPL も、
バグの起きたソースを `root_cause_file` に書く（tpl-tools の `TEMPLATE.md` の例も `path/to/file.ts:symbol`）。
kompiro/karasu では `root_cause_*` を持つ 177 件のうち 103 件がソースなど原則でないファイルだけを指す retrospective で、
有無で判定すると、それらのチェックリストが AT に転記される。

tpl-tools の skill の起源の定義は、proactive を「`root_cause_file: "docs/concepts.*"` または `root_cause_adr` を加えて持つ」と
書いており、ソースを指す `root_cause_file` を proactive の印にはしていない。ADR-92 の短い言い方だけが広すぎた。

## 決定

- proactive TPL は、`discovered_from` に `root_cause_adr` があるか、`root_cause_file` が原則を書いた文書
  （`docs/concepts*` のような原則ファイルや spec）を指すもの。`root_cause_file` があるだけでは proactive としない。
- `root_cause_file` が spec のように原則ともバグの現場とも読める文書を指すときは、`issue:` の Issue のラベルで決める
  （`bug` / `test-infra` なら retrospective。tpl-tools の retrospective の定義）。
- `issue:` があること自体は起源を表さない（ADR-92 のまま）。
- `design-doc` から proactive TPL を起こすときは、違反しうる原則を書いた文書を `root_cause_file` に書く（または
  `root_cause_adr`）。

ADR-92 の本文は経緯として残し、書き換えない。

## 理由

- 起源の定義（tpl-tools の skill）と一致し、実在する TPL の大半を正しく分ける。
- 判定に `issue:` を使わないという ADR-92 の要点は保つ。

## 却下した案

- **ADR-92 のとおり `root_cause_*` の有無で判定する**: 却下。上記のとおり retrospective の多くを proactive と読む。
- **`issue:` の Issue のラベルだけで判定する**: 却下。TPL ごとに GitHub を引く必要があり、Issue の無い TPL を決められない。
  原則の文書を指すかどうかで決まらないときの補助に留める。
