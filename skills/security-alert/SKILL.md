---
name: security-alert
description: >
  Dependabot の security alert（GHSA / CVE 起因の脆弱性アラート）をトリアージして
  解決するワークフロー。未解決の alert を一括取得し、direct / transitive を判別して
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
  合成できず、alert だけが残る。
- **alert の `state` は安全性の証明ではない**。GitHub の auto-triage は通知量を減らすために
  alert を `auto_dismissed` にするが、脆弱版は lock に残ったままである（ステップ 1）。
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

未解決の Dependabot security alert を一括で取得する（**バッチ処理 — 全件を対象にする**）。

**`state == "open"` だけを取ってはいけない。** GitHub の auto-triage は低影響と判断した alert を
`auto_dismissed` にする（既定規則は development スコープの依存が対象）。これは**通知量の判断で
あって、パッケージが安全になったことの証明ではない**。脆弱版は lock に残り続ける。

```
gh api repos/{owner}/{repo}/dependabot/alerts --paginate \
  --jq '.[] | select(.state=="open" or .state=="auto_dismissed") | {
    number,
    state,
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

`fixed` と（人手の）`dismissed` は除く。前者は解決済み、後者は人間が明示的に下した判断で、
本 workflow が蒸し返す対象ではない。`auto_dismissed` はそのどちらでもない。

**終了条件は alert の件数ではなく lock の解決版で決める。** 「対応すべき alert はありません」と
言ってよいのは、**収集した全 alert について解決版が脆弱範囲の外にある**ことを確認したときだけ
（ステップ 2 の突き合わせ）。収集結果が 0 件だった場合もここに含まれる。`auto_dismissed` で
解決版が既に patched 版なら真の no-op なのでそう報告してよいが、それは state ではなく版を見て
言えることである。

- 同一 advisory が複数 manifest で alert 化されることがある（pnpm workspace では宣言と
  解決済みバージョンが別 manifest として計上される）。後段でまとめて扱う。

### 2. 各 alert のリスク分析

alert ごとに以下を整理する。

- **severity**: critical / high / medium / low。
- **advisory**: GHSA / CVE と summary。詳細は `gh api` の `security_advisory.description` や
  GitHub Advisory ページ（WebFetch）で確認する。
- **relationship**: `direct` / `transitive`。解決手段の分岐に直結する（ステップ 3）。
- **scope**: `runtime` / `development`。runtime のほうが優先度が高い。**優先度づけにだけ使い、
  やる / やらないの判定には使わない**。`scope` は依存グラフが動くと再計算される。
  karasu の alert #68 は同じ日の午前に `open` / `runtime`、午後に `auto_dismissed` /
  `development` になった（無関係な依存更新 PR がグラフを変えたため）。脆弱版は動いていない。
- **vulnerable range / first patched version**: 修正版が存在するか。存在しない場合は
  緩和策（該当機能の不使用・代替パッケージ・`dismiss` 理由）を検討対象にする。
- **対応する PR の有無**: `gh pr list --author "app/dependabot" --state open` に当該 alert を
  解消する security update PR があるか。
- **自分の宣言レンジとの突き合わせ**: 下記。

各 alert に対応の緊急度（severity と scope から）と推奨修正方法（ステップ 3）を付ける。

#### advisory の脆弱範囲を自分の pin と突き合わせる

**alert 1 件につき、advisory の `vulnerable_version_range` と、host repo の override 機構
および各 manifest の宣言レンジを必ず突き合わせる。** lock file の解決バージョンだけを見て
「pin されている = 対処済み」と判断しない。

```
# 1. advisory の脆弱範囲
gh api repos/{owner}/{repo}/dependabot/alerts/<n> \
  --jq '.security_vulnerability | {range: .vulnerable_version_range, patched: .first_patched_version.identifier}'

