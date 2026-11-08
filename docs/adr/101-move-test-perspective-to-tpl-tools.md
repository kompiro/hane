# ADR-101: `test-perspective` skill を tpl-tools に移し、hane 側を引退させる

- **日付**: 2026-11-07
- **ステータス**: 決定済み
- **Issue**: [#101](https://github.com/kompiro/hane/issues/101)
- **関連**: [ADR-103](103-retire-disables-model-invocation-and-init-writes-tpl-config.md)（本 ADR の後、Retire の定義に `disable-model-invocation: true` を加え、`init` が TPL の id 形式を config に書くようにした）, [ADR-10](10-tpl-integration-into-skills.md)（本 ADR がその一部を改める）, [ADR-55](55-skill-deprecation-convention.md)（deprecate 運用。本 ADR はその適用）, [ADR-92](92-tpl-issue-anchor-for-proactive.md)（TPL の採番。tpl-tools の skill に引き継がれた）, tpl-tools [ADR-39](https://github.com/kompiro/tpl-tools/blob/main/docs/adr/39-test-perspective-skill-plugin.md)（skill の移設先と選択肢の比較）, [#99](https://github.com/kompiro/hane/issues/99)（ずれが表に出た bug）

## 背景

ADR-10 は TPL を書く `test-perspective` skill を hane に置き、tooling を host に留めた。当時の
tooling は karasu の `tpl:*` スクリプトで、TPL の書き方は skill の側が決めていた。

その後 tooling は [tpl-tools](https://github.com/kompiro/tpl-tools) に切り出され、書き方の規則
（生成された索引、チェックリストのマーカー、id の形式）の多くを tpl-tools が決めるようになった。
hane の skill はそれを後から追いかけることになり、生成された索引を手で編集させていた #99 のような
ずれが、host で TPL を書いて初めて見つかった。

tpl-tools は skill を自分の plugin として持つことにした（tpl-tools ADR-39）。hane に残るコピーは、
そのまま置いておくと 2 つ目の古い記述になる。

## 決定

hane の `test-perspective` skill を **Retire** レベルで引退させ、後継を tpl-tools plugin の
`tpl-tools:test-perspective` とする。hane の marketplace（`kompiro-hane`）に tpl-tools を載せて配る。
ADR-55 の Retire に加えて frontmatter に `disable-model-invocation: true` を付ける。トリガー語を外しても
`description` が残る限り、モデルが自動で選ぶ余地があるため。`/hane:test-perspective` と明示すれば呼べる。

ADR-10 のうち、次の点を改める。

- **skill の置き場所:** TPL の作成・更新・deprecate は tpl-tools の skill が担う
- **TPL のファイル名規約:** id の形式は host の tpl-tools の config（`idFormat`）に従う。hane は既定を定めない

ADR-10 のうち、次の点は変えない。

- **gating:** `docs/test-perspectives/` の有無で TPL の手順を切り替える
- **produce / consume の分離:** `design-doc` と `acceptance-test` は TPL を引用する側として hane に残る
- **hane に tooling を持ち込まない:** CLI も validator も hane には入らない

`init` は TPL の雛形をコピーしなくなる。`docs/test-perspectives/` を採用したら `.gitkeep` だけを作り、
tpl-tools の plugin と CLI を案内する。

## 理由

- **Retire にしたのは、同じ言葉に 2 つの skill が反応しないようにするため。** Soft-deprecate では
  トリガー語が残り、規則が古い hane の skill が動くおそれがある。後継は hane の skill の役割をすべて
  覆うので、ADR-55 の基準では Retire にあたる
- **marketplace の追加と引退を同じ PR にするのは、後継を入れられない期間を作らないため。** 引退した
  時点で、後継は同じ marketplace から入れられる
- **marketplace を hane のまま使うのは、利用者が追加する marketplace を増やさないため。** tpl-tools は
  自前の marketplace を持たない。タグには固定しない。tpl-tools の `plugin.json` は `version` を持つので、
  利用者に更新が届くのは tpl-tools のリリースで版が上がったときになる
- **`init` が雛形をコピーしないのは、引退した skill の雛形を新しい host に配らないため。** 後継の skill が
  雛形を持つので、host に写しを置く理由がない。tpl-tools の雛形を取得してコピーする案は、`init` が
  他の repo のパスに依存することになる

## 却下した案

- **Soft-deprecate で移行期間を置く**: 却下。上記のとおり古い skill が動き続ける。移行のために残す
  理由も薄い。引退後も `/hane:test-perspective` と明示すれば本文は読める
- **hane の skill を残して tpl-tools への案内だけにする（本文を消す）**: 却下。ADR-55 は経緯を辿れるよう
  本文を残すと定めている
- **hane に skill を残し、ずれを検査で拾う**: 却下（比較は tpl-tools ADR-39）。検査はずれを見つけるだけで、
  直す PR は別の repo に要る。hane にテストを持ち込まない方針とも合わない

## 帰結

- TPL を使う host は hane に加えて tpl-tools plugin を入れる。入れていない host では TPL を書く skill が
  自動では候補に出ない。`description` とバナーが移行先を示す
- `design-doc` が proactive TPL を起こす手順は tpl-tools の skill を呼ぶ。plugin が無ければ導入を案内する
- 引退した skill の本文は tpl-tools の規則を追わない。バナーがそのことを明示する
