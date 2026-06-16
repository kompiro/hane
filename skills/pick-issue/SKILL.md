---
name: pick-issue
description: >
  着手できる次の Issue を探して提示し、選んだら start-dev に引き継ぐ。
  作業中（status: implementing / designing）の Issue は別セッションが動いている
  可能性が高いため候補から除外する。
  Trigger when the user says: "次のIssue", "着手できるIssue", "Issueを探して",
  "次に何をやる", "pick issue", "next issue", "find an issue to work on",
  "what should I work on next", or similar phrases requesting to choose the next Issue.
---

# Pick Next Issue Skill

open な Issue から「いま着手できる」ものを選び出してユーザーに提示する。
複数の Claude Code セッションを並行運用するとき、**別セッションが作業中の Issue を
重複して掴まない**ことを最優先の目的とする。ユーザーが 1 件選んだら、そのまま
`start-dev` ワークフローへ引き継いで開発を開始する。

## 前提条件

- `gh auth status` で GitHub 認証済みであること

## ホスト repo に依存する慣習について

本 skill は `status: *` ラベル運用（`status: ready / blocked / implementing /
designing / designed / in-review`）があれば最大限活用するが、**ラベルが無い repo
でも動く**ように設計する。ラベルが定義されていない場合は、assignee と紐付く
open PR の有無だけで「作業中かどうか」を判定する（後述の手順 2）。

## 着手可否の判定基準

| 分類 | 条件 | 候補に含めるか |
|---|---|---|
| 作業中（別セッションが動いている可能性大） | `status: implementing` / `status: designing` | **除外** |
| レビュー中（作業はほぼ完了） | `status: in-review` | **除外** |
| 着手不可 | `status: blocked` | **除外** |
| 着手準備完了 | `status: ready` | **含める**（最優先） |
| 設計完了・実装待ち | `status: designed` | **含める** |
| ラベル無し | `status: *` ラベルがどれも付いていない open Issue | **含める**（label 運用が無い repo のフォールバックも兼ねる） |

加えて、ラベルに関わらず以下のいずれかに当てはまる Issue は「作業中」とみなして
**除外**する（label 運用が無い repo での主たる作業中検出手段）:

- **assignee が付いている** — 誰か（別セッション含む）が着手済みとみなす
- **open な linked PR / ブランチがある** — 本文に `Closes #N` / `Refs #N` を含む
  open PR が存在する、または Issue 番号に対応するブランチが push されている

## 手順

### 1. open Issue の取得

引数で対象を絞れる場合はそれを尊重する（例: ラベル指定 `/pick-issue area:core`）。
無ければ全 open Issue を取得する。

```
gh issue list --state open --limit 100 \
  --json number,title,labels,assignees,updatedAt,url
```

### 2. 作業中・着手不可を除外する

「着手可否の判定基準」表に従って候補を絞る。

1. ラベルベースの除外: `status: implementing` / `status: designing` /
   `status: in-review` / `status: blocked` のいずれかを持つ Issue を落とす。
   - **`implementing` / `designing` は特に重要** — 別セッションが現在作業している
     可能性が高いため、必ず除外する。
2. assignee ベースの除外: `assignees` が空でない Issue を落とす。
3. linked PR ベースの除外: open PR を一括取得し、本文の `Closes #N` / `Refs #N`
   / `Fixes #N`、または `headRefName` に Issue 番号を含むものを「作業中」として
   その Issue を落とす。

   ```
   gh pr list --state open --limit 100 --json number,headRefName,body
   ```
4. 残った Issue が「着手可能な候補」。0 件ならその旨を伝えて終了する
   （「いま着手できる Issue はありません。`status: ready` の Issue を用意するか、
   作業中ラベルの棚卸しを検討してください」）。

### 3. 候補のランク付け

残った候補を以下の優先度で並べる:

1. **status グループ**: `ready` → `designed` → ラベル無し の順
   （curate 済みのものを優先し、ラベル無しは最後に回す）
2. **priority ラベル**: `priority: *` 系ラベルがあれば高い順
3. **依存関係**: 本文に `depends on #X` / `blocked by #X` 等の記述があり、その
   `#X` がまだ open なら順位を下げる（または候補から外し、理由を添える）
4. **滞留時間**: 上記が同列なら `updatedAt` が古い順（放置を避ける）、なければ
   Issue 番号の小さい順

### 4. 候補の提示

上位 3〜5 件をユーザーに提示する。各候補について:

- `#番号 タイトル`
- status（ラベル無しなら「ラベル無し」）
- 推す理由（最優先である根拠・滞留時間・スコープの小ささ等）を 1 行

最上位を「推奨」として明示する。除外した「作業中」Issue があれば、**何件を
どの理由で除外したか**を 1 行で補足する（黙って絞らない）。

### 5. 選択と start-dev への連携

1. AskUserQuestion で着手する Issue を 1 件選んでもらう（推奨を先頭に置く）。
   - ユーザーが「どれも違う」場合は、絞り込み条件を聞き直すか終了する。
2. 選ばれた Issue 番号を引数として `start-dev` スキルを起動し、開発を開始する
   （Issue 読み込み → worktree 作成 → 計画 → 実装 → PR の流れ）。
   - `start-dev` 側で `status: implementing` への更新（ラベル運用がある場合）や
     worktree 作成を行うため、本 skill ではラベル更新は行わない。

## 注意

- **作業中 Issue を絶対に推奨しない。** 並行セッションの重複作業を防ぐことが本
  skill の存在意義。判定に迷う Issue（assignee 有り・linked PR 有り）は安全側に
  倒して除外する。
- 本 skill は読み取り専用の探索に徹し、ラベルや Issue の状態は変更しない。状態
  遷移は `start-dev` に委ねる。
- `status: *` ラベルが無い repo では、assignee と linked PR だけが作業中検出の
  手がかりになる。検出の確度が下がる旨を提示時に一言添えてよい。
