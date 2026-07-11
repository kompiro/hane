# ADR-69: status ラベルの無い Issue に初期 status を付与する `triage-status` skill を hane に追加する

- **日付**: 2026-07-11
- **ステータス**: 決定済み
- **Issue**: [#69](https://github.com/kompiro/hane/issues/69)
- **関連**: [ADR-49](49-pick-issue-skill.md)（`status: *` を読んで着手対象を選ぶ側 / optional 慣習を存在で gating する先例）, `start-dev` / `ship` skill（`status: *` の lifecycle 遷移を更新する側）, [ADR-10](10-tpl-integration-into-skills.md)（optional 慣習の gating の先例）

## 背景

hane の `status: *` ラベル運用は、`start-dev` / `ship` が work の進行に合わせて
遷移させ、`pick-issue` がそれを読んで着手対象を選ぶ、という形で回っている。
しかし **新規に作られた Issue に「最初の status」を付ける主体がいない**。誰も
status を付けないまま Issue が溜まると、

- `pick-issue` の着手可否判定（ready / blocked 等）が効かず、ラベル無しフォール
  バックに落ちる
- 依存待ちの Issue が `blocked` と明示されず、うっかり着手されうる

という空白が生じる。既存 skill はこの「初期付与」をカバーしていない
（`start-dev` は着手時、`ship` は完了時の遷移のみ）。

論点は 3 つ: (1) どの status を初期付与の対象にするか / (2) 既に status がある
Issue をどう扱うか / (3) status をどう推論するか。

## 決定

`status: *` ラベルがまだ付いていない open Issue に、内容から推論した**初期 status**
を提案・確認・付与する optional な `triage-status` skill を新設する。

- **付与するのは初期 status のみ**。static に判断できる `status: ready` /
  `status: blocked` / `status: designed` の 3 つに限る。**active な状態
  （`designing` / `implementing` / `in-review`）は付与しない** — これらは「今まさに
  誰かが作業している」ことを表し、着手していない Issue に付けると実態とずれ、
  `pick-issue` の作業中除外を誤らせる。active 状態は `start-dev` / `ship` が work の
  進行に合わせて付ける。
- **既に status がある Issue は触らない**。上書き・遷移は lifecycle skill（`start-dev`
  / `ship`）の責務。本 skill は「status 空白の Issue」だけを対象にする。
- **status を内容から推論する**。open な依存の記述（`depends on #X` / `blocked by #X`
  で `#X` が open）→ `blocked`、承認済み design doc の存在 → `designed`、いずれでも
  なければ既定で `ready`。各提案に根拠を添え、迷う場合は安全側の `ready` に倒す。
- **確認なしの一括付与はしない**。推論は誤りうるため「提案 → 確認 → 付与」を基本と
  し、複数件でも承認を得てから適用する。
- **`status: *` ラベルの存在で gating する**。ラベルが定義されていない repo では
  何もできないため、その旨を伝えて終了し、ラベルは捏造しない。host の `CLAUDE.md`
  に新しいマーカーは導入しない（他 skill と同じ流儀）。

責務分離の全体像: **`triage-status` = 初期 status の付与 / `start-dev`・`ship` = その後
の遷移 / `pick-issue` = status を読んで着手対象を選ぶ**。

## 理由

- 初期付与を active 状態から切り離すのは、`designing` / `implementing` / `in-review`
  が「作業中」を意味し、その付与主体は work を実際に動かす `start-dev` / `ship`
  だから。着手していない Issue にこれらを付けると、`pick-issue` が「別セッションが
  作業中」と誤判定して候補から外してしまう（ADR-49 の作業中除外ロジック）。static に
  正しく判断できるのは ready / blocked / designed の 3 つに限られる。
- 既存 status を上書きしないのは、遷移が lifecycle skill に強く結びついているから。
  本 skill が既存 status を書き換えると、並行する `start-dev` / `ship` の遷移と衝突し、
  状態が実態からずれる。対象を「空白の Issue」に限ることで安全に共存できる。
- status を推論するのは、`ready` / `blocked` の区別（依存が解決済みか）が Issue 本文
  から static に判断できるから。特に `blocked` を open な依存の根拠が明確なときだけに
  絞ることで、誤って着手可能な Issue を塞ぐことを避ける。
- 確認を必須にするのは、誤った初期 status が後工程（`pick-issue` の着手判定）に伝播
  するから。安全側（`ready`）に倒し、確信のあるものだけ別 status を提案する。
- gating を他 skill と同型（存在するものだけ使う）にすることで、hane 全体が一貫した
  メンタルモデルで読める。

## 却下した案

- **type / epic / priority などの分類ラベルも本 skill で付与する** — 却下。当初案は
  分類ラベル付与を目的にしていたが、実運用で欲しいのは「status 空白 Issue の解消」
  だった。分類ラベルと status は判断の性質（分類はいつでも付けられる / status は
  lifecycle と同期）が異なり、1 つの skill に混ぜると責務が曖昧になる。まず status
  付与に絞る。
- **active な状態（implementing 等）も初期付与の候補にする** — 却下。着手していない
  Issue に active 状態を付けると、`pick-issue` が作業中と誤認して除外する。active
  状態の付与主体は work を動かす lifecycle skill に限るべき。
- **既存 status も見直して遷移させる** — 却下。遷移は `start-dev` / `ship` が担う。
  初期付与 skill が遷移も担うと二重管理になり、並行セッションの状態と衝突する。
- **`pick-issue` に初期 status 付与を取り込む** — 却下。`pick-issue` は読み取り専用の
  探索に徹する設計（ADR-49）で、status を書き換えない責務分離が肝。書き込みを混ぜると
  その前提が崩れる。トリガー意図も「次の Issue を選ぶ」と「status を付ける」で異なる。
- **status 未定義の repo では status ラベルを自動生成して付与する** — 却下。ラベル
  体系は repo オーナーの語彙。`/hane:init` がラベル作成を担うため、本 skill は存在で
  gating し、無ければ定義を促して終了する。
