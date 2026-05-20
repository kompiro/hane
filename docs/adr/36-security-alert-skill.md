# ADR-36: Dependabot security alert をトリアージする `security-alert` skill を hane に追加する

- **日付**: 2026-05-20
- **ステータス**: 決定済み
- **Issue**: [#36](https://github.com/kompiro/hane/issues/36)
- **関連**: [ADR-33](33-dependabot-update-skill.md)（`dependabot` skill — 更新 PR のトリアージ）, [ADR-10](10-tpl-integration-into-skills.md)（optional 慣習をディレクトリの存在で gating する先例）

## 背景

hane には `dependabot` skill があるが、これは Dependabot が開いた **依存更新 PR**（weekly の
version bump バッチ）を捌くものである。Dependabot の **security alert**（GHSA / CVE 起因の
脆弱性アラート）は、これと別物として扱う必要がある。

- security alert は `gh api repos/{owner}/{repo}/dependabot/alerts` から取得する。open PR
  一覧には現れない。
- **alert に対応する PR が存在しないことがある**。脆弱なパッケージが transitive 依存の場合、
  bump すべき直接の宣言行が `package.json` に無いため、Dependabot は security update PR を
  合成できず、alert だけが open のまま残る。
- transitive 依存の解決には、bot PR のマージではなく package manager の override 機構
  （pnpm `overrides` / npm `overrides` / yarn `resolutions`）を使うことが多い。

この欠落は `kompiro/karasu` で具体的に表面化した。transitive な medium severity の alert が
2 件（`ws` / `brace-expansion`）出ていたが Dependabot PR は無く、トラッキング Issue 作成 →
`pnpm.overrides` 追加 → lockfile 検証 → ADR 記録、という手順を手動で実施した（karasu #1474 /
#1475 / ADR-20260520-05）。この手順は再現性のあるワークフローであり、skill 化する価値がある。

論点は 2 つ: `dependabot` skill を拡張するか別 skill にするか / transitive 依存の override を
どう安全に当てるか。

## 決定

Dependabot security alert を一括トリアージする optional な `security-alert` skill を新設する。

- **`dependabot` skill とは別 skill にする**。収集元（alerts API vs open PR 一覧）も、解決手段
  （override / direct bump vs bot PR のマージ）も、PR が存在しないケースの扱いも異なる。
  両者をひとつの skill に混ぜると分岐が複雑になり、トリガー語彙も曖昧になる。
- **relationship でルーティングする**。`dependency.relationship` が `direct` なら宣言バージョン
  を bump（または対応する Dependabot security PR を `dependabot` skill に委譲）、`transitive`
  なら package manager の override 機構で修正版に pin する。
- **override キーは脆弱メジャーにスコープする**。同じパッケージの複数メジャーが依存ツリーに
  共存する場合、無印キーで全メジャーを巻き上げると、脆弱性と無関係なメジャーまで breaking な
  境界をまたいで強制昇格する。advisory の脆弱バージョン範囲が含むメジャーだけにキーを
  スコープする（例 `"foo@5": "^5.0.6"`）。
- **human-in-the-loop**。skill は修正と PR を準備するに留め、マージはユーザーが行う。hane の
  他 skill と同じ流儀に揃える。自動マージ用の tooling は hane に持ち込まない。
- **トラッキング Issue + 修正 PR + ADR の三点で記録する**。1 回のバッチ = 1 Issue = 1 ADR。
  脆弱性をいつ・どの根拠で・どう解決したかを 1 件 1 ファイルで辿れるようにする。
- **optional 慣習として gating する**。ADR 記録は `docs/adr/` の存在で gating する。host の
  `CLAUDE.md` に新しいマーカーは導入しない — 他 skill と同じ流儀。

## 理由

- transitive 依存の security alert は、`dependabot` skill のメンタルモデル（open PR を列挙して
  捌く）では拾えない。PR が無い alert を取りこぼさないためには、alerts API を起点にした
  別ワークフローが要る。
- relationship によるルーティングは、修正手段が relationship で一意に決まるため、skill の
  判断を素直で曖昧さの無いものにできる。
- override キーのスコープ化は karasu での実体験に基づく。`brace-expansion` を無印キーで pin
  したところ、advisory 対象外の 1.x / 2.x consumer まで major rewrite の 5.x へ強制昇格した。
  脆弱バージョン範囲にキーを合わせることで、修正範囲を脆弱性の実体と一致させられる。
- 脆弱性対応の経緯を ADR に残すことは、インシデント発生時に「どの版をいつ・どの根拠で
  受け入れた / 緩和したか」を遡れるという点で、サプライチェーンセキュリティ上の実利がある。
  `dependabot` skill（ADR-33）と同じ記録方針を踏襲する。
- gating を他 skill と同型にすることで、hane 全体が「ディレクトリが存在するか」という
  単一のメンタルモデルで一貫する。

## 却下した案

- **`dependabot` skill を拡張して security alert も扱わせる** — 却下。収集元・解決手段・PR の
  有無がすべて異なり、ひとつの手順書に同居させると分岐が増えてどちらの経路も読みにくくなる。
  トリガー語彙も「更新 PR」と「脆弱性アラート」で利用者の意図が異なる。
- **transitive 依存を無印キーの override で一律に pin する** — 却下。脆弱性と無関係な
  メジャーまで breaking な境界をまたいで巻き上げる。karasu で実際に踏んだ失敗であり、
  キーを脆弱メジャーにスコープするほうが安全かつ修正範囲が最小になる。
- **alert を都度 `dismiss` して対応を見送る運用にする** — 却下。修正版が存在する脆弱性を
  放置することになり、Dependabot alert を有効化している意図に反する。`dismiss` は修正版が
  無い場合の緩和策の選択肢に留める。
- **自動マージ用の GitHub Actions / 設定を hane に同梱する** — 却下。hane は skill ファイルと
  manifest しか持たない（ADR-10 / ADR-33 と同じ理由）。tooling は host repo に委ねる。
