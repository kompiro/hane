---
name: security-alert
description: >
  Dependabot の security alert（GHSA / CVE 起因の脆弱性アラート）をトリアージして
  解決するワークフロー。open な alert を一括取得し、direct / transitive を判別して
  修正方針（PR マージ / 直接 bump / package manager の override）を決め、トラッキング
  Issue を作成して修正 PR を出し、判断根拠を ADR に記録する。transitive 依存で
  Dependabot が PR を起票しないケースを主対象にする。
  Trigger when the user says: "security alert", "セキュリティアラート",
  "Dependabot alert", "脆弱性対応", "GHSA", "CVE 対応", "security alert 対応",
  "handle security alerts", "triage security alerts", "dependabot security",
  "依存の脆弱性", or similar phrases requesting to process Dependabot security alerts.
---

# Dependabot Security Alert Triage Workflow

Dependabot の security alert（GitHub Advisory に基づく脆弱性アラート）を一括でトリアージし、
direct / transitive を判別して適切な修正方法で解決する。トラッキング Issue を作成し、修正 PR を
出し、判断結果と根拠を ADR に記録する。

## なぜ security alert を update PR と別 skill で扱うのか

`dependabot` skill は Dependabot が開いた **依存更新 PR** を捌く。security alert は別物として扱う。

- security alert は `gh api repos/{owner}/{repo}/dependabot/alerts` から取得する。open PR 一覧
  には現れない。
- **alert に対応する PR が存在しないことがある**。脆弱なパッケージが transitive 依存の場合、
  bump すべき直接の宣言行が `package.json` に無いため、Dependabot は security update PR を
  合成できず、alert だけが open のまま残る。
- transitive 依存の解決には、bot PR のマージではなく package manager の **override 機構**
  （pnpm `overrides` / npm `overrides` / yarn `resolutions`）を使うことが多い。

このため、`dependabot` skill の「open PR を列挙してトリアージ」とは収集元も解決手段も異なる。
本 skill は特に **transitive 依存で PR が起票されないケース**を主対象にする。

## 前提条件

- `gh auth status` で GitHub 認証済みであること
- ホスト repo が Dependabot security alert を有効化していること（リポジトリ設定の
  "Dependabot alerts"）
- alert / advisory の取得のため `gh api` および WebFetch でアクセスできること
- alert を読むには `gh` のトークンに security_events スコープ（または対象 repo の admin /
  security 権限）が必要

## ホスト repo に依存する慣習について

本 skill には以下の任意（optional）ステップが含まれる。ホスト repo がその慣習を採用して
いない場合は該当ステップをスキップする。

- **status ラベル**: `status: *` ラベル運用がある repo のみ、トラッキング Issue のラベルを
  更新する。
- **ADR**: `docs/adr/` を採用する repo のみ、判断結果を ADR に記録する（ステップ 8）。
  不採用の repo ではスキップし、結果を PR description に残すに留める。
- ADR のファイル名規約・言語・PR の auto-merge 可否は host repo の規約（`.claude/rules/` 等）
  に従う。

## 手順

### 1. Security alert の収集

open な Dependabot security alert を一括で取得する（**バッチ処理 — 全件を対象にする**）。

```
gh api repos/{owner}/{repo}/dependabot/alerts --paginate \
  --jq '.[] | select(.state=="open") | {
    number,
    pkg: .dependency.package.name,
    ecosystem: .dependency.package.ecosystem,
    manifest: .dependency.manifest_path,
    scope: .dependency.scope,
    relationship: .dependency.relationship,
    severity: .security_advisory.severity,
    ghsa: .security_advisory.ghsa_id,
    cve: .security_advisory.cve_id,
    summary: .security_advisory.summary,
    vuln_range: .security_vulnerability.vulnerable_version_range,
    patched: .security_vulnerability.first_patched_version.identifier
  }'
```

- 0 件なら「対応すべき Dependabot security alert はありません」と伝えて終了する。
- 同一 advisory が複数 manifest で alert 化されることがある（pnpm workspace では宣言と
  解決済みバージョンが別 manifest として計上される）。後段でまとめて扱う。

### 2. 各 alert のリスク分析

alert ごとに以下を整理する。

- **severity**: critical / high / medium / low。
- **advisory**: GHSA / CVE と summary。詳細は `gh api` の `security_advisory.description` や
  GitHub Advisory ページ（WebFetch）で確認する。
- **relationship**: `direct` / `transitive`。解決手段の分岐に直結する（ステップ 3）。
- **scope**: `runtime` / `development`。runtime のほうが優先度が高い。
- **vulnerable range / first patched version**: 修正版が存在するか。存在しない場合は
  緩和策（該当機能の不使用・代替パッケージ・`dismiss` 理由）を検討対象にする。
- **対応する PR の有無**: `gh pr list --author "app/dependabot" --state open` に当該 alert を
  解消する security update PR があるか。

各 alert に対応の緊急度（severity と scope から）と推奨修正方法（ステップ 3）を付ける。

### 3. 解決方針の決定（direct / transitive のルーティング）

`relationship` と PR の有無で修正方法を振り分ける。

