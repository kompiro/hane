---
type: tool
---

# AT-59: GitHub issue templates for the public OSS release

- **日付**: 2026-07-11
- **Issue**: #59
- **PR**: なし
- **関連ADR**: ADR-63（着手前の過去決定確認）
- **Related TPLs**: なし（hane は `docs/test-perspectives/` を採用しないため）
- **対象**: `.github/ISSUE_TEMPLATE/bug_report.yml`, `.github/ISSUE_TEMPLATE/feature_request.yml`, `.github/ISSUE_TEMPLATE/new_skill_proposal.yml`, `.github/ISSUE_TEMPLATE/config.yml`

## 概要

外部からの報告・要望を構造化して受けるため、`.github/ISSUE_TEMPLATE/` に YAML issue
forms（bug / feature / new-skill）と `config.yml` を追加する。

## 受け入れ条件

### AC-1: 3 つの form と config が存在し、YAML として妥当

依存を足さずに検証する。`js-yaml`（Node 同梱プロジェクトなら `npx js-yaml`）が
使えればそれで、無ければ host repo が持つ YAML パーサ（`yq` / `python3 -c 'import yaml'`
等）で各ファイルを 1 度ロードできれば OK。GitHub 側でも push 時に検証される
（決定的な確認は手動確認の「New issue チューザ」）。

```bash
for f in bug_report feature_request new_skill_proposal config; do
  test -f ".github/ISSUE_TEMPLATE/$f.yml" && echo "OK: $f.yml exists" || echo "MISSING: $f.yml"
done
# 妥当性: 利用可能な YAML パーサでロードする（いずれか）
for f in .github/ISSUE_TEMPLATE/*.yml; do
  npx --yes js-yaml "$f" >/dev/null 2>&1 && echo "OK: valid $f" || echo "CHECK (parser unavailable): $f"
done
```

- [ ] 4 ファイルが存在し、YAML パーサでロードできる（または GitHub 上でエラー表示が出ない）

### AC-2: form が必須メタ（name/description/body）を持ち、既存ラベルのみ参照する

依存なしの構造チェック（GitHub の label に存在する `bug` / `enhancement` のみ使用）。

```bash
for f in bug_report feature_request new_skill_proposal; do
  p=".github/ISSUE_TEMPLATE/$f.yml"
  grep -q '^name:' "$p"        && echo "OK: $f has name"
  grep -q '^description:' "$p" && echo "OK: $f has description"
  grep -q '^body:' "$p"        && echo "OK: $f has body"
done
# 参照ラベルが既存ラベル（bug / enhancement）だけであること
labels=$(grep -h '^labels:' .github/ISSUE_TEMPLATE/*.yml | grep -oE '"[^"]+"' | tr -d '"' | sort -u)
echo "$labels" | grep -qvE '^(bug|enhancement)$' && echo "FAIL: unknown label -> $labels" || echo "OK: only known labels ($labels)"
```

- [ ] すべて `OK:` を出力し、`FAIL:` が出ない

### AC-3: bug form が host-repo コンテキストを、new-skill form が採用判断材料を拾う

```bash
grep -q 'Host-repo context' .github/ISSUE_TEMPLATE/bug_report.yml && echo "OK: bug captures host context"
grep -qi 'Which skill' .github/ISSUE_TEMPLATE/bug_report.yml && echo "OK: bug asks which skill"
grep -qi 'Trigger phrases' .github/ISSUE_TEMPLATE/new_skill_proposal.yml && echo "OK: new-skill asks triggers"
grep -qi 'Overlap with existing' .github/ISSUE_TEMPLATE/new_skill_proposal.yml && echo "OK: new-skill asks overlap"
```

- [ ] 上記コマンドがすべて `OK:` を出力する

### AC-4: config が blank issue を無効化し、README / SECURITY へ誘導する

```bash
grep -q 'blank_issues_enabled: false' .github/ISSUE_TEMPLATE/config.yml && echo "OK: blank issues disabled"
grep -q 'SECURITY.md' .github/ISSUE_TEMPLATE/config.yml && echo "OK: routes security reports"
grep -q 'README.md' .github/ISSUE_TEMPLATE/config.yml && echo "OK: routes questions"
```

- [ ] 上記コマンドがすべて `OK:` を出力する

## 手動確認

- [ ] リポジトリの "New issue" チューザに 3 テンプレートが並び、security / question の contact link が表示される（GitHub 上で目視）
