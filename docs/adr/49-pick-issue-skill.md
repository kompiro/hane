# ADR-49: 次に着手できる Issue を選ぶ `pick-issue` skill を hane に追加する

- **日付**: 2026-06-16
- **ステータス**: 決定済み
- **Issue**: [#49](https://github.com/kompiro/hane/issues/49)
- **関連**: [ADR-10](10-tpl-integration-into-skills.md)（optional 慣習をディレクトリ/ラベルの存在で gating する先例）, `start-dev` skill（着手後の開発ワークフロー）, `open-pr` skill（`.claude/worktrees/` の並行 worktree を前提にした先例）

## 背景

hane は `.claude/worktrees/<branch-name>` に worktree を切って複数の Claude Code
セッションを並行運用する運用（`start-dev` / `open-pr`）を前提にしている。この運用
では「次にどの Issue に着手するか」を選ぶときに、**別セッションが既に作業中の
Issue を重複して掴む**事故が起きうる。

これまで着手対象の選定は人手で `gh issue list` を眺めて行っており、

- どの Issue が作業中かを毎回ラベル・assignee・open PR から目視で突き合わせる
- 並行セッションがあると、作業中の Issue をうっかり選んでしまう

という問題があった。`start-dev` は「Issue が決まった後」のワークフローであり、
「どの Issue を選ぶか」「作業中のものを除外するか」はカバーしていない。

論点は 2 つ: (1) 「作業中」をどう検出するか / (2) 提示後に `start-dev` へどう
つなぐか。

## 決定

着手できる次の Issue を探して提示し、選択後 `start-dev` へ引き継ぐ optional な
`pick-issue` skill を新設する。

- **「作業中」を多層で検出して除外する**。
  - ラベル運用がある repo では `status: implementing` / `status: designing` を
    最優先で除外する（別セッションが現在動いている可能性が高い状態）。あわせて
    `status: in-review`（作業ほぼ完了）と `status: blocked`（着手不可）も除外する。
  - ラベルに依存しない検出手段として、**assignee が付いている** / **open な
    linked PR・ブランチがある** Issue も「作業中」とみなして除外する。これにより
    `status: *` ラベルを採用していない repo でも作業中検出が機能する。
- **着手可能とみなすのは `status: ready` / `status: designed` / ラベル無しの
  open Issue**。ラベル無しを候補に含めることで、label 運用が無い repo でも
  フォールバックとして使える。
- **候補をランク付けして提示する**。`ready` → `designed` → ラベル無しの順を基本に、
  `priority: *` ラベル・依存関係（open な依存先があれば降格）・滞留時間で並べ、
  上位数件と推奨 1 件を提示する。除外した作業中 Issue の件数と理由も明示する
  （黙って絞らない）。
- **選択後は `start-dev` に引き継ぐ**。本 skill は読み取り専用の探索に徹し、ラベル
  更新・worktree 作成・状態遷移は `start-dev` に委ねる。責務を分離する。
- **optional 慣習として gating する**。`status: *` ラベルが無くても動く。ラベルが
  あれば活用し、無ければ assignee + linked PR で判定する。host の `CLAUDE.md` に
  新しいマーカーは導入しない — 他 skill と同じ流儀。

## 理由

- `implementing` / `designing` を除外する判断は、並行セッション運用の実情に直結
  する。これらは「今まさに別の誰か（別セッション）が触っている」状態であり、
  重複作業・コンフリクトを生む最大の原因なので、最優先で候補から外す。
- 作業中検出をラベルだけに頼らないのは、`status: *` ラベルが hane では optional
  だから。assignee と linked PR は GitHub の標準シグナルであり、ラベル運用が無い
  repo でも「誰かが掴んでいる」ことを高い確度で示す。多層で見ることで、ラベルの
  付け忘れや label 非採用 repo でも安全側に倒せる。
- ラベル無し Issue を候補に含めるのは、label 運用を採用していない repo を切り捨て
  ないため。ただし curate 済みの `ready` / `designed` より後ろに回し、優先度を
  下げることで、運用している repo では label の意図を尊重する。
- 探索と着手を分離（`pick-issue` → `start-dev`）するのは、`start-dev` が既に
  Issue 単位のワークフローとして完成しているため。状態遷移を二重に持たせず、
  `pick-issue` を「選ぶだけ」に保つことで、両 skill とも単純に保てる。
- gating を他 skill と同型（存在するものだけ使う）にすることで、hane 全体が
  一貫したメンタルモデルで読める。

## 却下した案

- **`start-dev` に Issue 選定機能を取り込む** — 却下。`start-dev` は「Issue が
  決まった後」の責務が既に大きい。選定ロジック（作業中除外・ランク付け）を混ぜると
  分岐が増え、トリガー語彙も「開発を始める」と「次の Issue を探す」で利用者の意図が
  異なる。別 skill にして `start-dev` を呼び出す形にするほうが責務が明確。
- **作業中の判定をラベルだけで行う** — 却下。`status: *` ラベルは hane では
  optional であり、label 非採用 repo では作業中をまったく検出できなくなる。
  assignee と linked PR を併用することで、ラベルが無くても機能する。
- **作業中 Issue も「作業中」と注記した上で候補に残す** — 却下。本 skill の存在
  意義は並行セッションの重複作業の防止であり、作業中 Issue を選択肢に残すと事故の
  余地を残す。安全側に倒し、判定に迷うものは除外する。
- **`pick-issue` 内でラベルを `implementing` に更新してから提示する** — 却下。
  状態遷移は `start-dev` が担う。探索段階で状態を書き換えると、ユーザーが結局
  着手しなかった場合に Issue の状態が実態とずれる。
