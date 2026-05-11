# Test Perspective Library (TPL) integration into hane skills

- **日付**: 2026-05-11
- **Issue**: [#10](https://github.com/kompiro/hane/issues/10)
- **ステータス**: 検討中
- **関連**:
  - karasu `docs/test-perspectives/README.md`（TPL の完全な運用フロー）
  - karasu [`ADR-20260509-04`](https://github.com/kompiro/karasu/blob/main/docs/adr/20260509-04-test-perspective-library.md)（TPL 運用開始の決定）
  - karasu#1264（forward 運用 — hane への移植が follow-up と明記された箇所）, karasu#1221（メタ観点を TPL スキーマに載せない決定）
  - hane skills: `skills/acceptance-test/SKILL.md`, `skills/design-doc/SKILL.md`, `skills/qa/SKILL.md`
  - hane [`ADR-8`](../adr/8-issue-based-doc-numbering.md)（host repo の慣習を optional に gating する先例）

## 背景・課題

`kompiro/karasu` では **Test Perspective Library（TPL）** という運用が育っている。`docs/test-perspectives/` 配下に、再発しうる失敗パターンを構造化された「観点」（frontmatter + 3〜5 項目のチェックリスト）として 1 ファイル 1 観点で蓄積し、DesignDoc 作成時・新機能実装時・bug 修正時に該当 `topic` / `scope.packages` の TPL を参照する。DesignDoc / 受け入れテストが関連 TPL の ID を引用することで、既知の落とし穴が関連機能の変更時に再点検される。

現状、これは karasu ローカルの慣習で、karasu の `CLAUDE.md` と PR/Issue テンプレートに配線されているだけ。`hane` の skill 群（`acceptance-test` / `design-doc` / `qa`）は TPL を一切認識しない。karasu の TPL README 自身が *「`/hane:acceptance-test` に同等のプロンプトを足すのは kompiro/hane 側の follow-up」*（"forward 運用" のノート, karasu#1264）と明記している。

**ゴール**: `hane` が TPL ⇄ acceptance-test の連携を **optional に** サポートする。host repo が実際に `docs/test-perspectives/` を持っているかで gating する（AT skill が `type:` を、design-doc skill が `status:` ラベルを gating しているのと同じ流儀）。これにより他の repo も同じ運用を採用できる。

Issue #10 はアンブレラ Issue で、3 つのピースに分かれる（推奨順 (3) → (1) → (2)）:

1. `skills/acceptance-test/SKILL.md` を TPL-aware にする（minimum viable）
2. `hane` に `test-perspective` skill を新設し、`design-doc` / `qa` skill を配線する
3. **このドキュメント** — (1)(2) の前に設計を固める

このドキュメントは (3)。固めるべき論点は Issue 本文が挙げているとおり:
- karasu の TPL 機構のどこまでが汎化でき、どこが karasu ローカルに留まるか
- gating メカニズム（`docs/test-perspectives/` の存在? host `CLAUDE.md` の明示マーカー?）
- `test-perspective` を独立 skill にするか、AT / design-doc skill の編集で足りるか
- そのうえで follow-up PR にどう分割するか

## 制約・前提

- **hane は「skill ファイルと manifest しか持たない」スタンス**（`CLAUDE.md`「実装方針」）。テスト・ビルドツールは入れない。コード品質チェックもしない。したがって `pnpm tpl:validate` / `pnpm tpl:related` / `pnpm tpl:review:body` のような **tooling は hane には移植しない** — host repo が提供している場合のみ条件付きで参照する。
- **既存 skill の gating パターンに合わせる**:
  - `acceptance-test`: 既存 AT に `type:` frontmatter が見当たらなければ `type` ステップをスキップ
  - `design-doc` / `start-dev`: `status: *` ラベルが定義されていない repo ではラベル更新行をスキップ。`docs/design/` / `docs/adr/` を採用する repo のみ該当ステップ有効
  - → TPL も「`docs/test-perspectives/` が無ければクリーンにスキップ」で揃える
- **karasu の TPL README は日本語**、frontmatter スキーマは karasu の ADR と語彙（`topic`）を共有している。hane は host repo の言語・語彙を前提にできない（hane 自身の docs は英語、karasu は日本語）。したがって hane の skill body は「host repo の docs 言語に合わせる」「host repo の ADR 語彙があればそれを使う、無ければ free-form」と書く。
- **AT/ADR 命名は hane ADR-8 に従う**（GitHub Issue → PR → ローカル採番）。TPL のファイル名規約（karasu は `TPL-YYYYMMDD-NN-<slug>.md`）は ADR-8 のスコープ外なので、`test-perspective` skill 内で別途定める（後述）。

## 検討した選択肢

### 論点 A: gating メカニズム

#### 案 A1: `docs/test-perspectives/` ディレクトリの存在で gating

skill 起動時 / 該当ステップで `docs/test-perspectives/` の有無を見る。あれば TPL ステップを実行、無ければスキップ。host 固有の設定（`topic` 語彙、ファイル名規約の差分など）は、そのディレクトリ内の `README.md` があればそこから読む。

- **メリット**: 既存 gating（`type:` frontmatter の有無、`status:` ラベルの有無、`docs/design/` の有無）と完全に同じ流儀。新しい設定ファイルやマーカーが要らない。「ディレクトリを作る = 運用を始める」が直感的。
- **デメリット**: ディレクトリはあるが README が無い / 中身が空、という中途半端な状態の扱いを決める必要がある（→ README が無くても TPL ファイルがあれば動く、両方無ければ「空運用」として scan は no-op、と定義すればよい）。

#### 案 A2: host `CLAUDE.md` の明示マーカーで gating

`CLAUDE.md` に `<!-- hane:tpl enabled -->` のようなマーカー、または「ドキュメント表」に `docs/test-perspectives/` 行があるかで判定。

- **メリット**: 「ディレクトリは作ったがまだ運用しない」を表現できる。
- **デメリット**: hane の他の gating はどれも「成果物の存在」で判定していて、`CLAUDE.md` のマーカーを見る前例が無い。マーカーの綴り・場所を hane と host で合意する必要があり、結合が増える。over-engineering 感が強い。

#### 案 A3: 引数 / 対話で都度確認

skill 起動のたびにユーザーに「TPL を参照する?」と訊く。

- **メリット**: 実装ゼロ。
- **デメリット**: 自動参照されること自体が TPL の価値（karasu ADR-20260509-04「自動的に参照される状態を作ることが目的」）。毎回訊くのは運用として弱い。

→ **A1 を採る。** 既存 gating と同型で、追加の規約も要らない。

### 論点 B: karasu 機構のうち汎化する範囲

| karasu の構成要素 | 汎化する? | hane での扱い |
|---|---|---|
| `docs/test-perspectives/` の TPL ファイル群（frontmatter + 本文 5 節） | ✅ 汎化 | `test-perspective` skill がスキーマと本文構成を定義（karasu README から一般化） |
| 1 ファイル 1 観点 / `TPL-YYYYMMDD-NN-<slug>.md` 命名 | ✅ 汎化（ただし host が独自規約を持てば優先） | skill 内に命名規則として記述。ADR-8 と同様「host repo が独自規約を持つ場合はそちらを優先」のエスケープハッチ付き |
| 3-Yes ルール / retrospective vs proactive 起源 / `discovered_from` での起源判別 | ✅ 汎化 | `test-perspective` skill の中核ロジック |
| ライフサイクル（concept → proactive TPL → development → bug → retrospective TPL） | ✅ 汎化 | skill 本文に図とともに記述 |
| deprecated への移行（削除しない / rationale 必須） | ✅ 汎化 | skill の運用ルールに記述 |
| DesignDoc / AT が TPL ID を引用する（"Related TPLs" メタ行）+ proactive TPL のチェックリスト項目を AC に転記（forward 運用） | ✅ 汎化 | `acceptance-test` / `design-doc` skill の編集（= follow-up (1)(2)） |
| `topic` の controlled vocabulary が karasu の `docs/adr/README.md` を指す | 🟡 部分的 | 「host repo に ADR 語彙があればそれを使う。無ければ free-form」と書く。hane 自身は ADR 語彙を持たない（`docs/adr/README.md` 不在）ので、hane 内で dogfooding するなら free-form になる |
| メタ観点（スコープフィルタ）を TPL スキーマに**載せない** 判断（karasu#1221） | ✅ 汎化（として「TPL に載せないものの線引き」を skill に注記） | skill に「topic/package に紐付かないメタ観点は TPL にしない」と一行 |
| `pnpm tpl:validate`（frontmatter & 一覧表の machine check） | ❌ 汎化しない | host tooling。skill は「host が `tpl:validate` を提供していれば実行を促す」程度 |
| `pnpm tpl:related <topic>`（DesignDoc 用の関連 TPL 一覧出力） | ❌ 汎化しない | 同上。skill は「host が `tpl:related` を提供していればそれを使う、無ければ手動で grep」 |
| `pnpm tpl:review:body` + `.github/workflows/tpl-review.yml`（週次 deprecation レビュー Issue 自動生成） | ❌ 汎化しない | host の CI 運用。skill は「定期 deprecation レビューを推奨」とだけ書き、cadence・自動化は host に委ねる |
| Fit/Gap 分析（TPL チェックリスト × test/AT のカバレッジ matrix） | 🟡 部分的 | `qa` skill が「TPL の Fit/Gap カバレッジヒントを surface する、最低でも regress させない」程度に留める（Issue が "lower priority" と明記） |
| `@kompiro/adr-tools` の `loadConfig` 再利用 / `adr.config.json` | ❌ 汎化しない | karasu の実装詳細 |
| PR/Issue テンプレートの "TPL impact" / "Scope filter" セクション | ❌ 汎化しない（hane は PR テンプレートを配らない） | skill が「host の PR テンプレートに TPL 欄があれば埋める」と書く程度。テンプレート自体は host repo の責務 |

要するに **「ドキュメントの形・運用ルール・参照タイミングは汎化」「それを machine-check / 自動生成する tooling と、controlled vocabulary の中身は host ローカル」**。これは hane の既存スタンス（skill body は汎化、host の `package.json` scripts / lint / format は条件付き参照）と完全に一致する。

### 論点 C: `test-perspective` を独立 skill にするか

#### 案 C1: 独立した `test-perspective` skill を新設（Issue の案 (2)）

`skills/test-perspective/SKILL.md` で TPL レコードの **作成 / 更新 / deprecate** を担う。`acceptance-test` / `design-doc` skill は TPL を **引用（consume）** するだけ。

- **メリット**:
  - TPL レコードの authoring は AT / design-doc とは別の独立したタスク（独自スキーマ・3-Yes ルール・ライフサイクル）。AT skill の中にインライン展開すると AT skill が肥大化する（AT skill は既にかなり長い）。
  - `acceptance-test` と `design-doc` が「両方 docs/ 配下の成果物を作る」のに別 skill である構造と同じ。produce 側（`test-perspective`）と consume 側（`acceptance-test` / `design-doc`）を分ける。
  - bug 修正フロー（`/hane:ship` 等）からも「retrospective TPL を起こすか?」を呼べる。
- **デメリット**: skill が 1 つ増える。`docs/test-perspectives/` を持たない repo にとっては no-op の skill が plugin に並ぶ（ただし他の skill も host の慣習次第で no-op になりうるので新しい問題ではない）。

#### 案 C2: AT / design-doc skill の編集だけで済ませる（新 skill なし）

TPL の作成手順を `acceptance-test` skill（retrospective 起源）と `design-doc` skill（proactive 起源）の中にそれぞれ書く。

- **メリット**: skill 数が増えない。
- **デメリット**:
  - TPL の作成ロジックが 2 箇所に重複する（更新・deprecate も含めると 3 箇所）。
  - bug 修正は AT を伴わないこともある（karasu の `bug` Issue 起点の retrospective TPL は「bug 修正と同じ PR で書く」— 必ずしも AT skill 経由ではない）。AT skill に押し込むと呼べないケースが出る。
  - 「TPL とは何か / どう書くか」の単一の正典が無くなる。

#### 案 C3: 最小構成 — AT skill だけ TPL-aware にして、authoring skill は後回し

Issue の (1) だけやって (2) は当面やらない。

- **メリット**: いちばん小さい。consume 側だけ先に入る。
- **デメリット**: consume はできても produce（新規 TPL を起こす）の標準手順が hane に無い。host repo が karasu の README を毎回参照することになり、「hane で運用が完結する」状態にならない。ただし **段階導入としては妥当**（Issue も (3)→(1)→(2) と分けている）。

→ **C1 を採る（最終形）。ただし段階導入として (1) を先に出す（C3 は (1) のマイルストーン）。** 独立 skill にする理由は「produce と consume の分離」「authoring ロジックの単一正典」「bug 修正フローからも呼べる」。

### 論点 D: follow-up PR の分割

このドキュメント（PR (3)）がマージされた後:

- **PR (1): `acceptance-test` skill を TPL-aware にする** — host が `docs/test-perspectives/` を持つ場合のみ、AC を書く前に `topic` / `scope.packages` がマッチする TPL を scan し、(a) AT 本文に `**Related TPLs**:` メタ行で引用、(b) 引用した **proactive** TPL の関連チェックリスト項目を AC として（自動 / 手動を問わず明示的に）転記。すべて条件付き。`docs/test-perspectives/` が無ければクリーンにスキップ。→ あわせて、その変更自体の AT を `docs/acceptance/` に作る（hane 内 dogfooding。`docs/test-perspectives/` を hane が持たない状態でも skip 動作が確認できることを AC に含める）。
- **PR (2a): `test-perspective` skill を新設** — `skills/test-perspective/SKILL.md`。frontmatter スキーマ、命名 `TPL-YYYYMMDD-NN-<slug>.md`（host 独自規約優先のエスケープ付き）、3-Yes ルール、retrospective vs proactive、deprecation ルール、ライフサイクル図、参照タイミング。karasu README から一般化。host tooling（`tpl:validate` / `tpl:related`）は条件付き参照。
- **PR (2b): `design-doc` skill を TPL-aware にする** — host が `docs/test-perspectives/` を持つ場合、マッチする TPL + `concepts*` / ADR を scan し "Related TPLs" セクションで引用。原則が破られそうなら同じ PR で proactive TPL を起こす（`test-perspective` skill を呼ぶ）。
- **PR (2c): `qa` skill の TPL ヒント（lower priority）** — TPL の Fit/Gap カバレッジヒントを surface、最低でも regress させない。Issue が明示的に "lower priority" としているので、(2a)(2b) より後、または見送り可。
- 必要なら `CLAUDE.md` / `README.md` の更新（hane 自身が `docs/test-perspectives/` を持つかは別途判断 — 持たないなら skill 群は hane 内では no-op のまま dogfood は karasu で行う）。

PR (1) と (2a) は独立に出せる（(1) は consume、(2a) は produce）。(2b) は (2a) に依存（proactive TPL を起こすステップが `test-perspective` skill を参照する）。(2c) は (2a) に依存。

## 比較（論点ごとの結論）

| 論点 | 結論 |
|---|---|
| A. gating | `docs/test-perspectives/` ディレクトリの存在で gating（既存 gating と同型、追加規約なし） |
| B. 汎化範囲 | ドキュメントの形・運用ルール・参照タイミングは汎化。tooling（validate/related/review-body）と `topic` 語彙の中身は host ローカル、skill は条件付き参照 |
| C. 新 skill | 独立した `test-perspective` skill を新設（produce/consume 分離）。段階導入として AT skill の TPL-aware 化 (1) を先行 |
| D. 分割 | (3) このドキュメント → (1) AT skill → (2a) `test-perspective` skill → (2b) design-doc skill → (2c) qa skill（最後 / 見送り可） |

## 現時点の方針

1. このドキュメントを PR で出してレビュー・マージ（= Issue #10 の (3) 完了）。
2. follow-up Issue を 4 本（または Issue #10 のチェックリストとして）に分割: (1) AT skill、(2a) `test-perspective` skill、(2b) design-doc skill、(2c) qa skill。
3. (1) → (2a) → (2b) → (2c) の順で実装。各 PR は `docs/test-perspectives/` 不在時のスキップ動作を AC に含める。
4. hane 自身が `docs/test-perspectives/` を持つかは (2a) 着手時に判断（持たない方向で考えている — hane の dogfood は karasu 側で行われており、hane 内に観点を貯める母体が薄い。skill body の妥当性は karasu での利用で担保する、という既存スタンスを維持）。
5. このドキュメントは実装完了後 ADR に昇格させる（`docs/adr/` 採用 repo）。番号は ADR-8 のルールに従い Issue #10 → 採番（`docs/adr/10-...`、見出し `ADR-10`）。
