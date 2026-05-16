---
name: design-doc
description: >
  Create design documents in docs/design/ for brainstorming and exploring architectural ideas.
  Trigger when the user says: "設計ドキュメント", "デザインドキュメント", "設計を残す", "壁打ち",
  "design doc", "create design doc", or similar phrases requesting design documentation.
---

# Design Document Skill

設計の壁打ちや検討過程を `docs/design/` にドキュメントとして残す。
ADR（決定記録）の前段階として、アイデアの探索・比較・整理を行うためのドキュメント。

## ADR との違い

| | Design Doc | ADR |
|---|---|---|
| 目的 | 設計の探索・壁打ち・検討過程の記録 | 最終的な設計判断の記録 |
| ステータス | ドラフト → 検討中 → ADR化（昇格時に元ファイルは削除） | 提案 → 決定済み/却下 |
| 内容 | 問題の深掘り・選択肢の比較・トレードオフ分析 | 決定事項・理由・却下した案 |
| 配置先 | `docs/design/` 直下 | `docs/adr/`（日本語で書く） |

## 手順

1. ユーザーと対話しながら設計の論点を明確にする
   - 何を解決したいのか（問題・課題）
   - どういう制約があるか
   - どんな選択肢を考えているか
2. `docs/design/` および `docs/adr/` 内の既存ドキュメントを確認し、重複や関連するものがないか確認する
   - 過去に同様のテーマが検討・決定されていないかを `docs/adr/` まで遡って探査すること
3. テスト観点ライブラリ（TPL）を確認する（ホスト repo が `docs/test-perspectives/` を採用している場合のみ。ディレクトリが無ければ本ステップをスキップする）。2 段階で観点を取り込む:
   1. **既存 TPL の一覧**: ホスト repo が `tpl:related <topic>` 等のスクリプトを提供していればそれを使い、無ければ `docs/test-perspectives/` 配下の TPL ファイルの frontmatter（`topic` / `scope.packages` / `applicable_to`）を grep して、今回の設計テーマにマッチする TPL を拾う。見つかったものはドキュメントの `## Related TPLs` 節に列挙する（`docs/test-perspectives/` へのリンク付き）
   2. **未 TPL 化の原則のスキャン**: 同じ topic の `docs/concepts*` 等の原則ファイルと関連 ADR を読み、まだ TPL になっていない原則で今回の設計が違反しうるものがないか確認する。あれば 3-Yes ルール（横展開しうる / 構造的に再発しうる / 既存 TPL 未掲載）に照らし、満たすなら **同じ PR で** proactive TPL を起こす（`test-perspective` スキルを呼び、`discovered_from.root_cause_file` または `root_cause_adr` を設定する）。同じ PR で起こすのが最も摩擦が少ない。起こした proactive TPL は `## Related TPLs` 節にも記載し、相互リンクする
4. 壁打ちの内容を整理してドキュメント化する
   - host repo の `docs/design/` に `TEMPLATE.md` が無ければ、この skill の
     [`TEMPLATE.md`](TEMPLATE.md) を `docs/design/TEMPLATE.md` としてコピーする
     ことをユーザーに提案し、同じ PR に含める。すでに `docs/design/TEMPLATE.md`
     がある repo はそちらの雛形に従う
5. ブランチ・worktree を作成してからファイルを作成する
   - ブランチ名の例: `docs/design-<kebab-case-title>`
   - `git worktree add .claude/worktrees/<branch> <branch>`
   - worktree 内でファイルを作成し、コミット・push・PR 作成まで行う
6. 「未解決の問い」セクションに項目がある場合は、ユーザーにレビューを依頼する前に一緒に解消する
   - 未解決の問いを1つずつユーザーに提示し、意見や考えを引き出す
   - 回答が得られた問いはドキュメントの該当箇所（「現時点の方針」など）に反映してコミットする
   - 全ての問いが解消されたら「未解決の問い」セクションを削除（または空にする）してコミットする
   - 解消できない問いが残る場合はその旨をドキュメントに明記した上で次のステップへ進む
7. ユーザーにレビューを依頼する
8. PR がマージされたら、紐付いている Issue がある場合はラベルを更新する（`status: *` ラベル運用を採用している repo のみ）:
   ```
   gh issue edit <N> --remove-label "status: designing" --add-label "status: designed"
   ```
   > `status: designed` は「設計完了・実装着手可能」を意味する。
   > 実装を開始する際（`/start-dev` など）に `status: implementing` に更新すること。
   > ラベル運用がない repo では本ステップをスキップする。
9. 設計が固まった場合は、ADR化を提案する（`docs/adr/` を採用する repo のみ）。ADR化するときは、Design Doc の内容を ADR に集約したうえで **同じ PR で `docs/design/` の元ファイルを削除する**（ステータスを「決定済み」に更新してリンクだけ残す運用はしない）。ADR は日本語で書く（host repo の `.claude/rules/` 等にルールがあればそれに従う）。実装を伴う場合の昇格は通常 `/start-dev` のクリーンアップ手順で行う

## ファイル形式

Design Doc の雛形はこの skill ディレクトリの [`TEMPLATE.md`](TEMPLATE.md) を使う。
`TEMPLATE.md` をコピーして冒頭の HTML コメントを削除し、各節を埋める。

節構成は 背景・課題 / 制約・前提 / 検討した選択肢 / 比較 / Related TPLs（任意）/
現時点の方針 / 未解決の問い（任意）。`## Related TPLs` 節は host repo が
`docs/test-perspectives/` を採用している場合のみ残す。

## 壁打ちの進め方ガイドライン

- **探索的に**: 最初から結論を出そうとせず、まず選択肢を広げる
- **トレードオフ重視**: 各案のメリット・デメリットを明示する
- **具体例で検証**: 抽象的な議論に留まらず、具体的なコード例やユースケースで検証する
- **制約を明確に**: 「なぜその案がダメか」の理由となる制約を明示する
- **段階的に深掘り**: 一度に全てを決めず、大きな方針から詳細へと進める
- **TPL を取り込む**（`docs/test-perspectives/` 採用 repo のみ）: 既存 TPL を引用したら ID を `## Related TPLs` 節に書く。原則違反を予見して proactive TPL を起こした場合は、その TPL と本 DesignDoc を相互リンクする

## 命名規則

- ファイル名: `docs/design/kebab-case-title.md`
- ADR / AT と異なり**ファイル名に番号は付けない**（1 issue ≠ 1 design doc になりがちで、探索フェーズではトピック名識別の方が運用しやすい）
- 紐付く GitHub Issue / PR があれば、ファイル冒頭の `**Issue**: #<番号>` / `**PR**: #<番号>` メタ欄で対応関係を示す
- タイトルは検討テーマを端的に表す
