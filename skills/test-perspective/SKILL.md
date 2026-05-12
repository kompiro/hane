---
name: test-perspective
description: >
  Create, update, or deprecate Test Perspective Library (TPL) records in docs/test-perspectives/.
  Trigger when the user says: "テスト観点", "観点ライブラリ", "TPL", "観点を追加", "TPLを起こす",
  "TPLをdeprecate", "test perspective", "add TPL", "deprecate TPL", or similar phrases requesting
  test-perspective record maintenance.
---

# Test Perspective (TPL) Skill

再発しうる失敗パターンを、構造化された「観点」として `docs/test-perspectives/` に蓄積・更新・deprecate する。
1 観点 = 1 ファイル。DesignDoc 作成時・新機能実装時・bug 修正時に該当 `topic` / `scope.packages` の観点が参照される状態を作るのが目的。

## 前提条件

このスキルはホスト repo が **`docs/test-perspectives/`（TPL）を採用している場合のみ** 意味を持つ。

- ディレクトリが存在しない場合は、まず「`docs/test-perspectives/` を新設して運用を始めるか」をユーザーに確認する。始める場合は最初の 1 件をこのスキルで作成し、必要なら `docs/test-perspectives/README.md`（運用方針の入り口）と `TEMPLATE.md` も用意する
- ディレクトリはあるが空 / `README.md` も `TEMPLATE.md` も無い、という状態でも動作する（既存ファイルが無ければスキャンは no-op）

## ホスト repo に依存する慣習

- **`topic` の controlled vocabulary**: ホスト repo が ADR の語彙を持つ場合（例: `docs/adr/README.md` のセクション見出し、`adr.config.json` の `topics` 等）はそれを使い、TPL と ADR で語彙を共有する。持たない場合は free-form の小文字 kebab トピックでよい
- **ファイル名規約**: 既定は `docs/test-perspectives/TPL-YYYYMMDD-NN-<slug>.md`（ゼロ埋めなし）。ホスト repo が独自の規約を持つ場合はそちらを優先する（ADR/AT の命名と同じ「host 独自規約優先」のエスケープ）
- **検証ツール**: ホスト repo が `tpl:validate`（frontmatter と一覧表の machine check）等を提供していれば、作成・更新後にそれを実行する。無ければ手動で frontmatter を確認する
- **関連 TPL クエリ**: ホスト repo が `tpl:related <topic>` 等を提供していればそれで関連 TPL を一覧する。無ければ `docs/test-perspectives/` 配下の frontmatter（`topic` / `scope.packages` / `applicable_to` / `known_consumers`）を grep する
- **定期 deprecation レビュー**: cadence（週次 / 月次 / 半期）と自動化（CI で review Issue を自動生成する等）はホスト repo に委ねる。このスキルは「`active` な TPL を放置しないため定期レビューを推奨」とだけ示す

## 手順

### 1. モードの判定

スキル起動時の引数・会話の文脈から、以下のどれかを判定する:

- **新規作成** — bug / test-infra Issue から、または原則（concepts / ADR）から、新しい観点を起こす
- **既存更新** — 新しい Issue が既存 TPL のパターンに該当する／チェックリスト・対処パターン・関連テストの refresh が必要
- **deprecate** — 構造変更などで、ある観点が原理的に発生しなくなった

### 2. 新規作成

#### 2-1. 起源を判定する

TPL は 2 つの起源から生まれる。frontmatter の `discovered_from` で区別できるようにする:

- **Retrospective（事後）** — `bug` または `test-infra` ラベルの Issue から、実際に起きた失敗を一般化する。`discovered_from.issue: "#N"` を持つ。`test-infra` は E2E flake / fixture / harness の問題で、典型的には testing 系トピックの観点を生む
- **Proactive（事前）** — アーキテクチャ原則 / 非目標 / north-star（`docs/concepts*` のようなファイルや ADR）から、原則が破られたときに起きるであろう失敗を予測して観点化する。`discovered_from.root_cause_file: "docs/concepts.*"` または `discovered_from.root_cause_adr: "ADR-..."` を持つ

起源が違うだけで、frontmatter スキーマ・3-Yes ルール・更新/deprecate の運用ルールはすべて同じ。

#### 2-2. 3-Yes ルールで作成可否を判断する

以下の 3 つすべてが Yes なら新規 TPL として起こす。1 つでも No なら、個別 Issue として処理して TPL は作らない:

1. 同じ root cause が **別の機能でも発生しうる** か?
2. 構造的なパターンとして **再発する可能性がある** か?
3. 既存の TPL でカバーされていない観点か?（既存 TPL のパターンに該当するなら「既存更新」へ）

#### 2-3. ファイルを作成する

- ファイル名: `docs/test-perspectives/TPL-YYYYMMDD-NN-<slug>.md`（`YYYYMMDD` は作成日、`NN` はその日の連番、ゼロ埋めなし、`<slug>` は観点を端的に表す小文字 kebab）。ホスト repo が独自規約を持つ場合はそちらに従う
- frontmatter:

  ```yaml
  ---
  id: TPL-YYYYMMDD-NN
  title: "観点を1行で表現"
  status: active            # active | deprecated
  date: YYYY-MM-DD
  applicable_to:
    - "再利用可能な抽象パターン（例: 設定値を消費する機能）。1 行 = 1 パターン。複数パターンに当てはまるなら複数行"
  known_consumers:          # optional — この観点が適用されると判明している具体的 consumer。grep 可能な kebab-case
    - feature-name
  discovered_from:
    - issue: "#N"                              # retrospective の場合
    # - root_cause_adr: "ADR-XXXXXXXX-XX"      # proactive（ADR 起源）の場合
    # - root_cause_file: "docs/concepts.*"     # proactive（原則ファイル起源）の場合
    # - root_cause_file: "path/to/file.ts:LINE"
  related_to:
    - TPL-XXXXXXXX-XX        # optional — 同ディレクトリの実在 TPL のみ
  topic: <controlled-vocabulary>   # ホスト repo の ADR 語彙があればそれ、無ければ free-form kebab
  scope:
    packages:
      - <existing-package-or-source-root>
  ---
  ```

  - `applicable_to` — 適用される **抽象パターン**。consumer の具体名は書かない（そちらは `known_consumers`）。consumer 空間が広すぎて列挙が無意味なら `known_consumers` ごと省略してよい
  - `known_consumers` — 新たに該当 consumer が見つかったら追記する
