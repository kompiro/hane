# ADR-58: SECURITY.md を先に整備し、private vulnerability reporting の有効化は公開フリップ後に回す

- **日付**: 2026-07-09
- **ステータス**: 決定済み
- **Issue**: [#58](https://github.com/kompiro/hane/issues/58)
- **関連**: [#61](https://github.com/kompiro/hane/issues/61)（OSS 公開トラッキング）, [ADR-36](36-security-alert-skill.md)（host repo の security alert 対応 skill — レイヤーが異なる）, [ADR-63](63-consult-past-decisions-before-design.md)（着手前の過去決定確認）, karasu ADR-20260624-05（private vulnerability reporting 有効化の先行事例）

## 背景

OSS 公開（#61）の前提として、脆弱性の受け付け方を定める必要がある。当初 #58 は
「`SECURITY.md` の追加」と「private vulnerability reporting（PVR）の有効化」を
1 つの作業として起票していた。

着手前の過去決定確認（ADR-63）で、hane の既存 ADR に衝突する決定は無いことを確認
した（ADR-36 は host repo の Dependabot alert を扱う skill の話で、hane 自身の
セキュリティ方針とはレイヤーが異なる）。

一方、実現可能性の確認で制約が判明した: **GitHub の PVR は public repository 限定**
であり、private な現状の hane では有効化できない（`GET /repos/kompiro/hane/private-vulnerability-reporting`
が 404 を返す）。

hane は skill 本文にシェル手順を持ち、それを host repository 内でエージェントが実行
する。コンパイル済みコードも実行時依存も持たないが、攻撃面は実在する。

## 決定

- **`SECURITY.md` を先に整備する**。報告経路（PVR の advisory フォーム、暫定の
  メール窓口）、supported versions（最新リリースのみ）、coordinated disclosure、
  そして **hane 固有の scope**（skill 本文が host repo で実行される点、hooks、
  marketplace 経由の配布経路、skill が読む外部コンテンツ由来の prompt injection）を
  明記する。
- **PVR の有効化は #61 の公開フリップ直後のチェックリストへ移す**。#58 の scope から
  外し、フリップ手順の一部として実行する。
- 公開前は `SECURITY.md` のメール窓口が実質的な受け口として機能する。

## 理由

- PVR が public 限定である以上、#58 の中で有効化を完了させることは物理的に不可能。
  作業単位を「用意できるもの（方針文書）」と「公開後にしかできないもの（設定）」で
  割ると、#58 を今クローズでき、フリップ手順に取りこぼしなく残せる。
- `SECURITY.md` を先行させることで、フリップした瞬間に受け入れ態勢が整っている状態に
  なる。文書が無いまま public にすると、報告者が公開 Issue に書いてしまう窓が開く。
- scope に hane 固有の攻撃面を明記するのは、「markdown だけの repo だから安全」と
  誤解されないため。skill はエージェントに host repo 内での操作を指示するので、
  誘導可能性そのものが報告対象になる。

## 却下した案

- **いま PVR を有効化する** — 却下。GitHub の PVR は public repository でしか
  有効化できず、private な hane では API が 404 を返す。技術的に実行不可能であり、
  「やろうとして失敗した」記録として残す（将来 #58 を見返した人が同じ試行をしないよう）。
- **公開フリップ（#61）まで `SECURITY.md` の追加ごと待つ** — 却下。文書は private の
  うちに用意できるうえ、フリップ手順を軽くしておく方が、公開直後の取りこぼしリスクが
  小さい。公開と同時に方針が存在している状態が望ましい。
- **`SECURITY.md` を置かず CONTRIBUTING の一節で済ませる** — 却下。GitHub の
  community profile / repository security tab は `SECURITY.md` を特別扱いし、
  「Report a vulnerability」導線を出す。専用ファイルにする実利がある。
