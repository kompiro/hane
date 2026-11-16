# ADR-110: adr-tools を使う host では、過去決定の確認を `/adr-tools:adr-search` で行う

- **日付**: 2026-11-16
- **ステータス**: 決定済み
- **Issue**: [#110](https://github.com/kompiro/hane/issues/110)
- **関連**: [ADR-63](63-consult-past-decisions-before-design.md)（本 ADR がその確認の手段を一部改める）, [ADR-101](101-move-test-perspective-to-tpl-tools.md)（別 repo の plugin の skill を呼び、hane に tooling を持ち込まない先例）, adr-tools [ADR-38](https://github.com/kompiro/adr-tools/blob/main/docs/adr/38-search-and-refs.md)（`adr search` / `adr refs`）, adr-tools [ADR-39](https://github.com/kompiro/adr-tools/blob/main/docs/adr/39-adr-search-skill-plugin.md)（`adr-search` skill）, [#109](https://github.com/kompiro/hane/pull/109)（`kompiro-hane` に adr-tools を載せた PR）

## 背景

ADR-63 は `start-dev` の手順 4.3 と `design-doc` の手順 2 に、設計の前に過去決定（とりわけ却下）を
確認する必須の手順を入れた。確認の手段は `docs/adr/` の grep である。

ADR を [`@kompiro/adr-tools`](https://github.com/kompiro/adr-tools) で管理する host では、grep で
見つけた ADR がいまも有効かが分からない。

- superseded の ADR は、`superseded_by` を手でたどらない限り現行の決まりに見える
- `supersedes` を書かずに一部を改めた後の ADR は、たまたまその語で grep しない限り見つからない
- エージェントは生成された索引（`effective.md` / `graph.md`）を丸ごと読みがちになる

adr-tools v0.0.14 は `adr search` / `adr refs` を持ち、adr-tools plugin の `adr-search` skill は
報告するすべての ADR を「有効」「有効だが一部改訂」「superseded」「無効」「proposed」「unresolved」の
どれかに分ける。報告の最後の「Decisions that need a discussion before overriding」は、`not_adopted` の
ADR と ADR の却下した案の節を含み、ADR-63 が狙う却下決定にあたる。#109 で `kompiro-hane` から
入れられるようになった。

## 決定

`start-dev` の手順 4.3 と `design-doc` の手順 2 で、**repo ルートに `adr.config.json` があるとき**は
`/adr-tools:adr-search` で ADR を確認する。報告の 2 つのリストを次のように使う。

- 「Decisions to keep」: 計画（`design-doc` では「制約・前提」）に、守る制約として書く
- 「Decisions that need a discussion before overriding」: ADR-63 の衝突として扱う

plugin が入っていなければ grep で確認し、`/plugin install adr-tools@kompiro-hane` を勧める。導入は
待たない。`adr.config.json` が無い host（hane 自身を含む）は従来どおり grep する。

確認の対象とする repo は「`docs/adr/` がある」から「`docs/adr/` か `adr.config.json` がある」に広げる。
adr-tools では `paths.adrDir` で ADR の置き場所を変えられるため。

## 理由

- **判定に `adr.config.json` を使うのは、観測できる事実だから。** adr-tools の CLI はこのファイルを
  読んで動く。ファイルがあれば `adr search` が動く見込みが高く、無ければ skill は CLI を使えない
- **導入を待たないのは、grep で確認自体は成り立つから。** `design-doc` の proactive TPL は skill が
  無いと書けないので導入を頼んで待つ（ADR-101）が、過去決定の確認は grep でもできる。待たせると、
  導入しない利用者の手順が止まる
- **2 つのリストを ADR-63 の手順に対応づけるのは、確認の到達点を変えないため。** ADR-63 の到達点は
  「却下決定との衝突を見つけて計画に反映する」で、手段が変わってもそれは同じ
- **hane に CLI を持ち込まない。** 呼ぶのは別 repo の plugin の skill で、ADR-101 の方針と同じ

## 却下した案

- **adr-tools を使う host でも grep のままにする**: 却下。superseded や一部改訂を grep では判別できず、
  現行でない決定を守るべき制約として計画に書くおそれがある
- **plugin が無ければ導入を頼んで待つ（ADR-101 の proactive TPL と同じ扱い）**: 却下。上記のとおり
  grep で確認は成り立つ
- **`adr.config.json` が無くても plugin があれば skill を使う**: 却下。skill は CLI と config を
  前提にしており、無い host では skill 自身が grep の fallback に落ちる。hane の grep の手順
  （日本語の `ステータス: 却下` や「## 却下した案」を狙う）の方が hane の ADR の書き方に合う

## 帰結

- adr-tools を使う host では、hane に加えて adr-tools plugin を入れると、過去決定の確認が
  有効かどうかの判定まで含むようになる
- hane 自身は `adr.config.json` を持たないので、hane の開発では従来どおり grep で確認する
