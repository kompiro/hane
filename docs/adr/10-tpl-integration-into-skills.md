# ADR-10: テスト観点ライブラリ（TPL）を hane の skill 群に optional に統合する

- **日付**: 2026-05-12
- **ステータス**: 決定済み
- **Issue**: [#10](https://github.com/kompiro/hane/issues/10)（アンブレラ）— 実装: [#11](https://github.com/kompiro/hane/pull/11)（設計ドキュメント）, [#12](https://github.com/kompiro/hane/issues/12) / [#16](https://github.com/kompiro/hane/pull/16)（`acceptance-test`）, [#13](https://github.com/kompiro/hane/issues/13) / [#17](https://github.com/kompiro/hane/pull/17)（`test-perspective`）, [#14](https://github.com/kompiro/hane/issues/14) / [#18](https://github.com/kompiro/hane/pull/18)（`design-doc`）, [#15](https://github.com/kompiro/hane/issues/15) / [#19](https://github.com/kompiro/hane/pull/19)（`qa`）
- **関連**: [ADR-92](92-tpl-issue-anchor-for-proactive.md)（proactive TPL の採番と `discovered_from.issue` についての訂正。下記「決定」の「proactive TPL は Issue が無いことが多い」の前提を改める）, [ADR-8](8-issue-based-doc-numbering.md)（「host repo の独自規約を優先」「Issue 番号優先の採番」の先例。本 ADR でも踏襲）, karasu `docs/test-perspectives/README.md` および karasu `ADR-20260509-04`（汎化元となった TPL 運用の原典）。本 ADR は設計ドキュメント `docs/design/tpl-acceptance-test-integration.md`（PR #11）を昇格させたものだが、そのファイルは昇格時に圧縮のため削除した（経緯は本 ADR に集約）

## 背景

`kompiro/karasu` では **テスト観点ライブラリ（Test Perspective Library, TPL）** という運用が育っている。再発しうる失敗パターンを `docs/test-perspectives/` 配下に 1 観点 1 ファイル（frontmatter + 3〜5 項目のチェックリスト）で蓄積し、DesignDoc / 受け入れテストが関連 TPL の ID を引用することで、既知の落とし穴が関連機能の変更時に再点検される。これは karasu ローカルの慣習で、karasu の `CLAUDE.md` と PR/Issue テンプレートに配線されているだけだった。karasu の TPL README 自身が「`/hane:acceptance-test` に同等のプロンプトを足すのは kompiro/hane 側の follow-up」と明記していた。

`hane` がこの TPL ⇄ acceptance-test 連携をサポートし、他の repo も同じ運用を採用できるようにしたい。ただし必須にはせず、また skills-only な plugin に karasu の tooling を持ち込まない。設計ドキュメントでは 4 つの論点を検討した: gating メカニズム / 汎化する範囲と karasu ローカルに留める範囲 / TPL の authoring を新 skill にするか既存 skill の編集で足りるか / follow-up PR への分割方法。

## 決定

hane の skill 群に optional な TPL サポートを追加する。host repo が `docs/test-perspectives/` ディレクトリを持っているかで gating する。

- **Gating**: `docs/test-perspectives/` の存在で判定する。host の `CLAUDE.md` に新しいマーカーは導入しない — `acceptance-test` が `type:` frontmatter で、`design-doc` / `start-dev` が `status:` ラベルや `docs/{design,adr}/` ディレクトリで gating しているのと同じ流儀。ディレクトリが無ければ TPL 関連ステップはすべてクリーンにスキップされる。
- **汎化の境界**: ドキュメントの**形**（frontmatter スキーマ、本文 5 節構成）、**運用ルール**（3-Yes ルール、`discovered_from` による retrospective / proactive 起源の区別、deprecation = `status` を変えて末尾に rationale を追記・削除はしない）、**ライフサイクル**（concept → proactive TPL → development → bug → retrospective TPL）、**参照タイミング**（DesignDoc 作成時 / 新機能実装時 / bug 修正時）は hane に汎化する。**tooling**（`tpl:validate` / `tpl:related` / 定期 deprecation レビューの自動化）と `topic` の **controlled vocabulary** は host ローカルに留め、条件付きで参照する（「host repo が提供していれば使う」）。hane には何も移植しない — これは hane の「skill ファイルと manifest しか持たない、テスト・ビルドツールは導入しない」というスタンスを保つため。
- **独立した `test-perspective` skill**: TPL レコードは新設の `test-perspective` skill が **produce（作成・更新・deprecate）** する。`acceptance-test` と `design-doc` は TPL を **consume（引用）** するだけ。produce / consume を分けることで、authoring ロジック（スキーマ・3-Yes・ライフサイクル・deprecation）を 1 箇所の正典に集約でき（AT skill と design-doc skill に重複させない）、AT を書くかどうかと独立に bug 修正フローからも呼べる。
- **TPL のファイル名規約**: `docs/test-perspectives/TPL-<番号>-<slug>.md`、見出し `TPL-<番号>`、ゼロ埋めなし。番号の優先順位は ADR-8 と同じく **紐付く Issue 番号 → PR 番号 → ローカル採番（既存最大 +1）** とする — retrospective TPL は起点の `bug` / `test-infra` Issue 番号（`discovered_from.issue` と揃う）、proactive TPL は Issue が無いことが多いのでそれを起こした DesignDoc PR の番号、どちらも無いときだけローカル採番。1 つの Issue / PR に複数 TPL を切る場合は slug で区別し、採番後はリネームしない（外部参照が番号を指すため）。karasu の `TPL-YYYYMMDD-NN` のように host repo が独自規約を持つ場合はそちらを優先する（ADR-8 と同じエスケープハッチ）。日付ベースではなく GitHub 番号ベースにしたのは、AT / ADR と同じく並行ブランチでの連番衝突を避け、ドキュメントから Issue / PR への一跳びの追跡性を持たせるため。
- **PR 分割**: (3) 設計ドキュメント → (1) `acceptance-test` の TPL-aware 化 → (2a) `test-perspective` skill 新設 → (2b) `design-doc` の TPL-aware 化 → (2c) `qa` のカバレッジヒント。(1) と (2a) は独立、(2b)/(2c) は (2a) に依存。すべて実装・マージ済み。hane 自身は `docs/test-perspectives/` を採用しないため、各実装 PR は「ディレクトリ不在時にスキップする / 既存出力を変えない（no regression）」ことを AT の AC に含めた。
- **hane 自身は `docs/test-perspectives/` を採用しない**: hane の dogfooding は利用先 repo（karasu）で行われており、hane 内に観点を貯める母体が薄い。skill body の妥当性は利用先 repo での動作で担保する、という `CLAUDE.md`「実装方針」の既存スタンスを維持する。したがってこれらの skill は hane リポジトリ内では no-op。

## 理由・帰結

**ポジティブ**

- karasu 以外の repo もディレクトリを 1 つ作るだけで TPL 運用を採用でき、authoring / 引用 / カバレッジヒントが `/hane:test-perspective`・`/hane:acceptance-test`・`/hane:design-doc`・`/hane:qa` を通じて使えるようになる。
- gating が hane の他の host 慣習 gate とすべて同型 — 「ディレクトリ / frontmatter / ラベルが存在するか?」という単一のメンタルモデルで済み、skill ごとの特例が無い。
- produce / consume の分離が既存の `acceptance-test` と `design-doc` の分離と同じ構造なので、skill セットの一貫性が保たれる。
- hane の tooling-free スタンスは無傷 — `tpl:*` スクリプトも validator も CI も追加していない。

**ネガティブ**

- `docs/test-perspectives/` を持たない repo にとって no-op の skill が 1 つ増える — ただし他の skill も host 慣習次第で no-op になりうるので、新しい種類の問題ではない。
- `topic` 語彙と TPL ファイル名の詳細が host 定義なので、採用する 2 つの repo が divergence しうる — これは karasu の `adr.config.json` / `docs/adr/README.md` 語彙を hane に焼き込まないことの意図的なトレードオフ。
- `/hane:qa` のカバレッジヒントは AT の `**Related TPLs**:` メタ欄と `**対象**:` のプロース記述に依存するため、重なり判定はベストエフォートで、完全な Fit/Gap matrix（host repo 側のワークフローのまま）の代替にはならない。

## 却下した案

- **host の `CLAUDE.md` の明示マーカーで gating する** — 却下。hane の他の gate はどれもそうなっておらず、「ディレクトリが存在する」以上の利点が無いのに hane と host repo の間に綴り・配置の取り決めが増える。
- **TPL の authoring を `acceptance-test`（retrospective）と `design-doc`（proactive）の skill に取り込み、新 skill を作らない** — 却下。authoring / 更新 / deprecate のロジックが 2 箇所（bug 修正を含めると 3 箇所）に重複し、bug 起源の retrospective TPL は必ずしも AT skill 経由で書かれない。
- **`acceptance-test` の consume 側だけ出して残りは後回し** — 最初のマイルストーンとしては検討した（PR #16 がほぼそれ）が、停止点ではない。produce 側の skill が無いと host repo は hane 内に authoring の正典を持てない。
- **karasu の `tpl:validate` / `tpl:related` / レビュー workflow の tooling を hane に移植する** — 却下。hane は skill ファイルと manifest しか持たず、tooling は karasu の package 構成と `@kompiro/adr-tools` の config に結びついている。
- **hane 自身が `docs/test-perspectives/` を採用する** — 当面は却下。hane の表面は skill body そのもので、それは利用先 repo で検証され、観点を貯める母体が薄い。
