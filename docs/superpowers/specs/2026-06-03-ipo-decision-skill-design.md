# ipo-decision skill — Design (v1)

Date: 2026-06-03
Status: Approved (design), pending spec review → writing-plans

## Purpose

A sibling to the `equity-decision` skill that produces a structured **IPO subscription-decision memo** (抽選参加判断) for Japanese pre-listing IPOs. The existing `equity-decision` skill assumes a listed stock (market price via Yahoo, 有報 via EDINET) and cannot handle pre-IPO names. IPO analysis has a different center of gravity: **supply/demand (需給) is the protagonist, not DCF**.

Proven by ad-hoc precedent in the `stock` repo: `581A GO`（抽選参加判断・全株売出・吸収¥971億・公募割れ警戒・ロックアップ明け後）and `SPCX`（pre-IPO飛びつき非推奨）. This skill productizes that pattern.

> Research summary, not investment advice. Verify against the 目論見書; the decision is the user's.

## Scope (v1)

- **In**: JP, pre-listing IPO, subscription decision (上場前・抽選参加判断).
- **Out (future)**: US IPO (S-1), just-listed (初値後のホールド/初値売り判断), pre-IPO unlisted/secondary (SPCX type).
- Triggers: 「このIPO参加すべき？」「<会社/コード> 目論見書」「上場予定の<銘柄>を調べて」.

## Three settled framework decisions

1. **Stage** = pre-listing subscription decision only.
2. **Data sourcing** = hybrid: EDINET 有価証券届出書 (auto) + web for late/demand items + `fetch_yahoo.py` for listed comps. If a demand item can't be sourced, write 数字取得失敗 and request the 目論見書 URL.
3. **Initial-price (初値)** = directional only. Output a 公募割れ警戒 / 中立 / プレミアム期待 risk level. **Never output a predicted initial price** (fail-loud).

## File structure (mirrors equity-decision)

```
dot_claude/skills/ipo-decision/
  SKILL.md                              # routing, workflow, fail-loud
  references/ipo-workflow.md            # 5-phase IPO memo template
  references/ipo-supply-demand-rubric.md# 需給スコア thresholds (IPO analogue of dcf-rubric)
  # reused from equity-decision (do NOT duplicate; reference by path or copy minimal):
  #   scripts/fetch_yahoo.py   — listed comps multiples
  #   scripts/fetch_edinet.py  — EXTENDED to fetch 有価証券届出書/訂正届出書
```

Decision for plan stage: whether `ipo-decision` reuses `equity-decision/scripts/` in place (shared path) or ships its own copy. Prefer shared/extended `fetch_edinet.py` to avoid divergence.

## Data fetchers

- **Extend `fetch_edinet.py`**: add support for fetching **有価証券届出書 (securities registration statement)** and **訂正有価証券届出書** doc types (currently it only surfaces 有報=120 / 半期=160). Exact docTypeCode(s) to be confirmed during implementation (有価証券届出書 ≈ 030, 訂正 ≈ 040 — verify against the EDINET docTypeCode list). Optionally a `--sections` mode to extract 株式の状況 (公募/売出), 大株主, 手取金の使途, 事業等のリスク, 監査.
- **Web 補完**: 仮条件・公開価格・吸収額・ロックアップ詳細・オーバーアロットメント — these often appear only in the 訂正届出書/目論見書 issued later, or on IPO sites. Source with citation; if unavailable, 数字取得失敗 + request URL.
- **`fetch_yahoo.py` (reuse)**: pull listed comparables' PER/PSR/EV-multiples for relative pricing of the IPO offer price.

## 5-phase memo template (`ipo-workflow.md`)

Header: `会社名 (コード) — IPO抽選参加メモ` / 上場予定日, 市場区分(グロース/スタンダード/プライム), 仮条件 or 想定発行価格.

1. **事業** — what they do, business model, growth stage (黒字/赤字・成長率) — ≤3 sentences + revenue mix.
2. **業績（目論見書）** — 3期 売上/営業益/純益/成長率, 黒字化有無, **繰越欠損金 (tax shield)**, 自己資本/ROE.
3. **需給（IPO固有・最重要）**:
   - 公募株数 / 売出株数 / オーバーアロットメント → **吸収金額 = 公開株数 × 公開価格上限 + OA（式を明示）**
   - 売出比率 (既存株主の換金) vs 公募 (成長投資)
   - 親会社 / VC / 創業者の放出規模と残存保有
   - ロックアップ (期間 / 解除価格条件 / 対象株主 / %)
   - 需給スコア (apply rubric) → 公募割れ警戒 / 中立 / プレミアム期待
   - 想定 PER/PSR vs 類似上場企業 (fetch_yahoo comps)
4. **リスク** — 目論見書「事業等のリスク」要点, 監査法人・継続性, 親会社/特定顧客依存, 規制, **ロックアップ解除後の時間差需給悪化**.
5. **判断** — 需給 × バリュエーション × 成長の総合 →
   - **積極参加 / 小ロット参加 / 初値売り前提で参加 / 見送り**
   - ロット戦略、初値後にホールドするなら条件、Invalidation KPI。

Append an IPO deep-dive menu (需給再計算 / ロックアップ解除スケジュール / 類似IPOの初値騰落比較 / 類似上場企業バリュエーション横並び / KPIモニタ).

## Supply/demand rubric (`ipo-supply-demand-rubric.md`)

Threshold-based scoring (the IPO analogue of `dcf-rubric.md`):
- 吸収額: 小型 (<¥100億)=需給良 / 中型 (¥100–500億)=中立 / 大型 (>¥500億)=需給重
- 売出比率: 高 (既存株主の換金主体)=ネガ
- 親会社/VC/創業者の放出: 全株売出=強ネガ; 残存保有大+ロックアップ=ポジ
- ロックアップ: 期間 (90/180日) と解除価格条件 (例 1.5倍) の有無
- オーバーアロットメント / グリーンシューオプションの規模
- 公開価格の対類似企業ディスカウント有無 (割安設定=初値プレミアム期待)
→ Combine into a directional 公募割れリスクレベル. Document is guidance, not a hard formula; the memo states which factors drove the level.

## IPO-specific fail-loud rules

- 仮条件未確定なら「未定」と明記し、確定後に再計算 (do not fabricate a price).
- **初値予想株価は出さない** — direction/risk level only (settled decision 3).
- 吸収額は式を見せて計算 (公開株数 × 公開価格上限 + OA); never a guessed lump number.
- Inherit equity-decision fail-loud: no hallucinated numbers, source everything, 数字取得失敗 when unsourceable, Yahoo distortion correction for comps.

## Out of scope / YAGNI (v1)

- No initial-price point prediction.
- No US/S-1 support.
- No post-listing or pre-IPO-secondary modes.
- No automated 仮条件/初値 scraping beyond cited web lookup.

## Open items for the implementation plan

1. Confirm EDINET docTypeCode(s) for 有価証券届出書 / 訂正届出書 and implement the fetch + (optional) `--sections` extraction.
2. Decide script reuse vs copy between `equity-decision` and `ipo-decision`.
3. Author `ipo-workflow.md` and `ipo-supply-demand-rubric.md`.
4. Author `SKILL.md` (routing regex, workflow steps, fail-loud, disclaimer).
5. Verify end-to-end on a real upcoming JP IPO (or re-run 581A as a regression of the pattern).
6. Bundle `chezmoi apply` with the pending equity-decision changes (order-execution.md + SKILL.md edits) per the user's earlier decision.
