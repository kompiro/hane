---
name: dependabot
description: >
  Dependabot の依存更新 PR を一括でトリアージするワークフロー。各 PR の更新内容を
  upstream リポジトリまで遡ってサプライチェーン観点でリスク分析し、マージ推奨可否を
  Design Doc にまとめてユーザーに返す。ユーザーの判断後、承認分をマージ・却下分を
  クローズし、判断結果と根拠を ADR に記録する。
  Trigger when the user says: "dependabot", "依存更新", "依存関係の更新",
  "Dependabot PR", "dependabot対応", "依存をまとめて更新",
  "handle dependabot", "triage dependabot", "review dependabot PRs",
  or similar phrases requesting to process Dependabot update PRs.
---

# Dependabot Update Triage Workflow

Dependabot が開いた依存更新 PR を一括で取り込み、各更新を **upstream リポジトリまで遡って
リスク分析**し、マージ可否の判断材料を Design Doc としてユーザーに返す。ユーザーが採否を
決定したら、承認分を反映し、判断結果と根拠を ADR に記録する。

## なぜ全 PR でリスク分析を必須にするか

サプライチェーン攻撃（メンテナアカウントの乗っ取り、悪意ある postinstall スクリプトの
混入、リポジトリ移管後の改ざん、typosquatting な transitive 依存の追加）が増えており、
semver の bump 種別（patch / minor / major）や互換性スコアだけでは安全性を判断できない。
`patch` であっても公開物に悪意あるコードが含まれうる。

このため本 skill は **bump 種別を問わずすべての PR を upstream まで遡って確認**し、
リスク分析を省略しない。「patch だから自動マージ」という分岐は設けない。

## 前提条件

- `gh auth status` で GitHub 認証済みであること
- ホスト repo が Dependabot（`.github/dependabot.yml`）を有効化していること
- リスク分析のために upstream リポジトリやパッケージレジストリへ WebFetch / `gh api`
  でアクセスできること

## ホスト repo に依存する慣習について

本 skill には以下の任意（optional）ステップが含まれる。ホスト repo がその慣習を採用して
いない場合は該当ステップをスキップする。

- **Design Doc**: `docs/design/` を採用する repo のみ、トリアージ結果を Design Doc として
  残す（ステップ 4）。不採用の repo では結果を会話および各 PR へのコメントで返す。
- **ADR**: `docs/adr/` を採用する repo のみ、判断結果を ADR に記録する（ステップ 7）。
  不採用の repo ではスキップし、結果を ADR PR のコメント等で残すに留める。
- ADR / Design Doc のファイル名規約・言語は host repo の規約（`.claude/rules/` 等）に従う。

## 手順

### 1. Dependabot PR の収集

開いている Dependabot PR を一括で取得する（**バッチ処理 — 全件を対象にする**）。

```
gh pr list --author "app/dependabot" --state open \
  --json number,title,headRefName,labels,body,createdAt
```

- 0 件なら「対応すべき Dependabot PR はありません」と伝えて終了する。
- Dependabot のグループ更新 PR（複数依存をまとめた PR）も 1 件として扱う。
- セキュリティ更新 PR（`security` ラベル付き）は優先度を高く扱う。**そのパッケージが
  override 機構（pnpm `overrides` / npm `overrides` / yarn `resolutions`）にも載っている
  場合は、`security-alert` skill の「advisory の脆弱範囲を自分の pin と突き合わせる」を
  先に回す。** override の floor が脆弱範囲の内側だと、bot PR をマージしても解決が戻る
  か、`ERR_PNPM_LOCKFILE_CONFIG_MISMATCH` で CI が通らない。

### 2. 各 PR のメタデータ抽出

PR ごとに以下を整理する。

- **エコシステム**: ブランチ名 `dependabot/<ecosystem>/...`（`npm_and_yarn` / `pip` /
  `github_actions` / `bundler` など）から判定する。
- **依存名と版**: `<name>` を `<from>` → `<to>` へ。PR 本文・タイトルから抽出する。
- **bump 種別**: `<from>` と `<to>` を比較して patch / minor / major を判定する。
- **direct / transitive**: PR 本文の Dependabot メタ情報やラベルから判定する。
- **Dependabot 互換性スコア**: PR 本文に含まれていれば控える（**参考値に留め、これ単独で
  採否を決めない**）。
- **CI 状態**: `gh pr checks <番号>` で取得する。

### 3. リスク分析（必須・全 PR 対象）

bump 種別にかかわらず、すべての PR について upstream を遡って確認する。

1. **リリースノート / CHANGELOG**: `<from>`→`<to>` 間のリリースノート・CHANGELOG を読む。
2. **コード差分**: タグ間の compare（例: GitHub の `compare/<from>...<to>`）や
   `npm diff` 等で実際の差分を確認する。コメントや lockfile 以外の不審な変更がないか。
3. **メンテナ・所有権の変化**: 新規 publisher、リポジトリの移管・改名、新メンテナの追加、
   GitHub アカウントの異常など、配布主体の変化がないか。
