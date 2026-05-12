---
name: acceptance-test
description: >
  Create acceptance test records in docs/acceptance/.
  Trigger when the user says: "アクセプタンステスト", "受け入れテスト", "ATを作成",
  "acceptance test", "create AT", or similar phrases requesting acceptance test documentation.
---

# Acceptance Test Record Skill

実装予定の機能や変更に対するアクセプタンステスト記録を `docs/acceptance/` に作成する。

## 手順

1. AT 番号を決定する（詳細は「命名規則」参照）。優先順位:
   1. 紐付く GitHub **Issue 番号**があればそれを使う（`<issue>-kebab-title.md`）
   2. Issue が無く **PR 番号**が確定している場合は PR 番号を使う（draft PR を先に開く運用も可）
   3. どちらも無い場合のみ `docs/acceptance/` 内の既存ファイルの最大番号 + 1 でローカル採番
2. ユーザーに以下を確認する（明示されていない場合）：
   - 対象となる機能・変更の概要
   - 紐付く Issue 番号（あれば）／ Issue が無ければ PR 番号
   - 関連するADR（あれば）
   - 対象コード・モジュール
3. 対象の既存コード、仕様ドキュメント、ADRを読み、実装の詳細を把握する
4. 変更対象ファイルから `type` を推論する（ホスト repo が `type` 区分を採用している場合のみ。`docs/acceptance/` 内の既存 AT に `type:` フロントマターが見当たらない場合は本ステップをスキップしてよい）:
   - プロダクトコード（host repo が定めるソースルート、例: `src/` や `packages/` 配下）のみ変更 → `type: product`
   - それ以外（`.claude/`, `docs/` 等のツール・ドキュメント）のみ変更 → `type: tool`
   - 両方含む場合 → ユーザーに確認する
5. テスト観点ライブラリ（TPL）を確認する（ホスト repo が `docs/test-perspectives/` を採用している場合のみ。ディレクトリが無ければ本ステップをスキップする）:
   - 関連 TPL を探す: ホスト repo が `tpl:related <topic>` 等のスクリプトを提供していればそれを使う。無ければ `docs/test-perspectives/` 配下の TPL ファイルの frontmatter（`topic` / `scope.packages` / `applicable_to` / `known_consumers`）を grep し、今回の変更対象モジュール・トピックにマッチするものを拾う
   - マッチした TPL の ID を AT 本文の `**Related TPLs**:` メタ欄に列挙する（`docs/test-perspectives/` へのリンク付き）
   - うち **proactive** な TPL — `discovered_from` が原則ファイル（`concepts*` 等）や ADR を指すもの。`issue: #N` を指すものは retrospective — については、関連するチェックリスト項目を AC として転記する。自動化予定でも手動確認でも構わないが、AC として明示する（"forward 運用": proactive TPL を引用した DesignDoc は、その実装 PR で該当チェックリスト項目の contract test と AT AC を着地させる）。転記した AC には出所の TPL ID を併記する
6. 受け入れ条件（AC）を具体的かつ検証可能な形で記述する
7. ファイルを作成し、ユーザーにレビューを依頼する

## ファイル形式

```markdown
---
type: product  # または tool
---

# AT-<番号>: タイトル

- **日付**: YYYY-MM-DD
- **Issue**: #<番号> または なし
- **PR**: #<番号> または なし（Issue が無く PR 番号で採番した場合に明記）
- **関連ADR**: ADR-<番号> または なし
- **Related TPLs**: TPL-XXXXXXXX-XX, … または なし（`docs/test-perspectives/` を採用する repo のみ。該当無し / 不採用 repo では `なし` か欄ごと省略）
- **対象**: 対象モジュール・ファイルの説明

## 概要

変更の目的と背景を1〜2文で記述。

## 受け入れ条件

### AC-N: 条件グループ名

- [ ] 具体的かつ検証可能な条件
- [ ] 入力と期待出力が明確な条件
- [ ] エッジケースやエラーケースも含む

## 検証方法

（自動テストコマンド、手動確認手順など）
```

## 受け入れ条件の書き方ガイドライン

