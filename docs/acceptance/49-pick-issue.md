---
type: tool
---

# AT-49: pick-issue skill が着手できる次の Issue を提示する

- **日付**: 2026-06-16
- **Issue**: #49
- **PR**: なし
- **関連ADR**: ADR-49（pick-issue skill 追加）, ADR-10（optional 慣習の gating）
- **Related TPLs**: なし（hane は `docs/test-perspectives/` を採用しないため）
- **対象**: `skills/pick-issue/SKILL.md`, `README.md`, `CHANGELOG.md`

## 概要

open な Issue から「いま着手できる」ものを選び出して提示し、選択後に `start-dev`
へ引き継ぐ `pick-issue` skill を追加する。並行セッション運用での重複作業を防ぐため、
作業中（`status: implementing` / `status: designing`）の Issue を候補から除外する
ことを最優先の要件とする。

## 受け入れ条件

### AC-1: pick-issue skill が存在し、起動できる

- [ ] `skills/pick-issue/SKILL.md` が存在し、frontmatter（`name: pick-issue`、トリガーフレーズ付き `description`）を持つ
- [ ] `/hane:pick-issue` として起動できる（skills はディレクトリ自動検出のため manifest 変更は不要）

### AC-2: 作業中の Issue を候補から除外する

- [ ] `status: implementing` を持つ Issue を候補から除外する
- [ ] `status: designing` を持つ Issue を候補から除外する
- [ ] `status: in-review` / `status: blocked` を持つ Issue を候補から除外する
- [ ] assignee が付いている Issue を「作業中」として除外する
- [ ] 本文に `Closes #N` / `Refs #N` / `Fixes #N` を含む open PR、または Issue 番号に対応するブランチがある Issue を「作業中」として除外する

### AC-3: 着手可能な Issue を候補に含める

- [ ] `status: ready` の Issue を候補に含める
- [ ] `status: designed` の Issue を候補に含める
- [ ] `status: *` ラベルがどれも付いていない open Issue を候補に含める
- [ ] 候補を `ready` → `designed` → ラベル無し の順を基本にランク付けする

### AC-4: ラベル運用が無い repo でも動く

- [ ] `status: *` ラベルが定義されていない repo では、assignee と linked PR の有無だけで作業中を判定する
- [ ] ラベル無し repo では全 open Issue（assignee/linked PR が無いもの）を候補にできる

### AC-5: 候補を提示し、除外理由を明示する

- [ ] 上位数件（3〜5 件）と推奨 1 件を提示する
- [ ] 除外した「作業中」Issue の件数と理由を 1 行で補足する（黙って絞らない）
- [ ] 着手できる候補が 0 件の場合、その旨と次のアクション（`ready` Issue の用意・作業中ラベルの棚卸し）を伝える

### AC-6: 選択後 start-dev へ引き継ぐ

- [ ] AskUserQuestion で着手する Issue を 1 件選ばせる（推奨を先頭に置く）
- [ ] 選択された Issue 番号を引数として `start-dev` を起動する
- [ ] pick-issue 自身はラベル・Issue の状態を変更しない（状態遷移は start-dev に委ねる）

### AC-7: README / CHANGELOG が更新され、スコープが守られている

- [ ] `README.md` の Skills 表に `pick-issue` が追加されている
- [ ] `README.md` の「Per-skill customization points」に pick-issue の gating（status ラベル optional）が記載されている
- [ ] `CHANGELOG.md` の `[Unreleased]` に `pick-issue` skill 追加（#49）が記載されている
- [ ] host repo の `CLAUDE.md` の生成・編集は行わない（スコープ外）

## 検証方法

hane はテスト・ビルドツールを持たない skills-only repo のため、自動テストは無い。
上記 AC はすべて AI / 人間レビューによる手動確認とする。`pick-issue` skill の実挙動
（作業中除外・ランク付け・start-dev 連携）は、利用先 repo（karasu 等）での dogfooding
で担保する。

> 未チェック項目について:
>
> - 全項目: hane に自動テストランナーが無いため、skill body の妥当性は dogfooding と利用先 repo での動作で担保する（`CLAUDE.md`「実装方針」）。レビューで内容を確認したらチェックする。
> - AC-2 〜 AC-6 の実挙動: 複数の status ラベル・assignee・open PR を持つ Issue が混在する repo で skill を実際に走らせて確認する（人間検証）。
