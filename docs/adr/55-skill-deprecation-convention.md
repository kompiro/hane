# ADR-55: skill の deprecate 運用（frontmatter マーカー + 2 段階の引退）を定める

- **日付**: 2026-06-30
- **ステータス**: 決定済み
- **Issue**: [#55](https://github.com/kompiro/hane/issues/55)
- **関連**: [ADR-8](8-issue-based-doc-numbering.md)（採番ルール）, `test-perspective` skill（`active` / `deprecated` の status を持つ TPL 運用の先例）

## 背景

hane の skill は増えてきており、機能が他へ吸収されて使われなくなるものが出てきた。
しかし **skill を引退させる運用が無い**。skill を「非推奨」とマークする手段も、
なぜ引退させたのか（理由・後継）を記録する場所も、利用者に知らせる方法も無かった。

最初の具体例は **`qa`** skill（`docs/acceptance/` の受け入れテスト記録から QA
チェックリストを日付き md に生成する）。この責務は次の 2 つでより良く満たされる:

- **`qa` サブエージェント**（PR の diff からテスト不足を埋める。より能動的）
- **`acceptance-test`** skill（AT 記録そのものを所有する）

`qa` を引退させたいが、その場限りの削除にせず、将来の引退も一貫して監査可能に
できるよう、まず再利用できる deprecate 運用を定めたい。

論点は 2 つ: (1) 何をもって deprecate を「識別可能」にするか / (2) 「マークする」と
「実際に呼ばれなくする」をどう扱うか。

## 決定

skill の deprecate 運用を、**frontmatter マーカー**と **2 段階の引退レベル**で定める。

### frontmatter マーカー

deprecate する skill の `SKILL.md` frontmatter に以下を付ける:

- `deprecated: true` — **必須**。機械的に識別可能にするマーカー。
- `deprecated_reason: <一文>` — **必須**。なぜ引退させたか。
- `superseded_by: <後継の skill / subagent 名、無ければ "none">` — 推奨。行き先を示す。

加えて、`SKILL.md` 本文の先頭に deprecation バナー（`> **⚠️ Deprecated.** …`）を置き、
理由・後継・本 ADR へのリンクを人間向けに明示する。

### 2 段階の引退レベル

**`deprecated: true` を付けても、harness のトリガー集合からは外れない** — skill が
候補に出るかどうかを決めているのは `description`（トリガー語）であり、harness は
`deprecated` キーを解釈しない。「マークする」と「呼ばれなくする」は別レイヤーなので、
意図に応じて 2 段階から選ぶ:

1. **Soft-deprecate（マークのみ）** — frontmatter マーカー + バナーを付けるが、
   `description` のトリガー語は残す。skill は今まで通りトリガーされるが、非推奨で
   あることは記録される。移行期間を置きたいときに使う。
2. **Retire（引退）** — 上記に加えて `description` から「Trigger when the user
   says …」のトリガー語を取り除き、`description` を `[Deprecated]` で始める。これで
   harness はもう候補に出さない。後継が完全にカバーしている場合に使う。
   **`SKILL.md` 本文は残す**（経緯・意図の provenance を保つ）。

### 周知

- `README.md` の skills 表で、deprecated な skill の行は `~~`name`~~` と取り消し線に
  し、What it does 欄に `_Deprecated — …_` と後継を書く。
- `CHANGELOG.md` の `## [Unreleased]` に `### Deprecated`（または `### Removed`）節で
  記録する。

### `qa` への適用

`qa` は後継（`qa` サブエージェント + `acceptance-test`）が責務を完全にカバーする
ため、**Retire** レベルを適用する。トリガー語を取り除き、サブエージェントと競合
しないようにする。本文は provenance として残す。

## 理由

- **frontmatter マーカーにする**のは、Issue で求められた「frontmatter に
  `deprecated: true` を付け、理由を書いて識別可能にする」をそのまま満たすため。
  ファイルを消さずに status を持たせる発想は、`test-perspective` skill が TPL に
  `active` / `deprecated` を持たせている運用と同型で、hane 全体のメンタルモデルと
  一貫する。
- **2 段階に分ける**のは、`deprecated: true` だけでは skill がトリガーされ続ける
  という harness の実挙動があるから。マークと「実際に呼ばれなくする」を混同すると、
  「deprecate したのに呼ばれる」という齟齬が残る。レベルを明示することで、移行期間
  を置く場合（Soft）と即引退する場合（Retire）を取り違えない。
- **本文を残す**のは、なぜ引退させたかを後から辿れるようにするため。skill を削除
  すると、その存在理由・引退理由がコミット履歴の奥に消える。
- **`qa` を Retire にする**のは、後継が能動的（subagent は diff から不足を埋める）で
  あり、トリガー語を残すとユーザーの「qa」発話で subagent と skill が競合するから。
  移行期間を置く理由が無いため、即引退が妥当。

## 却下した案

- **deprecate する skill を即削除する** — 却下。引退理由・経緯が失われ、将来同じ
  判断を再検討するときに根拠を辿れない。frontmatter マーカー + 本文残置なら監査可能。
- **`deprecated: true` だけで運用を完結させる（description は触らない）** — 却下。
  harness はこのキーを解釈しないため、マークしても skill はトリガーされ続ける。
  「呼ばれなくする」意図が達成できず、`qa` のように後継と競合するケースを解決できない。
- **deprecated skill の一覧を別ファイル（DEPRECATED.md 等）で管理する** — 却下。
  status を skill 本体から離すと同期ずれの温床になる。frontmatter に持たせれば
  skill ファイルが唯一の真実になり、`README.md` 表が人間向けの索引を兼ねる。
