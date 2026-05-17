<!--
test-perspective skill が生成する TPL（Test Perspective Library）記録の雛形。

使い方:
1. このファイルを `docs/test-perspectives/TPL-<番号>-<slug>.md` にコピーする。
2. コピー先で本 HTML コメントブロック（先頭）を削除し、frontmatter と各節を埋める。
3. proactive / retrospective の起源に応じて `discovered_from` の該当行だけ残す。

規約メモ:
- ファイル名: `docs/test-perspectives/TPL-<番号>-<slug>.md`。番号は GitHub
  番号ベース（Issue → PR → ローカル採番、ゼロ埋めなし）。見出し `TPL-<番号>`。
  採番後はリネームしない。host repo が独自規約（例: `TPL-YYYYMMDD-NN-<slug>.md`）
  を持つ場合はそちらを優先する。
- 言語: 日本語本文 + 英語の識別子・固有名詞。
- `topic` は host repo が ADR の controlled vocabulary を持てばそれを共有し、
  無ければ free-form の小文字 kebab トピックでよい。
- `scope.packages` には実在するパッケージ / ソースルートのみ書く。
- `tpl:validate` / `tpl:related` 等の検証ツールは host repo 側の運用。
  提供されていれば作成後に実行する。詳細は SKILL.md「ホスト repo に依存する慣習」。
-->

---
id: TPL-<番号>          # ファイル名の番号と一致
title: "観点を1行で表現"
status: active            # active | deprecated
date: YYYY-MM-DD          # 作成日
applicable_to:
  - "再利用可能な抽象パターン（例: 設定値を消費する機能）。1 行 = 1 パターン。複数パターンに当てはまるなら複数行"
known_consumers:          # optional — この観点が適用されると判明している具体的 consumer。grep 可能な kebab-case
  - feature-name
discovered_from:
  - issue: "#N"                              # retrospective の場合（この番号がファイル名の番号になる）
  # - root_cause_adr: "ADR-<番号>"            # proactive（ADR 起源）の場合
  # - root_cause_file: "docs/concepts.*"     # proactive（原則ファイル起源）の場合
  # - root_cause_file: "path/to/file.ts:LINE"
related_to:
  - TPL-<番号>            # optional — 同ディレクトリの実在 TPL のみ
topic: <controlled-vocabulary>   # ホスト repo の ADR 語彙があればそれ、無ければ free-form kebab
scope:
  packages:
    - <existing-package-or-source-root>
---

# TPL-<番号>: 観点を1行で表現

## 観点

何を検証すべきかを、再利用可能な抽象度で記述する。具体実装に閉じた書き方ではなく、別の機能でも適用できる原則として書く。

## 想定される失敗モード

この観点が見落とされた場合に、どのような形で失敗が現れるか。具体例があればそれも記述する。

## チェックリスト

新機能の実装/修正時に確認する項目。**3〜5 項目に絞る**（多すぎると使われない）:

- [ ] チェック項目1
- [ ] チェック項目2
- [ ] チェック項目3

## 既知の対処パターン

過去にこの問題を解決した方法。なければ「（未確立）」と記す。

## 関連テスト

この観点を検証する既存テストのパス。なければ「（なし）」と記す。
