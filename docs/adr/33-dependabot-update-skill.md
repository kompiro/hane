# ADR-33: Dependabot 更新 PR をリスク分析する `dependabot` skill を hane に追加する

- **日付**: 2026-05-18
- **ステータス**: 決定済み
- **Issue**: [#33](https://github.com/kompiro/hane/issues/33)
- **関連**: [ADR-10](10-tpl-integration-into-skills.md)（optional 慣習を「ディレクトリの存在」で gating する先例、produce / consume の分離）, `design-doc` skill（Design Doc → ADR 昇格のライフサイクル）, `.claude/rules/adr-language.md`

## 背景

Dependabot は依存更新 PR を継続的に開くが、その採否を効率よく・かつ安全に捌くワークフローが
hane には無かった。一般的な運用では「patch / minor は CI が通れば自動マージ」とすることが多い。
しかし近年、サプライチェーン攻撃 — メンテナアカウントの乗っ取り、悪意ある `postinstall`
スクリプトの混入、リポジトリ移管後の改ざん、typosquatting な transitive 依存の追加 — が
増えており、semver の bump 種別や Dependabot の互換性スコアだけでは更新の安全性を判断できない。
`patch` リリースであっても公開物に悪意あるコードが含まれうる。

そこで「bump 種別を問わず全 PR を upstream まで遡ってリスク分析し、人間が採否を決める」
ワークフローを skill として hane に持たせたい。ただし hane の既存スタンス（skill ファイルと
manifest しか持たない / テスト・ビルドツールを導入しない / optional 慣習はディレクトリの
存在で gating する）は維持する。

論点は 4 つ: 採否の自動化をどこまで許すか / トリアージ結果と最終判断をどう記録するか /
1 回の実行で何件の PR を扱うか / hane の他 skill との一貫性をどう保つか。

## 決定

Dependabot の依存更新 PR を一括トリアージする optional な `dependabot` skill を新設する。

- **リスク分析を全 PR で必須にする**: bump 種別（patch / minor / major）や互換性スコアで
  分岐せず、すべての PR について upstream のリリースノート・コード差分・メンテナ / 所有権の
  変化・install スクリプトの追加・依存ツリーの変化・既知 advisory・公開からの経過時間を
  確認する。「patch だから自動マージ」という近道は設けない。
- **自動マージしない / human-in-the-loop**: skill はトリアージ結果と推奨（マージ推奨 / 保留 /
  却下）を提示するに留め、採否の決定は必ずユーザーが行う。hane の他 skill と同じ「Claude が
  準備し、人がマージする」流儀に揃える。
- **Design Doc で提案し、ADR で結果を記録する**: トリアージ結果は `docs/design/` に Design Doc
  として出力し、ユーザーがそれをレビューして採否を決める。決定後、承認分のマージ・却下分の
  クローズを行い、判断結果と根拠を ADR に記録する。Design Doc → ADR の昇格（内容を ADR に
  集約し同じ PR で元ファイルを削除）は hane の既存ライフサイクルをそのまま再利用する。
  1 回のトリアージ実行 = 1 つの ADR とし、「いつ・なぜその版を入れた / 見送った」を 1 件
  1 ファイルで辿れるようにする。
- **バッチ処理**: 1 回の実行で開いている Dependabot PR を全件列挙し、リスク順に並べて
  一括でトリアージする。依存更新は相互に関連しうるため、PR を 1 件ずつ見るより全体像を
  一度に俯瞰できる方が判断しやすい。
- **optional 慣習として gating する**: Design Doc 出力は `docs/design/`、ADR 記録は
  `docs/adr/` の存在で gating する。host の `CLAUDE.md` に新しいマーカーは導入しない —
  `design-doc` / `start-dev` がディレクトリやラベルの存在で gating しているのと同じ流儀。
  両ディレクトリが無い repo では結果を会話と PR コメントで返す。
- **hane 自身は tooling を持ち込まない**: 自動マージ用の GitHub Actions や validator は
  追加しない。skill は `gh` / WebFetch / `@dependabot` コメントだけで完結し、hane の
  skills-only スタンスを保つ。

## 理由

- サプライチェーン攻撃下では semver の互換性は「安全性」を意味しない。bump 種別による
  自動マージは攻撃者が最も悪用しやすい経路（patch を装った改ざん版）をそのまま素通り
  させてしまう。全 PR でのリスク分析必須化は、この最も弱い箇所を塞ぐための核心。
- Design Doc を中間成果物にすることで、ユーザーは「マージ推奨」という結論だけでなく
  リスク分析の根拠まで見たうえで採否を決められる。レビュー可能な人工物が残る。
- 結果を ADR に残すことで、依存を入れた / 見送った判断が後から監査できる。インシデント
  発生時に「どの版をいつ・どの根拠で受け入れたか」を遡れることはサプライチェーン
  セキュリティ上の実利がある。
- gating を他 skill と同型にすることで、hane 全体が「ディレクトリ / ラベルが存在するか」
  という単一のメンタルモデルで一貫する。skill ごとの特例を増やさない。
- バッチ処理は、グループ更新 PR や相互依存する更新をまとめて評価でき、トリアージの
  往復回数も減らせる。

## 却下した案

- **patch / minor を CI 通過で自動マージし、major のみ手動判断する** — 却下。これが本 ADR が
  最も明確に退ける案。サプライチェーン攻撃は patch / minor の見た目で配布されるため、bump
  種別による信頼の付与は攻撃面をそのまま残す。CI の通過も悪意あるコードの不在を保証しない。
- **トリアージ結果を Design Doc / ADR に残さず、会話の中で推奨を提示するだけにする** — 却下。
  レビュー可能な人工物も監査可能な記録も残らず、依存採否の経緯を後から辿れない。
- **自動マージ用の GitHub Actions / `@dependabot` 設定を hane に同梱する** — 却下。hane は
  skill ファイルと manifest しか持たず、tooling は host repo のワークフローに結びつく
  （ADR-10 で TPL tooling を移植しなかったのと同じ理由）。
- **PR を 1 件ずつ処理する** — 却下。グループ更新や相互依存する更新を個別に見ると全体像を
  見失う。Issue #33 でもバッチ処理を選択した。
- **host の `CLAUDE.md` に専用マーカーを足して gating する** — 却下。hane の他の gate は
  どれもディレクトリ / ラベルの存在で判定しており、綴り・配置の取り決めを増やす利点が無い。