- **具体的**: 「正しく動作する」ではなく「`fn(input)` が `expected` を返す」のように書く
- **検証可能**: チェックボックスで完了を判断できる粒度にする
- **グループ化**: 関連する条件を AC-N 単位でまとめ、各グループに説明的な名前を付ける
- **網羅的**: 正常系・異常系・エッジケース・公開APIを漏れなくカバーする
- **独立的**: 各ACは他のACに依存せず、単独で検証できることが望ましい
- **TPL 由来の AC は出所を併記**: proactive TPL のチェックリスト項目から転記した AC には、どの TPL ID から来たかを併記する（例: `- [ ] ...（TPL-20260509-18）`）。後から「この AC はなぜあるのか」を辿れるようにする

## 命名規則

- ファイル名: `docs/acceptance/<番号>-kebab-case-title.md`
- **番号は GitHub の番号を優先**（優先順位順）:
  1. 紐付く Issue 番号（例: Issue #42 → `docs/acceptance/42-add-login.md`、見出しは `AT-42`）
  2. Issue が無ければ PR 番号（例: PR #8 → `docs/acceptance/8-foo.md`、見出しは `AT-8`）。PR 番号は branch を push して draft PR を開けば確定する
  3. どちらも無いときのみローカル採番（既存最大 + 1）
- ゼロ埋めはしない（Issue / PR 番号は可変桁のため）
- 1 Issue / 1 PR に対して複数の AT を切る場合は `<番号>-<slug>.md` の slug 部分で区別する（例: `42-login-form.md`, `42-login-error.md`）
- **採番後はリネームしない**: 外部参照（Issue・PR 本文・コミットメッセージ・他 AT からのクロスリンク）が AT 番号を指しているため、ローカル採番→Issue 採番のような巻き直しは不可。代わりに AT 内の `Issue` / `PR` 欄で後付けの対応関係を示す
- タイトルは機能・変更を端的に表す英語のkebab-case
- 既存の `NNNN-` 形式（ゼロ埋め4桁）の AT はリネームしない（外部参照を保つため）。新規作成分から本規則を適用する

## 自動化アノテーション（Playwright / Vitest）

すべての AT ファイルは以下の唯一の方式で自動化状態を表す。
"Verified by" メタ欄や "Automated Checks" セクション分けなど、
他の方式は採用しない（既存ファイルは順次本方式に揃える）。

### ルール

1. **チェックボックス**: 各受け入れ条件は `- [x]`（自動化済み） / `- [ ]`（未自動化）で表す。
2. **テスト名にケースラベル**: Playwright / Vitest テスト名に `(Case 1)`, `(TC-2)`, `(AT-0031-02)` のようなラベルを含める。AT markdown とテストの対応付けが機械的に追跡できる。
3. **アノテーション blockquote**: 自動化された箇条書きの**直後の行**に、以下の形式で blockquote を 1 行で添える。テストファイルのパスは host repo の慣習に従う（例: `tests/<file>.spec.ts`、`packages/e2e/tests/<file>.spec.ts` など）。

   ```markdown
   - [x] チェック項目テキスト
   > ✅ Automated — `tests/<file>.spec.ts` › `<test name>`
   ```

   一部のみ自動化（視覚確認は手動など）の場合:

   ```markdown
   - [x] チェック項目テキスト
   > 🟡 Partially automated — `tests/<file>.spec.ts` › `<test name>`（視覚的判定は手動）
   ```

4. **AC 節先頭の "section-level partial" blockquote（任意）**: 個々の `[x]` を per-bullet で展開する余裕がないとき、AC 節の冒頭に 1 つだけ `🟡 Partially automated — ...` blockquote を置いて、節全体の自動化スコープを記述してよい。後で per-bullet に展開する暫定形として使う。

   ```markdown
   ## 受け入れ条件

   > 🟡 Partially automated — `tests/at-XXXX.spec.ts` covers AC-1 (tab switching), AC-3 (editor↔diagram updates, partial), and AC-5 (Samples tab). AC-2 / AC-4 stay manual until follow-up coverage lands.

   ### AC-1: ...
   - [ ] ...
   ```

   coverage 検査ツール（host repo にある場合）はこの形式を canonical とみなして検査を通す想定で設計してよい。per-bullet 展開はベストエフォートで進める。

