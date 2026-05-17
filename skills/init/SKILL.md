---
name: init
description: >
  Scaffold the host-repo conventions the hane skills expect — doc directories, document
  templates, a process.md skeleton, and optionally status labels and a rules directory.
  Trigger when the user says: "hane init", "init", "初期設定", "セットアップ", "scaffold",
  "hane を導入", "ディレクトリ構造をセットアップ", "set up hane", or similar phrases requesting
  host-repo setup for the hane skills.
---

# Host Repo Init Skill

hane の各 skill（`start-dev` / `design-doc` / `acceptance-test` / `test-perspective` /
`qa` など）は、host repo が一定のディレクトリ・ドキュメント慣習を採用していることを
前提に動く。このスキルは、その初期セットアップを対話で行う。

このスキルの価値は「固定のファイルを置くこと」ではなく、**repo ごとに異なる選択を
対話で決め、hane が前提とする慣習の単一の出所になること**にある。選択肢を持たず
固定構造を吐くだけならテンプレート repo やシェルスクリプトで足りる。

## 手順

### 1. 前提確認

- カレントが git repo であることを確認する（でなければ `git init` を提案する）。
- `.gitignore` に `.claude/worktrees/` が含まれているか確認する。無ければ追記を
  提案する（`start-dev` / `ship` / `design-doc` がここに worktree を作るため）。

### 2. 既存状態のスキャン

`docs/{design,adr,acceptance,test-perspectives}/`、`docs/process.md`、`.claude/rules/`、
`status: *` ラベルの有無を調べる。**このスキルは冪等**で、既に存在するものは
上書きせず skip する。スキャン結果を踏まえて次の質問を出す。

### 3. 4 つの選択をユーザーに確認

以下を対話で確認する（既に存在するものは「採用済み」として扱い、質問から除いてよい）。

1. **採用するドキュメントディレクトリ** — `docs/design/`（Design Doc）/
   `docs/adr/`（ADR）/ `docs/acceptance/`（受け入れテスト）/
   `docs/test-perspectives/`（TPL）のうちどれを採用するか。複数選択可。
2. **ADR のファイル名規約** — GitHub 番号ベース（`<番号>-slug.md`、hane の既定。
   ADR-8 参照）か、日付ベース（`YYYYMMDD-NN-slug.md`、karasu 方式）か。
   `docs/adr/` を採用する場合のみ訊く。
3. **`status: *` ラベル運用** — `start-dev` / `ship` が Issue の進捗を
   `status: ready / blocked / implementing / designing / designed / in-review`
   ラベルで追跡する運用を採用するか。
4. **`.claude/rules/` ディレクトリ** — repo 固有の authoring ルール（ADR の言語など）
   を置くディレクトリを作るか。

### 4. scaffold する

回答に基づき、以下を生成する。**既存ファイルは上書きしない**（skip して記録する）。

| 選択 | 生成物 |
|---|---|
| `docs/design/` を採用 | `docs/design/TEMPLATE.md` |
| `docs/adr/` を採用 | `docs/adr/TEMPLATE.md` |
| `docs/acceptance/` を採用 | `docs/acceptance/TEMPLATE.md` |
| `docs/test-perspectives/` を採用 | `docs/test-perspectives/TEMPLATE.md` |
| いずれかの doc ディレクトリを採用 | `docs/process.md`（スケルトン。下記参照） |
| `.claude/rules/` を採用 | `.claude/rules/.gitkeep` |
| ラベル運用を採用 | `status: *` ラベル 6 種を `gh label create` で作成 |

#### テンプレートアセットのコピー元

各 `TEMPLATE.md` は **hane plugin 内の skill アセットをコピー**する（複製・再生成
しない）。コピー元はこの `init` skill のディレクトリからの相対パス:

| 生成物 | コピー元 |
|---|---|
| `docs/design/TEMPLATE.md` | `../design-doc/TEMPLATE.md` |
| `docs/adr/TEMPLATE.md` | `../design-doc/ADR-TEMPLATE.md` |
| `docs/acceptance/TEMPLATE.md` | `../acceptance-test/TEMPLATE.md` |
| `docs/test-perspectives/TEMPLATE.md` | `../test-perspective/TEMPLATE.md` |

コピー後、内容は変更しない。各テンプレート冒頭の HTML コメントに規約（ファイル名・
言語・番号規約）が書かれているので、host repo 側で追加の説明は不要。

#### `status: *` ラベルの作成

ラベル運用を採用する場合、以下を `gh label create "<name>" --color <hex> --description "<desc>"`
で作成する（既存ラベルは skip）:

| ラベル | 用途 |
|---|---|
| `status: ready` | 着手可能 |
| `status: blocked` | 依存待ちで着手不可 |
| `status: designing` | Design Doc 作成中 |
| `status: designed` | 設計承認済み・実装着手可能 |
| `status: implementing` | 実装中 |
| `status: in-review` | レビュー中 |

色は任意（例: ready=緑、blocked=赤、それ以外=黄系）。

#### `docs/process.md` スケルトン

選択した内容を反映した最小限の `docs/process.md` を生成する。含める節:

- **ドキュメントのライフサイクル** — アイデア（Issue）→ 設計（`docs/design/`、採用時のみ）
  → 決定（`docs/adr/`、採用時のみ）の流れ。
- **ブランチ・worktree ルール** — `main` への直 push 禁止、worktree は
  `.claude/worktrees/<branch-name>`、ブランチ命名（`feat/` `fix/` `docs/` `chore/`
  `refactor/` + kebab-case）。
- **採番規約** — 選んだ ADR ファイル名規約。AT / TPL も同じ番号ベース。
- **ラベル運用** — 採用した場合のみ、`status: *` の遷移を記す。
- 各ドキュメント種別を採用した場合は、対応する `/hane:` skill（`design-doc` /
  `acceptance-test` / `test-perspective`）で記録を作る旨を 1 行ずつ書く。

process.md は host repo がその後育てる前提のスケルトン。冒頭にその旨を明記する。

### 5. 結果のレポート

生成したファイル・ラベルと、既存のため skip したものを一覧で報告する。

### 6. 完了後の案内

次のステップを短く示す:

- host repo の `CLAUDE.md` に hane の利用を 1 節追記する（このスキルは
  `CLAUDE.md` の内容には踏み込まない — repo 固有のため）。
- `/hane:start-dev` で最初の開発を始められる。

## 冪等性

このスキルは何度実行しても安全であること。2 回目以降の実行では、既に存在する
ファイル・ディレクトリ・ラベルはすべて skip し、不足分だけを補う。実行のたびに
created / skipped の内訳をレポートする。

## スコープ外

- host repo の `CLAUDE.md` の生成・編集（repo 固有すぎる。利用者に追記を促すのみ）。
- 既に独自の慣習で運用している repo の移行・整合（このスキルは**不足を埋めるだけ**で、
  既存の構造を作り変えない）。
