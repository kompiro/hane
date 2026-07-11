---
name: triage-status
description: >
  `status: *` ラベルがまだ付いていない open Issue に、内容から推論した初期 status
  （ready / blocked / designed）を提案してユーザー確認のうえ付与する。pick-issue の
  前段で status 空白を解消する triage 工程。既に status が付いた Issue や lifecycle の
  遷移（implementing / designing / in-review）は対象外（start-dev / ship / pick-issue が管理）。
  Trigger when the user says: "statusを付与", "初期statusを付ける", "status未設定のissue",
  "issueのstatusを整理", "statusをtriage", "assign status label", "triage issue status",
  "triage status", "set initial status", "add status to issue", or similar phrases
  requesting to assign an initial status label to Issues that lack one.
---

# Triage Status Skill

`status: *` ラベルがまだ付いていない open Issue に、**初期 status ラベル**を付与する。
新規に作られた Issue は誰も status を付けないまま溜まりがちで、`pick-issue` の
着手可否判定や優先度付けが効きにくくなる。本 skill はその空白を埋め、内容から
妥当な初期 status を推論して「提案 → 確認 → 付与」する。

## 前提条件

- `gh auth status` で GitHub 認証済みであること
- repo に `status: *` ラベルが定義されていること（`status: ready` / `status: blocked` /
  `status: designed` など）。**未定義なら本 skill は何もできない** — その旨を伝えて
  終了する（`/hane:init` でのラベル作成を案内する）。ラベルは捏造しない。

## スコープと責務の分離

- **付与するのは「初期 status」だけ** — `status: *` ラベルが 1 つも付いていない
  Issue に対して、**最初の 1 つ**を付ける。付与しうるのは静的に判断できる
  `status: ready` / `status: blocked` / `status: designed` の 3 つ。
- **lifecycle の遷移は対象外**。`status: designing` / `status: implementing` /
  `status: in-review` は「今まさに誰かが作業している」ことを表す active な状態で、
  `start-dev` / `ship` が work の進行に合わせて更新する。本 skill はこれらを
  **付与しない**（誰も着手していない Issue にこれらを付けると実態とずれる）。
- **既に status が付いた Issue は触らない**。上書き・遷移は lifecycle skill の責務。
  本 skill は「status 空白の Issue」だけを対象にする。
- 責務分離のまとめ: **本 skill = 初期 status の付与 / `start-dev`・`ship` = その後の
  遷移 / `pick-issue` = status を読んで着手対象を選ぶ**。

## ホスト repo に依存する慣習について

- repo の `status: *` ラベルの**存在**で gating する（他 skill と同じ流儀。新しい
  ホストマーカーは導入しない）。ラベルが無ければ終了する。
- どの status 名が定義されているかは repo により異なる。取得したラベル集合の中から、
  意味的に対応するもの（着手可能 → ready 相当、依存待ち → blocked 相当、設計承認済み
  → designed 相当）を選ぶ。定義されていない status は提案しない。

## 手順

### 1. 対象 Issue の決定

- 引数で Issue 番号が指定されていれば、それ（複数可）を対象にする。
  例: `/triage-status 123`、`/triage-status 123 456`。
- 指定が無ければ、**`status: *` ラベルが 1 つも付いていない** open Issue を対象に
  する。

  ```
  gh issue list --state open --limit 100 --json number,title,labels,body,url
  ```

  対象が多い場合は、まず件数を伝えて、全件処理するか / 番号を絞るかを確認する
  （黙って一部だけ処理しない）。既に status が付いた Issue が引数指定に含まれて
  いたら「既に status あり」として skip する（上書きしない）。

### 2. status ラベルの把握

repo の全ラベルを取得し、`status: *` family を洗い出す。

```
gh label list --limit 200
```

- `status: *` が 1 つも無ければ、ここで終了する（前提条件参照）。
- 定義されている status 名を確認し、`ready` / `blocked` / `designed` 相当がそれぞれ
  どの名前かを把握する（repo により名称が違いうる）。

### 3. 各 Issue の初期 status を推論

対象 Issue ごとに title + body を読み、以下の順で初期 status を決める。

| 判定 | 条件 | 付与する status |
|---|---|---|
| 依存待ち | 本文に `depends on #X` / `blocked by #X` / 「#X が必要」等の記述があり、その `#X` がまだ **open** | `status: blocked` |
| 設計承認済み | 承認された design doc が既に存在する（本文にリンク／`docs/design/` の該当ファイル／「設計完了」「design approved」等の記述） | `status: designed` |
| 着手可能 | 上記いずれにも当てはまらない（依存が解決済み・特記なし） | `status: ready`（既定） |

- **active な状態（designing / implementing / in-review）は付与しない**。これらは
  実際に着手したときに lifecycle skill が付ける。
- 依存先 `#X` が既に closed なら「解決済み」とみなし blocked にしない。
- 各提案に**1 行の根拠**を添える（本文のどの記述・どの依存から判断したか）。判定に
  迷う場合は安全側の `ready` に倒す（`blocked` は open な依存の根拠が明確なときだけ）。

### 4. 確認

提案を提示し、AskUserQuestion で付与内容を確認する。

- 対象が 1 件: 推論した status と根拠を提示し、そのまま付与 / 別の status に変更 /
  中止 を選ばせる。
- 対象が複数件: Issue ごとに `#番号 タイトル → status: X（根拠）` を一覧提示し、
  全件承認 / 個別に見直し / 中止 を選ばせる。
- ユーザーが status を変えたい場合はそれを反映する。

### 5. 付与

承認された内容だけを適用する。

```
gh issue edit <N> --add-label "status: <ready|blocked|designed>"
```

- 対象 Issue には status が無い前提なので `--remove-label` は不要。
- active な状態（designing / implementing / in-review）は付けない。
- repo に無い status ラベルは付けない（捏造しない）。

### 6. 結果の報告

付与した Issue と status を 1 行ずつ報告する。skip した対象（既に status あり・
判断不能）があれば件数と理由を添える（黙って絞らない）。付与後は `pick-issue` で
着手対象を選べる旨を一言添えてよい。

## 注意

- **active な状態を付けない。** designing / implementing / in-review は「作業中」を
  意味し、着手していない Issue に付けると `pick-issue` の除外判定を誤らせる。初期
  付与で静的に判断できるのは ready / blocked / designed の 3 つだけ。
- **既に status が付いた Issue を上書きしない。** 遷移は `start-dev` / `ship` の責務。
- **`status: *` ラベルが無い repo では動かない。** ラベルを捏造せず、定義を促して終了する。
- 本 skill は初期 status の付与に徹し、Issue の選定（`pick-issue`）や開発着手
  （`start-dev`）は行わない。
