---
name: sync-worktrees
description: >
  他の PR を main にマージした後、進行中の各 worktree に main を取り込む
  (merge) ワークフロー。並行している worktree が main から遅れるのを一括で
  解消する。Trigger when the user says: "worktreeにmainを取り込む",
  "worktreeを最新化", "worktree同期", "mainを取り込む", "sync worktrees",
  "merge main into worktrees", "update worktrees with main", or similar phrases
  requesting to bring the default branch into in-flight worktrees.
---

# Sync Worktrees Skill

進行中の worktree（`.claude/worktrees/<branch>` など）に、マージ済みの最新
default ブランチ（通常 `main`）を **merge で取り込む**。複数の worktree を
並行で走らせていて、どれかの PR が main に入った後に残りを一括で追従させる
ためのもの。

- **merge であって rebase ではない**。worktree のブランチは PR として公開されて
  いる前提なので、履歴を書き換える rebase ではなく merge で取り込む。
- **push はしない**。ローカル merge までで止める。push は pre-push hook / CI を
  発火させるため、各 worktree での `pnpm i` 済み確認も含めてユーザーの判断に委ねる。
- **自動コンフリクト解決はしない**。衝突したらその worktree で止めて報告する。

## 前提条件

- 対象リポジトリ内（いずれかの worktree、または main 本体）で実行されていること。
- リモート追跡が設定されていること（`origin`）。

## 手順

### 1. default ブランチを特定して fetch する

1. default ブランチ名を自動検出する:
   `git rev-parse --abbrev-ref origin/HEAD`（例: `origin/main` → `main`）。
   取得できなければ `main`、無ければ `master` にフォールバックする。
2. 最新を取得する: `git fetch origin <default>`。
   - 以降この `origin/<default>` を取り込み元として使う。

### 2. 対象 worktree を列挙する

1. `git worktree list --porcelain` で全 worktree を取得する。
2. 各エントリについて、次を **対象から除外** する:
   - `bare` の worktree。
   - `detached`（detached HEAD）の worktree — 追従先ブランチが無いため。
   - ブランチが default ブランチそのものの worktree（main 本体は取り込み元なので対象外）。
3. 残った「feature ブランチを持つ worktree」が対象。
4. 引数でブランチ名 / worktree パスが渡された場合は、その 1 つだけに絞る
   （例: `/hane:sync-worktrees feat/key-generator`）。

### 3. 各対象 worktree を順に処理する

各 worktree のパスを `<wt>` として、`cd` せず `git -C <wt> ...` で操作する。

1. **作業中・未コミットの保護（skip 判定）**。次のいずれかに当たる worktree は
   **merge せずスキップ**し、理由を控える:
   - 未コミットの変更がある: `git -C <wt> status --porcelain` が非空。
   - 既に merge / rebase / cherry-pick が進行中: `<wt>` の git dir に
     `MERGE_HEAD` / `REBASE_HEAD` 等がある（`git -C <wt> status` で
     "You have unmerged paths" 等が出る）。

   これは他のセッションがその worktree で作業中の可能性に配慮した保護でもある
   （後述「並行作業との関係」）。

2. **既に最新なら skip**。`git -C <wt> merge-base --is-ancestor origin/<default> HEAD`
   が真なら、その worktree は既に default を含んでいるので "up-to-date" として
   スキップする。

3. **merge を実行**: `git -C <wt> merge --no-edit origin/<default>`。
   - 成功 → "updated" として控える。
   - **コンフリクト**（終了コード非 0、`git -C <wt> diff --name-only --diff-filter=U`
     が非空）→ "conflict" として控え、衝突ファイル一覧を報告する。
     **merge はその場に残したまま次の worktree へ進む**（勝手に abort しない）。
     ユーザーには次の 2 択を伝える:
     - その worktree で手で解決してコミットする、または
     - `git -C <wt> merge --abort` で取り込みを取り消す。

### 4. サマリを返す

処理後、件数を集計して報告する:

- **updated**: main を取り込んだ worktree（パスとブランチ名）。
- **conflict**: 衝突した worktree（衝突ファイルと、解決 / abort の案内）。
- **skipped (dirty / in progress)**: 未コミット・merge 進行中でスキップした worktree。
- **up-to-date**: 既に最新だった worktree。

push していないことを明記し、各 worktree の push（→ PR 更新・CI 発火）は
ユーザー判断であることを添える。

## 並行作業との関係

git の worktree は index・HEAD・作業ツリーがそれぞれ独立しており、worktree A の
ブランチへ merge しても worktree B には影響しない。git は worktree ごとに
`index.lock` で操作を直列化するので、データ破損の意味では安全に同時実行できる。

問題になるのは **取り込み先の worktree を別セッションが今まさに編集している**
場合だけ。merge はその worktree の作業ファイルを書き換えるため、相手の編集と
競合し得る。本 skill は次でこれを緩和する:

- **未コミット変更がある worktree は skip**（手順 3-1）。作業中セッションの多くは
  未コミットの編集を抱えているため、これで実害のあるケースの大半を外せる。
- 残る隙は「作業ツリーが clean なまま別セッションが次の編集に入ろうとしている」
  瞬間のみ。気になる場合は引数で対象 worktree を 1 つに絞るか、対象から外す。
