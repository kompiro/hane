# ADR / Design Doc の言語・運用ルール

- `docs/adr/` の ADR は **日本語**で書く（タイトル・本文とも）。`docs/design/` の Design Doc・`skills/<name>/SKILL.md` の skill body と揃える。`README.md` / `CHANGELOG.md` / Issue / PR / commit subject は引き続き英語（`CLAUDE.md`「Issue・PR 記述ルール」）。
- Design Doc を ADR に昇格させるときは、Design Doc の内容を ADR に集約し、**同じ PR で `docs/design/` の元ファイルを削除する**。「ステータスを決定済みに更新してリンクだけ残す」運用はしない（記録を一本化し、肥大化を避けるため）。
- ADR / AT / TPL のファイル名は GitHub 番号ベース（`<番号>-<slug>.md`、見出しの番号もそれ、ゼロ埋めなし）。優先順位は紐付く Issue 番号 → PR 番号 → ローカル採番（既存最大 +1）。詳細は [ADR-8](../../docs/adr/8-issue-based-doc-numbering.md) と [ADR-10](../../docs/adr/10-tpl-integration-into-skills.md)。host repo が独自規約を持つ場合はそちらを優先する。