| ケース | 修正方法 |
|---|---|
| direct 依存 + Dependabot security PR あり | その PR を `dependabot` skill でトリアージ・マージする（本 skill の対象外として委譲） |
| direct 依存 + PR なし | 該当 `package.json` の宣言バージョンを修正版以上に bump する |
| transitive 依存 | package manager の override 機構で修正版に pin する（下記） |

**transitive 依存の override**: package manager を `packageManager` フィールド / lock file
から判定し、対応する機構を使う。

- pnpm — root `package.json` の `pnpm.overrides`
- npm — root `package.json` の `overrides`
- yarn — root `package.json` の `resolutions`

**override キーのスコープ**: 同じパッケージの複数メジャーが依存ツリーに共存する場合、
無印キー（例 `"foo": "^5.0.6"`）で全メジャーを巻き上げると、脆弱性と無関係なメジャーまで
breaking な境界をまたいで強制昇格してしまう。**advisory の脆弱バージョン範囲が含むメジャー
だけにキーをスコープする**（例 pnpm/npm `"foo@5": "^5.0.6"`、yarn `"foo@^5.0.0": "^5.0.6"`）。
脆弱なメジャーが 1 系統しか無ければ無印キーでよい。

修正版が存在しない alert は、bump / override では解決できない。緩和策（該当機能の不使用、
代替パッケージへの移行、根拠を添えた alert の `dismiss`）をユーザーに提示し、判断を仰ぐ。

### 4. トラッキング Issue の作成

トリアージ結果をまとめた Issue を作成する（**1 回のバッチ = 1 Issue**）。

- タイトル例: `chore(deps): resolve Dependabot security alerts (<pkg>, ...)`。
- 本文に alert の一覧表（番号 / パッケージ / severity / advisory / relationship / 脆弱範囲 /
  修正版）と、ステップ 3 で決めた修正方針を書く。
- Issue の記述言語は host repo の規約に従う。
- `status: *` ラベル運用がある repo では着手時に `status: implementing` に更新する。

> 既に同等の Issue が open なら新規作成せず、それを使う。

### 5. Worktree 作成と修正

1. ブランチ・worktree を作成する（命名例 `chore/dependabot-security-<YYYY-MM-DD>` または
   `fix/security-<pkg>`、worktree は `.claude/worktrees/<branch>`）。
2. ステップ 3 の方針に従って修正する:
   - direct bump — 該当 `package.json` の宣言を修正版以上に書き換える。
   - transitive override — root `package.json` に override エントリを追加する。既存の
     override 群があれば並び順（アルファベット順など）の慣習に揃える。
3. lock file を更新する（`pnpm install` / `npm install` / `yarn install`）。

### 6. 検証

1. **lock file の解決バージョン**: 対象パッケージが修正版に解決されていることを確認する。
2. **巻き込みの確認**: override をスコープした場合、無関係なメジャーが据え置かれている
   ことを確認する。付随した無関係な minor / patch の更新があれば、それが脆弱性と無関係で
   あることを確認する。
3. **ビルド・テスト**: host の `package.json` `scripts` から `build` / `test` を検出して
   実行し、通過することを確認する。該当 script が無ければスキップする。
4. 公開パッケージを持つ repo では、公開物（バンドル・third-party notice 等）への影響有無を
   確認し、必要なら changeset 等のリリースメタを添える。

### 7. PR 作成

1. `/commit` skill で Conventional Commits 形式でコミットする（型は `chore` / `fix`、
   scope は `deps`）。コミットメッセージに GHSA / CVE を明記する。
2. `git push -u origin <branch>` でプッシュする。
3. `gh pr create` で PR を作成する。`.github/PULL_REQUEST_TEMPLATE.md` があればそれに従い、
   無ければ Purpose / Summary / Changes の最小構成にフォールバックする。ステップ 4 の Issue を
   `Closes #N` で紐付ける。
4. CI を `gh pr checks <番号> --watch` で確認し、失敗すれば修正して追加コミットをプッシュする。
5. `status: *` ラベル運用がある repo では `status: in-review` に更新する。
6. PR URL をユーザーに提示し、レビューとマージを依頼する。

### 8. ADR 記録

判断結果と根拠を ADR に記録する。`docs/adr/` を採用していない repo はスキップし、経緯は
PR description に残すに留める。

1. ADR には以下を記録する:
   - **背景**: どの alert が出ていたか（パッケージ / severity / advisory / relationship）。
   - **決定**: 各 alert をどの修正方法（PR マージ / direct bump / override）で解決したか。
   - **理由**: 特に transitive override を選んだ理由、override キーをスコープした場合は
     その理由（無印キーが無関係メジャーを巻き込む点）。
   - **却下した案**: 無印 override / `dismiss` / transitive を直接依存へ昇格 など、検討して
     退けた案があれば残す。
2. ADR のファイル名・見出し採番・言語は host repo の規約に従う（GitHub 番号ベース、
   Issue 番号 → PR 番号 → ローカル採番、など）。
3. ADR のみの PR として切り出してよい。host repo が ADR-only PR の auto-merge を運用して
   いれば、その規約に従う。

> 1 回のトリアージ実行 = 1 つの ADR。脆弱性をいつ・どの根拠で・どう解決したかを 1 件
> 1 ファイルで辿れるようにする。インシデント対応時の監査証跡になる。
