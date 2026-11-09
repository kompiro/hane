# ADR-104: proactive TPL は起源（失敗が既に起きていたか）で見分け、フィールドでは決めない

- **日付**: 2026-11-09
- **ステータス**: 決定済み
- **Issue**: [#104](https://github.com/kompiro/hane/issues/104)
- **関連**: [ADR-92](92-tpl-issue-anchor-for-proactive.md)（proactive も `issue:` を持つ。本 ADR はその「proactive かどうかは `root_cause_file` / `root_cause_adr` の有無で判定する」を改める）, [ADR-101](101-move-test-perspective-to-tpl-tools.md)（TPL の定義は tpl-tools が持つ）, [ADR-10](10-tpl-integration-into-skills.md)（tooling は host にあれば使う）, kompiro/tpl-tools#54（tpl-tools の skill の同じ文言）, kompiro/karasu `docs/test-perspectives/README.md`「起源と運用ルールは独立」（同じ基準）

## 背景

`acceptance-test` は proactive TPL のチェックリストを AT の AC に転記する。その見分け方は「`issue:` を持つものは
retrospective」のままで、ADR-92 以降は proactive も `issue:` を持つので、`design-doc` から起こした proactive TPL を
すべて取りこぼしていた（#104）。

#104 の修正では、`discovered_from` のフィールドで見分ける規則を 3 通り試し、ローカルのレビューのたびに外れる TPL が
見つかった（数は kompiro/karasu の TPL で数えた）。

- **ADR-92 のとおり `root_cause_*` の有無**: retrospective もバグの起きたソースを `root_cause_file` に書く
  （tpl-tools の `TEMPLATE.md` の例も `path/to/file.ts:symbol`）。`root_cause_*` を持つ 177 件のうち 103 件が、
  原則でないファイルだけを指す retrospective だった。
- **`root_cause_adr`、または原則の文書を指す `root_cause_file`**: retrospective も修正で生まれた ADR を
  `root_cause_adr` に書く。`root_cause_adr` を持つ 55 件のうち少なくとも 18 件は、先頭の `issue:` が `bug` /
  `test-infra` の Issue だった（すべてが retrospective とは限らない）。
- **迷ったら `issue:` の Issue のラベル**: `bug` の Issue の設計作業から proactive TPL が生まれることがある
  （karasu TPL-2631）。

karasu の TPL の README は、起源の基準を 1 つに定めている: **その TPL を起こした時点で、観点が防ぐ失敗が既に
起きていたかどうか**。個々のフィールドや Issue のラベルは起源を決めない。

## 決定

- `acceptance-test` は、その TPL を起こした時点で観点が防ぐ失敗が既に起きていたかで proactive を見分ける
  （起きていなければ proactive）。`discovered_from` の個々のフィールドや Issue のラベルだけでは決めない。
- 手がかりは次のとおり。どれも単独では決め手にならない。
  - 根拠エントリが原則側（`docs/concepts*` や spec を指す `root_cause_file`、`root_cause_adr`）を指すか、失敗した箇所を指すか
  - `## 想定される失敗モード` が実際に起きた失敗を書いているか
  - `issue:` の Issue が、観点が防ぐ失敗そのものの報告か
- 決められなければユーザーに尋ねる。
- `design-doc` から proactive TPL を起こすときは、根拠エントリを原則側に向ける（違反しうる原則を書いた文書を
  指す `root_cause_file`、または `root_cause_adr`）。
- `issue:` があること自体は起源を表さない（ADR-92 のまま）。

ADR-92 の本文は経緯として残し、書き換えない。

## 理由

- tpl-tools の起源の定義（retrospective は起きた失敗を一般化し、proactive は原則から予測する）と、karasu の README の
  基準に一致する。
- フィールドで見分ける規則は、どれも実在する TPL で外れた。外れると、retrospective のチェックリストを AT に多く転記するか、
  proactive のものを取りこぼし、どちらも AT の AC を誤らせる。

## 却下した案

- **`root_cause_*` の有無で判定する（ADR-92）**: 却下。上記のとおり retrospective の多くを proactive と読む。
- **`root_cause_adr`、または原則の文書を指す `root_cause_file` で判定する**: 却下。修正で生まれた ADR を引く
  retrospective を proactive と読む。
- **`issue:` の Issue のラベルで判定する（単独でも、迷ったときの補助でも）**: 却下。`bug` の Issue から生まれた
  proactive TPL を retrospective と読み、Issue の無い TPL を決められない。
- **起源で分けず、Design Doc の `## Related TPLs` に挙がった TPL を転記する**: 今回は見送り。forward 運用の出どころを
  直接見る案だが、Design Doc を経ない AT の扱いを決める必要があり、#104 の範囲を超える。

## 帰結

- 見分けはエージェントの判断になり、機械的には決まらない。判断がつかない TPL はユーザーに尋ねるので、AT 作成の対話が
  1 往復増えることがある。
- tpl-tools の skill の短い言い方（「`root_cause_file` / `root_cause_adr` の有無で判定」）は、kompiro/tpl-tools#54 で
  同じ基準に揃える。