4. **install / postinstall / prepare スクリプト**: 新規追加・変更された lifecycle
   スクリプトがないか（マルウェア混入の典型的な経路）。
5. **依存ツリーの変化**: 新たに追加される transitive 依存がないか。不審なパッケージ名や
   公開直後のパッケージが混じっていないか。
6. **既知の advisory**: GitHub Advisory / `gh api`、`npm audit` 等で既知の脆弱性・
   マルウェア報告がないか。セキュリティ更新ならその CVE / GHSA を確認する。
7. **公開からの経過時間**: `<to>` が公開直後（数日以内）なら、改ざん検知前の可能性を考え
   様子見を選択肢に入れる。

調査ツール: upstream リポジトリ・レジストリへの WebFetch、`gh api repos/<owner>/<repo>/...`、
パッケージレジストリ API。

各 PR にリスクレベル（**low / medium / high**）と根拠、推奨アクション
（**マージ推奨 / 保留 / 却下**）を付ける。

### 4. Design Doc 生成（`docs/design/` 採用 repo のみ）

トリアージ結果を Design Doc にまとめる。`docs/design/` を採用していない repo はこの
ステップをスキップし、結果を会話と各 PR への `gh pr comment` で返してステップ 5 へ進む。

1. ブランチ・worktree を作成する（命名例: `chore/dependabot-triage-<YYYY-MM-DD>`、
   worktree は `.claude/worktrees/<branch>`）。
2. `design-doc` skill の `TEMPLATE.md` をベースに `docs/design/dependabot-triage-<YYYY-MM-DD>.md`
   を作成する。`docs/design/TEMPLATE.md` がある repo はそちらに従う。
3. 内容:
   - **一覧表**: PR 番号 / 依存名 / bump 種別 / CI / リスクレベル / 推奨アクション。
   - **PR ごとのリスク分析詳細**: ステップ 3 の調査結果と根拠。
   - **現時点の方針**: PR ごとの推奨アクションと、その理由。
4. コミット（`/commit`）・push・`gh pr create` で Design Doc の PR を作成する。
   Issue があれば `Refs #N` で紐付ける。
5. ユーザーに Design Doc の PR URL を提示し、**採否のレビューを依頼する**。

### 5. ユーザーの判断を待つ

ユーザーが Design Doc をレビューし、どの更新を承認 / 保留 / 却下するか決定する。

> ここで Claude の作業は一旦完了。ユーザーの採否決定を待つ。

### 6. 反映作業

ユーザーから採否の指示を受けたら実行する。

- **承認した PR**:
  1. `gh pr checks <番号>` で CI 通過を確認する。
  2. ベースが古い・コンフリクトしている場合は PR に `@dependabot rebase` をコメントし、
     再 CI を待つ。
  3. `gh pr merge <番号>`（host repo のマージ戦略に従う。`--squash` 等）でマージする。
- **却下した PR**:
  1. `gh pr close <番号>` でクローズする。
  2. その版を今後オファーさせない場合は `@dependabot ignore this <major|minor|patch>
     version` 等をコメントする（再オファー抑止。判断は却下理由に応じて行う）。
- **保留した PR**: そのまま残し、保留理由を ADR に記録する。

### 7. ADR 記録

判断結果と根拠を ADR に記録する。`docs/adr/` を採用していない repo はスキップする。

1. ステップ 4 の Design Doc を ADR に**昇格**させる: Design Doc の内容を ADR に集約し、
   **同じ PR で `docs/design/` の元ファイルを削除する**（ステータスを更新してリンクだけ
   残す運用はしない）。`design-doc` skill の `ADR-TEMPLATE.md` を雛形に使う。
2. ADR には以下を記録する:
   - **決定**: どの依存を更新し、どれを却下・保留したか。
   - **理由**: 各依存についてのリスク分析の結論と、採否の根拠。
   - **却下した案 / 保留**: 却下・保留した更新と、その理由（後から経緯を辿れるように）。
3. ADR のファイル名は GitHub 番号ベース（`docs/adr/<番号>-<kebab-title>.md`、見出し
   `ADR-<番号>`、ゼロ埋めなし）。番号の優先順位は Issue 番号 → Design Doc PR 番号 →
   ローカル採番（既存最大 +1）。host repo が独自規約を持つ場合はそちらを優先する。
4. ADR は日本語で書く（`docs/adr/` の既存 ADR / `.claude/rules/` の言語ルールに合わせる）。
5. ステップ 4 で作成したブランチ上で ADR の追加・Design Doc の削除をコミットし、Design Doc
   の PR をそのまま ADR の PR として更新する（または新規 PR を作る）。`gh pr checks --watch`
   で CI を確認し、ユーザーにマージを依頼する。

> 1 回のトリアージ実行 = 1 つの ADR。継続的に Dependabot 更新を回すと ADR が増えるが、
> 各実行はサプライチェーン上の独立した判断であり、記録を 1 件 1 ファイルで残すことで
> 後から「いつ・なぜその版を入れた / 見送った」を辿れるようにする。
