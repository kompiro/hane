<!--
ADR（Architecture Decision Record）の雛形。

design-doc skill（design doc → ADR 昇格）および start-dev skill
（クリーンアップ時の ADR 昇格）が、確定した設計判断を記録するときに使う。

使い方:
1. このファイルを `docs/adr/<番号>-<kebab-case-title>.md` にコピーする。
2. コピー先で本 HTML コメントブロック（先頭）を削除し、各節を埋める。
3. design doc からの昇格時は、design doc の内容をこの ADR に集約し、
   元の `docs/design/` ファイルは同じ PR で削除する。

規約メモ:
- ファイル名: `docs/adr/<番号>-<kebab-case-title>.md`。番号は GitHub
  番号ベース（Issue → PR → ローカル採番、ゼロ埋めなし）。見出し `ADR-<番号>`。
  host repo が独自規約（例: `YYYYMMDD-NN-<slug>.md`）を持つ場合はそちらを優先する。
- 言語: ADR は host repo の既存 ADR の言語に合わせる（既存が無ければ
  design doc / skill body と揃える）。識別子・固有名詞は英語綴りのまま。
- 本 雛形は frontmatter を持たない素の Markdown 形式。host repo が ADR の
  frontmatter スキーマ（`topic` の controlled vocabulary、関係性メタデータ、
  バリデータ等）を運用している場合は、その host 規約を優先する。
- 既存 ADR を覆すときは旧 ADR を書き換えず、新 ADR で扱う。旧 ADR の
  ステータスを更新し、両者を「関連」で相互リンクする。
-->

# ADR-<番号>: 短く人間が読めるタイトル

- **日付**: YYYY-MM-DD
- **ステータス**: 決定済み
- **Issue**: #<番号> または なし
- **関連**: 関連する Issue / PR / ADR / design doc / ソースファイル

## 背景

なぜこの判断に至ったか。どんな問題・選択肢を検討していたか。

## 決定

何を決めたかを一文で述べる。

## 理由

- 採用根拠を箇条書きで。
- 各案のトレードオフのうち、この決定を支える点。

## 却下した案

検討して却下した代替案と、その却下理由（後から経緯を辿るのに有用な場合のみ記述）。
