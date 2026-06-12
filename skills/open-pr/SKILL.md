---
name: open-pr
description: >
  Open the pull request for the branch you are working on in the browser via
  `gh pr view --web`. Trigger when the user says: "PRを開いて", "PRをブラウザで",
  "PRを見せて", "open pr", "open the PR", "show me the PR", or similar phrases
  requesting to open the working pull request in the browser.
---

# Open PR Skill

作業中のブランチに対応する PR を `gh pr view --web` でブラウザに開く。
毎回コマンドを手で打つ手間をなくすためのショートカット。

## 手順

1. 引数が渡されていればそれを優先する。PR 番号またはブランチ名とみなして
   `gh pr view <引数> --web` を実行し、終了する（例: `/open-pr 42`）
2. 引数がなければ対象ブランチを決める:
   - カレントディレクトリ（またはこのセッションで作業中の worktree）の
     ブランチが `main` / `master` 以外なら、それを対象にする
   - main 上にいる場合は `git worktree list` で `.claude/worktrees/` 配下の
     worktree を列挙し、各ブランチの PR を
     `gh pr view <branch> --json url,state,title` で確認する
     - open な PR が 1 件だけならそれを対象にする
     - 複数あれば AskUserQuestion でどれを開くか選んでもらう
     - 0 件なら `gh pr list --author @me` の結果を見せて、開ける PR が
       ないことを伝えて終了する
3. `gh pr view <branch> --web` を実行し、開いた PR のタイトルと URL を
   ユーザーに伝える

## 注意

- ブラウザを起動できない環境（ヘッドレス等）で `--web` が失敗したら、
  `gh pr view <branch> --json url -q .url` で URL だけ表示する
