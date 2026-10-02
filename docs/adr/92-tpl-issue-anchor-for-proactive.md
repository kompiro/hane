# ADR-92: proactive TPL も作業の Issue を採番の起点にし、`discovered_from.issue` を持つ

- **日付**: 2026-10-02
- **ステータス**: 決定済み
- **Issue**: [#92](https://github.com/kompiro/hane/issues/92)
- **関連**: [ADR-10](10-tpl-integration-into-skills.md)（TPL の採番規約。本 ADR はその「proactive TPL は Issue が無いことが多いので DesignDoc PR の番号」という前提を訂正する）, [ADR-8](8-issue-based-doc-numbering.md)（Issue → PR → ローカル採番の優先順位）, `test-perspective` skill, `design-doc` skill, kompiro/karasu#3025 / #3028 / #3029（発見の経緯と karasu 側の同じ規則）

## 背景

ADR-10 は TPL の番号を Issue → PR → ローカル採番の順で決めると定め、理由として
「proactive TPL は Issue が無いことが多いので、それを起こした DesignDoc PR の番号」
と書いた。`test-perspective` skill の 2-1 / 2-3 と `TEMPLATE.md` はこれを受けて、
retrospective は `discovered_from.issue`、proactive は `root_cause_file` /
`root_cause_adr` を持つ、と二者択一に読める形で書いていた。

ところが `design-doc` skill は DesignDoc を Issue から起こす流れを前提にしており、
proactive TPL は DesignDoc と同じ PR で起こされる。つまり proactive TPL にも、ほぼ
常に作業の Issue がある。karasu#3025 では Issue #3022 の DesignDoc で proactive TPL を
`TPL-3022` として起こした（優先順位 1 に従う）が、テンプレートの注記に従って
`issue:` を書かなかった。レビュアーはこれを「起点 Issue の無い TPL」と読み、PR 番号への
採番し直しを求めた。番号は正しく、記録が欠けていた。

## 決定

- 採番の判定基準を 1 つにする: **その TPL を起こした作業に Issue があるか**。起源
  （retrospective / proactive）では分けない。Issue があればその番号を使い、作業に Issue が
  無い、またはその Issue 番号を別の TPL がすでに使っているときだけ PR 番号に進む。
- `discovered_from.issue` は起源の目印ではなく採番の起点とし、起源を問わず先頭に書く。
  proactive TPL はそれに加えて `root_cause_file` / `root_cause_adr` を持ち、proactive か
  どうかはこれらの有無で判定する。
- `design-doc` skill から proactive TPL を起こすときは、DesignDoc の Issue を
  `discovered_from` の先頭に書く。

ADR-10 の優先順位（Issue → PR → ローカル採番）自体は変えない。変えるのは「proactive は
PR 番号に落ちるのが普通」という前提と、それに引きずられた `issue:` の扱い。

## 理由

- skill 自身が「Issue から DesignDoc を起こし、同じ PR で proactive TPL を起こす」流れを
  作っているので、「proactive は Issue が無いことが多い」は skill が想定する運用と合わない。
- `issue:` の有無で起源を表すと、正しく Issue 番号で採番した proactive TPL が
  「番号の根拠が書かれていない記録」に見える。番号の根拠と起源の種別を別のフィールドに
  分ければ、どちらも記録から読み取れる。
- karasu では GitHub 番号ベースへ移行してから起こした TPL はすべて、proactive も含めて
  先頭に Issue を書いており、この決定は実運用に規約を合わせるもの。

## 却下した案

- **proactive TPL は常に DesignDoc PR の番号にする**（ADR-10 の前提を規則に格上げする）:
  却下。Issue → PR の優先順位を起源で分岐させることになり、判定基準が 2 つに増える。
  Issue からの一跳びの追跡性も失う。
- **`issue:` は retrospective のみのまま、proactive は別フィールド（例: `origin_issue:`）で
  Issue を持つ**: 却下。同じ意味のフィールドが 2 つになり、host の validator（
  `@kompiro/tpl-tools` 等）の変更も要る。