- 本文（5 節構成）:

  ```markdown
  # TPL-YYYYMMDD-NN: 観点を1行で表現

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
  ```

- ホスト repo が TPL の一覧表（`docs/test-perspectives/README.md` 等）を持つ場合はそこに行を追加する。`tpl:validate` 等があれば実行して frontmatter と一覧表の整合を確認する

> proactive を引用した DesignDoc は、その実装 PR で該当チェックリスト項目の contract test と AT AC を着地させる（"forward 運用"）。`acceptance-test` スキルがこの転記を行う。

### 3. 既存更新

新しい Issue が既存 TPL のパターンに該当する場合（3-Yes の 3 番目が No）、その TPL を更新する:

- `discovered_from` セクションに Issue を追記する
- チェックリスト・「既知の対処パターン」・「関連テスト」の更新が必要ならそれも行う
- 起源は変えない（retrospective の TPL に proactive の根拠が後付けされることはあるが、`discovered_from` に両方並べればよい）

### 4. deprecate

実装の構造変更などで、ある観点が **原理的に発生しなくなった** 場合:

- `status` を `deprecated` に変更する
- エントリ自体は **削除しない**。本文の末尾に「なぜ deprecated にしたか」の rationale を追記する（後から「この観点はなぜ消えたのか」を辿れるようにするため）。rationale には `deprecated` の語を含める（ホスト repo の validator がこれを要求することがある）
- より新しい TPL がこの観点を包含する場合は、その TPL を `superseded by TPL-XXXXXXXX-XX` として rationale に明記する（ADR の `superseded_by` 運用と同じ）
- deprecate の **トリガー** は定期 deprecation レビュー（前述、cadence はホスト repo 次第）で起こすのが基本。レビューでは各 `active` TPL について「引用された `root_cause_file` / `root_cause_adr` は今も存在するか」「アーキテクチャの前提が変わっていないか」「これを包含するより新しい TPL があるか」を確認し、`keep` / `update` / `deprecate` を判断する

### 5. レビュー依頼

作成・更新・deprecate した TPL ファイル（と一覧表の差分）をユーザーに提示し、レビューを依頼する。

## TPL のライフサイクル

```
concept（docs/concepts.* / ADR）
   │   原則を実装に落とすときに違反しうる観点を抽出
   ▼
proactive TPL   ← 開発前に書く（予防可能な学習）
   │
   ▼
development（DesignDoc + 実装）
   │
   ▼
bug（proactive TPL でカバーできなかった失敗）
   │   実際に起きた失敗を一般化
   ▼
retrospective TPL   ← bug 修正と同じ PR で書く（不可避な学習）
```

- **proactive TPL** は **予防可能** な学習 — 書ければ bug を未然に防げる。書ければ書けるほど retrospective に学ぶしかない bug が減る
- **retrospective TPL** は **不可避** な学習 — 起きてからしか書けないが、起きたら必ず書く（同じ bug を 2 回起こさない）
- retrospective TPL を書くたびに「この観点を proactive TPL として書いておけたか?」を自問する。書けたはずなら、それは「proactive スキャンの漏れ」自体が次回のレトロスペクティブの素材になる（TPL としては記録しない）

## ADR との違い

- **ADR**: 過去の判断の記録（「我々はこう決めた」）
- **TPL**: 未来の検証の集約（「これを検証すべき」）

両者は frontmatter の `topic` / `scope.packages` を共有しているので、同じトピックで横串検索すれば「過去の判断」と「検証すべき観点」を同時に発見できる。

## 参照タイミング（他スキルとの連携）

- **DesignDoc 作成時**（`design-doc` スキル）: 該当 `topic` / `scope.packages` の既存 TPL を一覧し、さらに同じ topic の `concepts*` / 関連 ADR を読んで、まだ TPL になっていない原則で今回の設計が違反しうるものがないか確認する。あれば 3-Yes ルールに照らして proactive TPL を **同じ PR で** 起こす（このスキルを呼ぶ）
- **新機能の実装時 / 受け入れテスト作成時**（`acceptance-test` スキル）: AC を書く前に該当 TPL のチェックリストを確認し、引用した proactive TPL のチェックリスト項目を AC に転記する
- **bug 修正時**: 同じパターンの TPL がすでに存在しないか確認し、あれば `discovered_from` に追記する。なければ 3-Yes ルールで retrospective TPL の新規作成を検討する。併せて「この bug は proactive TPL を書いていれば防げたか?」も自問する

## スコープ外

`topic` / `package` に紐付かない **メタ観点**（全機能 PR に共通して適用する横断フィルタなど）は TPL スキーマに載せない。横串検索の単位（`topic` / `scope.packages`）を持たないものは TPL として管理する利点が薄いため。そういう観点はホスト repo の Issue / PR テンプレートのチェックリスト等で surface する。
