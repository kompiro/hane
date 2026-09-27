---
name: ship
description: >
  コミット済みの変更を PR 作成 → CI 確認 → クリーンアップまで進めるワークフロー。
  start-dev スキルを使わずに開発した場合にも対応する。
  Trigger when the user says: "ship", "ship it", "PRを作って", "PR作成",
  "プッシュしてPR", "出荷", "create PR", "push and PR", "submit PR",
  "マージまで", or similar phrases requesting to push, create a PR, or finish development.
---

# Ship Workflow

コミット済みの変更を PR 作成（draft）→ コードレビュー → ready → CI 確認 → クリーンアップまで進める。
`/start-dev` を使わずにブランチで直接開発した場合にも対応する。

## 前提条件

- `gh auth status` で GitHub 認証済みであること
- 現在のブランチが `main` でないこと（機能ブランチ上であること）
- コミット済みの変更があること

## ホスト repo に依存する慣習について

`/start-dev` skill と同じ optional 仕様に従う。`status: *` ラベル運用、preview deploy URL 表示、CHANGELOG 維持などはホスト repo が当該慣習を採用している場合のみ実行する。

## 手順

### 0. 状態確認

スキル開始時に現在の状態を自動検出する。

1. 現在のブランチ名を取得する: `git branch --show-current`
2. `main` ブランチ上の場合はエラーメッセージを表示して終了する
3. 未コミットの変更を確認する: `git status --porcelain`
   - 未コミットの変更がある場合、`/commit` スキルを実行してコミットする
   - コミット完了後、後続の処理を続行する
4. main からの差分コミット一覧を取得する: `git log --oneline origin/main..HEAD`
   - コミットがない場合はエラーメッセージを表示して終了する
5. worktree 内かどうかを判定する: `git rev-parse --show-toplevel`
   - パスに `.claude/worktrees/` または `.worktrees/` を含む場合は worktree 内と判定する
6. **依存関係をインストールする**（`package.json` がある場合のみ）
   - worktree 直後 / main から切り替えた直後 / lock file が更新された直後は `node_modules` が古く、pre-push hook の typecheck や test が依存不足で失敗する
   - 後続の commit / push より前に必ず実行する。host が lefthook / husky / pre-commit を採用している場合、install の `prepare` スクリプトで pre-push hook も設置される
   - パッケージマネージャは `package.json` の `packageManager` フィールドまたは lock file（`pnpm-lock.yaml` / `package-lock.json` / `yarn.lock`）から検出する
   - ロックファイルが最新なら即座に完了する
7. 関連 Issue を検出する:
   - ブランチ名からパターンマッチ（例: `feat/issue-42-xxx` → #42）
   - コミットメッセージ内の `#N` パターン
   - 見つからない場合はユーザーに Issue 番号を確認する（なしも可）
8. **CHANGELOG の追記を確認する**（ホスト repo が CHANGELOG を維持している場合のみ。リポジトリ直下に `CHANGELOG.md` が無い、または Keep a Changelog 形式の `## [Unreleased]` 見出しを持たない repo では本ステップをスキップする）
   - ブランチの差分が CHANGELOG に触れているか確認する: `git diff origin/main...HEAD --name-only | grep -i changelog`
   - 触れていない場合、変更がユーザーから見える挙動・ドキュメントを変えるものなら、`## [Unreleased]` 節への追記をユーザーに提案する（節が無ければ先頭に作る）。CI・内部ツールのみの変更など利用者影響が無いものは追記不要
   - 追記する場合は push より前に `/commit` でコミットに含める（push 後に気づくと PR に追従コミットが増える）
   - リリース手順自体（Unreleased の版上げ → tag 等）はこのスキルの責務外。host の手順（例: README の「Releasing」節）に従う

### 1. PR 作成

1. リモートにプッシュする:
   ```
   git push -u origin <branch-name>
   ```
   - host が pre-push hook を採用していれば push 時に自動実行される。**`--no-verify` / `LEFTHOOK=0` 等で hook を回避しない**
   - hook が失敗した場合は原因を直してから再 push する。failing hook を skip して `gh pr create` まで進めると、CI で初めて気づき手戻りが発生する
   - hook を採用していない host で push 前に手元確認したい場合は、host が提供する preflight 系コマンド（例: `pnpm preflight` / `make check`）があればそれを実行する。コマンド名は host の `package.json` scripts や `Makefile` から検出する
2. `git log --oneline origin/main..HEAD` と `git diff origin/main...HEAD --stat` で変更内容を分析する
3. PR 本文を生成する。`.github/PULL_REQUEST_TEMPLATE.md` のセクション構成に従い、コメントを実際の内容で埋める。テンプレートが無い場合は以下の最小構成にフォールバックする:

   - **Purpose**: `Closes #N` で Issue と紐付け。**Post-merge follow-ups に項目があるときは `Refs #N`**（項目の追記先として Issue を open のまま残す）。Issue がない場合は変更の目的を1行で記述（follow-ups があるなら先に Issue を起こす）
   - **Summary**: コミット履歴と差分から1-3行で要約
   - **Changes**: 主要な変更をリストで記述（コミット単位ではなく意味のある変更単位でまとめる）
   - **Manual Verification Checklist**: CI では検証できず、**マージ前に**この PR の preview かローカルの checkout で確認できる項目。なければ `N/A — all covered by automated tests`
   - **Post-merge follow-ups**: マージ後にしか観察・実行できない項目（次のリリース、次の自動レビュー、マージ後のバックフィルなど）。レビュー時にはチェックしない。なければ `N/A`
     - 振り分けの判断基準は 1 つ: **その項目をこの PR の preview かローカルの checkout で確認できるか**。できなければ follow-ups に置く
     - テンプレートにこの節が無い host でも、項目があれば節を足して書く
   - **Related Docs**: 更新した docs/ 内のファイル。なければ `N/A`