5. **ショートハンド A — ファイル単位（suite-wide）**: 同一テストファイルが連続する `[x]` バレット群を全部カバーする場合、各バレットに blockquote を書く代わりに、バレット群の**直前**に 1 つだけ suite-wide マーカーを置ける。任意の markdown 見出し（`#`〜`######`）が現れた時点で対象範囲は終了する。

   ```markdown
   ### AC-1: render flags

   > ✅ Automated by `tests/render.test.ts` (suite-wide)

   - [x] Missing file → stderr error message + exit code 1
   - [x] Default (no `--view`) → SVG written to stdout
   - [x] `--output <path>` → SVG written to file
   ```

   範囲内に未自動化（`- [ ]`）が混じる場合や、別ファイルでカバーされる項目がある場合は、suite-wide ではなく per-bullet 形式に戻すこと（局所例外を許すと範囲が曖昧になるため）。

6. **ショートハンド B — 1 バレット → 複数テスト**: 1 つのバレットが複数の `it(...)` で構成される場合、テスト名をスラッシュ区切り（`/`）で列挙する。

   ```markdown
   - [x] `NodeFileSystemProvider` reads files, lists directories, and checks existence
   > ✅ Automated — `tests/render.test.ts` › `readFile returns file contents` / `readDir returns entries with kind` / `exists returns true` / `exists returns false`
   ```

7. **未自動化バレットの理由 blockquote（任意）**: AC 節の末尾に 1 つだけ、未チェック項目をまとめて理由付きで blockquote にできる。何が／なぜ手動なのかを 1 行ずつ書く。

   ```markdown
   > 未チェック項目について:
   >
   > - "プレビューがリアルタイム更新": 視覚判定が必要なため AI / 人間レビューに残す。
   > - "別 AT でカバー済みの項目": 該当 AT 番号を併記。
   ```

   理由が単純（"視覚判定" のみ等）なら省略してよいが、複数の手動項目が並ぶときはこの形でまとめる。

### 完成イメージ

```markdown
## 受け入れ条件

### AC-1: ProjectSelector UI

- [x] ドロップダウンにプロジェクト一覧が表示される
> ✅ Automated — `tests/at-0004-project-management.spec.ts` › `dropdown lists seeded projects in the order they were written`

- [x] 「+ New」ボタンで作成できる
> ✅ Automated — `tests/at-0004-project-management.spec.ts` › `+ New flow creates a project and persists it`

- [ ] Rename ボタンで現在プロジェクト名を変更できる

### AC-2: ProjectModeApp 初期化

- [x] 起動時に前回開いたプロジェクトが localStorage から復元される
> ✅ Automated — `tests/at-0004-project-management.spec.ts` › `lastProjectId in localStorage restores the previously selected project`

- [ ] 編集後にプレビューがリアルタイム更新される
- [ ] ワーニングパネルに警告が表示される

> 未チェック項目について:
>
> - "プレビューがリアルタイム更新": 視覚判定が必要なため手動レビュー。
> - "ワーニングパネル": 別 AT で自動化済み（該当 AT を併記）。
```

### 既存スタイルからの移行

過去の AT ファイルで方式が混在している場合、いずれも上記の正規方式に畳む:

| 旧方式 | 移行先 |
| --- | --- |
| `- **Verified by**: `it("...")`` メタ欄 | 該当バレットを `- [x]` + 直後 `> ✅ Automated — ... › ...` blockquote に置き換え |
| `## Automated Checks` / `## Manual Verification` 節分割 | バレットを元の AC 節に戻し、各バレットに `> ✅ Automated` を添える |
| マーカーなし（spec が既にある） | spec ファイルを host repo の test ディレクトリから探し当てて blockquote を追加 |

coverage 検査ツールが host repo にある場合はそれを使って機械化できる。なければベストエフォートで揃える。