# 2. 宣言側を全部出す（override + 全 manifest の直接依存）
#    override の置き場は package manager 依存（ステップ 3 の一覧を参照）。
#    置き場を取り違えると「見当たらない = pin 無し」と誤判定するので、
#    lock file と同階層の設定ファイルまで含めて探す。
grep -rn '<pkg>' package.json pnpm-workspace.yaml packages/*/package.json 2>/dev/null
```

**1 の範囲が 2 のいずれかのレンジと交差していたら、そのレンジも修正版へ引き上げる**
（ステップ 3 の「既に override 済みだった場合」へ）。

なぜ必須か: 過去の security alert 対応で override の floor を「**その時点の** patched 版」に
固定すると、その版が後日別の advisory の脆弱範囲に含まれたとき、**override が脆弱版への
固定装置として働く**。lock を見るだけでは「pin 済み」に見えるため、この形は静かに残る。
override は「今の解決を矯正する道具」であって「もう安全であることの証明」ではない。

実例（いずれも override が既にあったが floor が脆弱範囲の内側）:

| package | 当時の override | advisory の脆弱範囲 | 気づくまで |
| --- | --- | --- | --- |
| `js-yaml` | `"js-yaml@4": "^4.3.0"` | `>= 4.0.0, < 4.3.1` | 即日（alert が open） |
| `dompurify` | `"dompurify": "^3.4.12"` | `<= 3.4.12` | 即日（alert が open） |
| `brace-expansion` | `brace-expansion@5: ^5.0.8` | `>= 4.0.0, < 5.0.9` | **2 週間**（alert が `auto_dismissed`） |

3 例目が 2 週間残ったのは、この突き合わせが**走らなかった**からである。alert が
`auto_dismissed` だったため `state == "open"` の収集に現れず、以降のステップに入らなかった。
ステップ 1 が `auto_dismissed` を含めるのはこのためで、**この節の検査は収集に依存している**。

### 3. 解決方針の決定（direct / transitive のルーティング）

`relationship` と PR の有無で修正方法を振り分ける。

| ケース | 修正方法 |
|---|---|
| direct 依存 + Dependabot security PR あり | その PR を `dependabot` skill でトリアージ・マージする（本 skill の対象外として委譲） |
| direct 依存 + PR なし | 該当 `package.json` の宣言バージョンを修正版以上に bump する |
| transitive 依存 | package manager の override 機構で修正版に pin する（下記） |
| すでに override があり、その floor が脆弱範囲の内側 | floor を修正版へ引き上げる。**同じパッケージの直接依存の宣言も同時に引き上げる**（下記） |

**transitive 依存の override**: package manager を `packageManager` フィールド / lock file
から判定し、対応する機構を使う。

- pnpm 11 以降 — `pnpm-workspace.yaml` の `overrides:`
- pnpm 10 以前 — root `package.json` の `pnpm.overrides`
- npm — root `package.json` の `overrides`
- yarn — root `package.json` の `resolutions`

**pnpm のバージョンを先に確かめる。** pnpm 11 は `package.json` の `pnpm` フィールドを
一切読まない（pnpm/pnpm#10086）。pnpm 11 の repo で旧位置に override を書くと**エラーに
ならず黙って無視され、脆弱性が修正されないまま PR が green になる**。`packageManager`
フィールドで判定し、既存 override がどちらにあるかを実際に見てから書き足す。

**override キーのスコープ**: 同じパッケージの複数メジャーが依存ツリーに共存する場合、
無印キー（例 `"foo": "^5.0.6"`）で全メジャーを巻き上げると、脆弱性と無関係なメジャーまで
breaking な境界をまたいで強制昇格してしまう。**advisory の脆弱バージョン範囲が含むメジャー
だけにキーをスコープする**（例 pnpm/npm `"foo@5": "^5.0.6"`、yarn `"foo@^5.0.0": "^5.0.6"`）。
脆弱なメジャーが 1 系統しか無ければ無印キーでよい。

**既に override 済みだった場合**: 新しい override を足すのではなく既存キーの floor を
引き上げる。このとき、**同じパッケージが直接依存としても宣言されていれば、その宣言レンジも
同時に修正版へ引き上げる**。override が効いている限り実解決は同じだが、宣言を据え置くと
**override を外した瞬間に脆弱範囲へ戻る宣言が残る**。override は宣言の正しさの代わりでは
ない。

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
   - 既存 override の floor 引き上げ — 既存キーの値を修正版へ書き換える。同じパッケージの
     直接依存の宣言があれば、**同じコミットで**そちらも引き上げる。
3. lock file を更新する（`pnpm install` / `npm install` / `yarn install`）。

### 6. 検証

1. **lock file の解決バージョン**: 対象パッケージが修正版に解決され、**脆弱版のエントリが
   lock から 1 件も残っていない**ことを確認する（`grep -c "<pkg>@<脆弱版>" <lock file>` が 0）。
   宣言を複数箇所直した場合、1 箇所でも取りこぼすと古い解決が残る。
2. **巻き込みの確認**: override をスコープした場合、無関係なメジャーが据え置かれている
   ことを確認する。付随した無関係な minor / patch の更新があれば、それが脆弱性と無関係で
   あることを確認する。**確認は解決バージョンの集合ではなく、lock の依存エッジで行う**（下記）。
3. **ビルドされない領域の確認**: lock が動いたパッケージの利用先が、host の `build` /
   `test` に含まれていない場合がある（docs サイト・別 workspace など）。含まれていなければ
   その領域のビルドを手で回す。CI が触らない領域の退行は merge 後に出る。
4. **ビルド・テスト**: host の `package.json` `scripts` から `build` / `test` を検出して
   実行し、通過することを確認する。該当 script が無ければスキップする。
5. 公開パッケージを持つ repo では、公開物（バンドル・third-party notice 等）への影響有無を
   確認し、必要なら changeset 等のリリースメタを添える。

#### 巻き込みは lock の依存エッジで見る（集合比較では見えない）

lock から `name@version` を抜いて**集合として** before / after を比べる方法は、
**消費側が「グラフに既にある別バージョン」へ乗り換えた場合を検出できない**。乗り換え先が
他の依存元経由で既に存在していれば、集合は変わらないか、むしろ縮む。それでも実際の解決は
動いており、その版がビルド出力に出るパッケージなら影響が出る。

見るべきは package キーの集合ではなく、**snapshot 内の依存エッジ**（どの snapshot が、どの
依存の、どの版を指しているか）。lock の生 diff を直接読むのは向かない — グラフが変わると
peer suffix が一斉に書き換わり（`foo: 2.0.3` → `foo: 2.0.3(supports-color@9.4.0)`）、版が
動いていない行が数百件出て信号が埋もれる。peer suffix を落としてから比べる:

```sh
edges() { # "<owner> <dep> <version>" を出す。peer suffix は落とす
  tr -d "'" | awk '
    /^  [^ ]/             { owner = $0; sub(/:$/, "", owner); gsub(/\(.*/, "", owner); sub(/^  /, "", owner) }
    /^      [^ ]+: [0-9]/ { dep = $1; sub(/:$/, "", dep); ver = $2; gsub(/\(.*/, "", ver); print owner, dep, ver }
  ' | sort -u
}
git show <base>:pnpm-lock.yaml | edges > /tmp/before.txt
edges < pnpm-lock.yaml > /tmp/after.txt
diff /tmp/before.txt /tmp/after.txt
```

残った差分が実際に動いた解決である。意図した bump 以外が出たら、その利用先がビルド出力に
出るかを確認する（上のステップ 3）。npm / yarn では lock の構造に合わせて owner / dep の
拾い方を読み替える。

**「意図した 1 パッケージ以外は動いていない」と書くときは、この方法で確かめた結果を根拠に
する。** 集合比較しかしていない状態でそう書くと、確かめていないことを確かめたと書くことになる。

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