4. PR タイトルを生成する:
   - Conventional Commits 形式に準拠する（例: `feat(core): add team property parsing`）
   - ブランチのコミット群の主要な変更を反映する
   - 70文字以内に収める
5. 生成した PR タイトルと本文をユーザーに提示し、確認を得る
6. 承認後、`gh pr create --draft` で **draft の** PR を作成する:
   ```
   gh pr create --draft --title "<title>" --body "<body>"
   ```
   - 自動 PR レビュアー（CodeRabbit など）は ready の PR への push ごとにレビュー枠を 1 回使い、draft はレビューしない設定が一般的。ready で開いてからレビューの修正を push すると、直す前と直した後で 2 回使う。draft ならどちらも使わない
   - draft を skip しない host でも失うものは無い（ready にした時点で CI とレビューが 1 回走る）
7. PR の URL をユーザーに通知する

### 1.5. draft でのコードレビュー

**到達状態**: PR を ready にした時点で、コードレビューの修正がすでに push されている。

1. PR 番号を取得する（`gh pr create` の出力から）
2. **コードレビュー**: `/review <pr-number>` を実行して PR の変更内容をレビューする（host が別のレビューコマンドを定めていればそれを使う。例: `/code-review`）
3. 指摘ごとに対応可否を決め、直すものを `/commit` でコミットして **まとめて 1 回だけ** `git push` する
4. draft を外す: `gh pr ready <pr-number>`。CI と自動レビュアーはここで走り出す

### 2. CI 確認

1. CI の完了を待つ: `gh pr checks <pr-number> --watch`
2. CI の結果に応じて対応する:
   - **全て通過**: ステップ 2.5 のポストチェックへ進む
   - **失敗**: 失敗したジョブのログを確認し、修正を提案する
     - 修正が必要な場合: 修正 → `/commit` → `git push` → 再度 CI 確認

### 2.5. ポストチェック

CI 通過後、以下のチェックを順に実行する。

1. **コンフリクト確認**: `gh pr view <pr-number> --json mergeable` で確認する
   - `CONFLICTING` の場合はユーザーに通知し、コンフリクト解消を案内する
   - `MERGEABLE` または `UNKNOWN` の場合は次へ進む
2. **PR Description の言語確認**: `gh pr view <pr-number> --json title,body` で取得し、host repo の言語ポリシー（CLAUDE.md 等で定義されている場合）に沿っていることを確認する
   - ポリシーから外れている場合は警告し、修正を提案する

すべてのチェック完了後、Issue がある場合はラベルを `status: in-review` に更新する（ラベル運用がある場合のみ）:

   ```
   gh issue edit <N> --remove-label "status: implementing" --add-label "status: in-review"
   ```

完了メッセージ:

   ```
   CI・ポストチェックが完了しました。
   手動検証チェックリストの項目を確認してください。
   確認完了後、GitHub 上で PR をマージしてください。
   （Post-merge follow-ups がある場合、項目はマージ後に Issue #N に載ります。
    確認が済んだら Issue を close してください）

   マージ後に「クリーンアップして」と言っていただければ、
   ローカルブランチ（と worktree）を削除します。
   ```

> ここで Claude の作業は一旦完了。
> レビューと PR マージは GitHub 上でユーザーが行う。

### 3. クリーンアップ

ユーザーから「マージした」「クリーンアップして」等の指示を受けたら実行する。

1. PR の状態を確認する: `gh pr view <pr-number> --json state`
2. マージ済みでない場合は警告し、確認を求める
3. マージ済みの場合、環境に応じてクリーンアップする:

   **worktree 内の場合（パスに `.claude/worktrees/` または `.worktrees/` を含む）:**
   ```
   MAIN_ROOT=$(git worktree list | head -1 | awk '{print $1}')
   cd "$MAIN_ROOT"
   git worktree remove <worktree-path>
   git branch -d <branch-name>
   ```

   **通常ブランチの場合:**
   ```
   git checkout main
   git pull origin main
   git branch -d <branch-name>
   ```

4. main ブランチを最新化する（worktree の場合も実行）:
   ```
   git checkout main
   git pull origin main
   ```
5. Issue を更新する（Issue 紐付けがある場合。ラベル操作はラベル運用がある場合のみ）:
   - PR で `Closes #N` した Issue は GitHub が自動で close するため、ラベル操作は不要
   - **Post-merge follow-ups に項目がある PR**: 項目が `Refs #N` の Issue 本文に載っていることを確かめる。host の workflow が追記済みなら本文に `<!-- post-merge-followups #<PR番号> -->` があるので何もしない。無ければ次の形で本文末尾に追記する（`gh issue edit <N> --body-file <file>`）:
     ```
     ## Post-merge follow-ups from #<PR番号>

     <!-- post-merge-followups #<PR番号> -->
     - [ ] <PR の項目をそのまま>
     ```
     Issue は close せず、ラベルも `status: in-review` のまま残す（`pick-issue` の候補から外れる）。項目を消化して close するのはユーザー。未消化の項目を催促しない
   - 依存していた Issue（`status: blocked` のもの）があれば `status: ready` に更新する:
     ```
     gh issue edit <blocked-issue> --remove-label "status: blocked" --add-label "status: ready"
     ```
   - 依存関係の判断: Issue 本文や会話の文脈から判断する
6. クリーンアップ完了をユーザーに通知する

リモートブランチは GitHub 上で PR マージ時に自動削除される設定を推奨。
