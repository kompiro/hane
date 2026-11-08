# ADR-103: Retire でモデルからの呼び出しも止め、`init` が TPL の id 形式を config に書く

- **日付**: 2026-11-08
- **ステータス**: 決定済み
- **Issue**: [#103](https://github.com/kompiro/hane/issues/103)
- **関連**: [ADR-55](55-skill-deprecation-convention.md)（deprecate 運用。本 ADR はその Retire の定義を改める）, [ADR-101](101-move-test-perspective-to-tpl-tools.md)（`test-perspective` の引退。本 ADR はその「hane は TPL の id 形式の既定を定めない」を改める）, [ADR-10](10-tpl-integration-into-skills.md)（hane の TPL を `TPL-<番号>` で採番していた）, [#102](https://github.com/kompiro/hane/pull/102)（ローカルの `/code-review` で両方の問題が見つかった PR）

## 背景

#102 は `test-perspective` を ADR-55 の Retire レベルで引退させた。マージ後に #102 へ当てたローカルの
`/code-review` で、次の 2 つが見つかった。

- **Retire の定義がモデルを止めない。** ADR-55 は「トリガー語を外せば harness はもう候補に出さない」と
  している。実際には、トリガー語の無い `description` でもモデルが内容から skill を選ぶ余地が残る。
  #102 は `test-perspective` にだけ `disable-model-invocation: true` を付け、ADR-55、README、
  CONTRIBUTING の定義と、先に引退した `qa` は古いままだった
- **`init` が TPL の id 形式を選ばせない。** hane は ADR・AT と同じ GitHub 番号ベースで TPL を
  `TPL-<番号>` と採番してきた（ADR-10）。後継の skill と `tpl validate` は host の `tpl.config.json` の
  `idFormat` に従い、config が無ければ `date-sequence`（`TPL-YYYYMMDD-NN`）になる。ADR-101 は
  「hane は既定を定めない」としたので、`init` で TPL を始めた repo は選ばないまま `date-sequence` になる。
  `tpl init` も常に `date-sequence` を書く

## 決定

- **Retire レベルに `disable-model-invocation: true` を加える。** ADR-55 の Retire は、トリガー語の削除、
  `description` 先頭の `[Deprecated]` に加えて、frontmatter にこのキーを付ける。ユーザーが名前で
  呼べば本文は読める。引退済みの `qa` にも付ける。Soft-deprecate は変えない
- **引退した skill のバナーは「下の手順に従わない」と書く。** 名前で呼ばれたときに、古い手順を
  実行せず後継を案内させるため
- **`init` は `docs/test-perspectives/` に TPL がまだ無いとき、TPL の id 形式を訊いて
  `tpl.config.json` に書く。** 既定は `issue-number`（`TPL-<番号>`）で、ADR・AT の採番と揃う。
  `date-sequence` も選べる。`tpl init` は使わない
- **`init` が `.gitkeep` と config を作るのは、ディレクトリに TPL がまだ無く、host に tpl-tools の config（`tpl.config.json` か `--config` で渡すファイル）が無いときだけ。** TPL がすでにある
  repo の運用は作り変えない。config が無いまま `TPL-<番号>` のファイルがあれば、`"idFormat": "issue-number"`
  を足すよう案内だけする

## 理由

- **Retire の目的は後継と競合させないこと**（ADR-55）で、トリガー語の削除だけではそれを満たさない。
  `disable-model-invocation` は Claude Code が skill に用意している、モデルからの呼び出しを止める
  キーで、ユーザーが名前で呼ぶ経路は残る。ADR-55 の「本文は provenance として残す」と両立する
- **既定を `issue-number` にするのは、hane の他の記録と番号の付け方を揃えるため。** ADR・AT は
  Issue 番号で採番し（ADR-8）、hane の TPL もそうしてきた。`init` で始めた repo だけ TPL の id が
  日付になると、どの Issue から起きた TPL かがファイル名から読めなくなる
- **config を `init` が書くのは、選ばなかった結果が tpl-tools の既定になるのを避けるため。** 後継の
  skill も検証の CLI も config を読むので、id 形式を記録する場所は config が 1 つで足りる

## 却下した案

- **`init` は `tpl init` を案内するだけにする**: 却下。`tpl init` は `idFormat` を選べず `date-sequence`
  を書くので、案内どおりに進めても hane の採番と揃わない。案内を飛ばした repo も `date-sequence` になる
- **Retire の定義は変えず、`disable-model-invocation` を skill ごとの判断にする**: 却下。Retire にする
  条件（後継が完全に覆う）を満たす skill は、どれも後継と競合させたくない。skill ごとに判断すると
  `qa` のように付け忘れが残る
- **TPL がすでにある repo にも config を書く**: 却下。ファイル名の形式を推定して書くことになり、
  `init` の「不足を埋めるだけで既存の構造を作り変えない」（`skills/init/SKILL.md`「スコープ外」）に反する。既存のファイル名に
  合わせるのは TPL を書く側の skill が担う（kompiro/tpl-tools#52）

## 帰結

- 引退した skill はモデルの skill 一覧に出なくなる。ユーザーが名前で呼んだときはバナーが後継へ案内する
- `init` で TPL を始めた repo は `tpl.config.json` を持ち、id 形式が明示される
- `init` 以前から `TPL-<番号>` で TPL を書いていて config の無い repo は、`idFormat: issue-number` を
  自分で足す必要がある。CHANGELOG がそれを告げる
