---
name: ipo-decision
description: |
  Generate an IPO subscription-decision memo (抽選参加判断) for a Japanese pre-listing IPO.
  Walks 5 phases — business, fundamentals, supply/demand, risks, verdict — where supply/demand is the protagonist.
  Use when (1) the user asks "このIPO参加すべき？", (2) names an upcoming JP IPO / its ticker, (3) pastes a 目論見書 / 有価証券届出書 URL. v1 = JP pre-listing only (US S-1 / just-listed / pre-IPO unlisted are out of scope).
argument-hint: <会社名 or コード or 目論見書URL> [extra context]
---

# `ipo-decision` skill

Produces a JP pre-listing IPO subscription-decision memo. Sibling of `equity-decision`;
for IPOs the analysis centers on **supply/demand (需給)**, not DCF.

> ⚠️ Not investment advice. Research summary from the 目論見書 and public data. Verify before subscribing.

## Scope (v1)
JP pre-listing IPO, subscription decision only. Out of scope: US/S-1, post-listing
(初値後), pre-IPO unlisted/secondary. If asked for those, say so and offer the closest path.

## Inputs
| Form | Example | Routing |
|---|---|---|
| 会社名 | `GO` `キオクシア` | `fetch_edinet.py --ipo "<name>"` → 届出書 docID |
| 新コード | `581A` | use as name hint; confirm filer via `--ipo` |
| URL | 目論見書/届出書 URL | read it directly; skip the lookup |

## Workflow
1. Locate the filing: `uv run ../equity-decision/scripts/fetch_edinet.py --ipo "<filerName>"`
   → pick the latest 030 (有価証券届出書) and any 040 (訂正). Open the `?type=2` PDF URL to read 業績・公募/売出株数・大株主・手取金の使途. If lookup fails, ask the user for the 目論見書 URL (do not abort).
2. Risk/audit text: `uv run ../equity-decision/scripts/fetch_edinet.py --sections <docID>` (works on the 届出書 XBRL too).
3. Offering terms not in the 届出書 (仮条件/公開価格/吸収額/ロックアップ詳細/OA): source from web with citation; if unavailable, write `数字取得失敗` and request the 目論見書.
4. Comps: `uv run ../equity-decision/scripts/fetch_yahoo.py <類似上場コード>` for relative valuation of the offer price.
5. Read `references/ipo-workflow.md`; fill the 5-phase template.
6. Apply `references/ipo-supply-demand-rubric.md` for the demand level.
7. Emit the memo, then the deep-dive menu.

## Fail-loud rules
- No hallucinated numbers. Unsourceable → `数字取得失敗`.
- 仮条件/公開価格 未確定 → write **未定**; recompute once fixed. Never invent the price.
- **No predicted initial price.** Direction only (公募割れ警戒 / 中立 / プレミアム期待).
- 吸収金額 = (公募+売出+OA)株 × 公開価格上限 — show the formula, never a guessed lump sum.
- Inherit the Yahoo distortion correction from `equity-decision/SKILL.md` when using comps (prefer IR actuals over Yahoo `operatingIncome`; mark adopted vs Yahoo).

## Disclaimer
Research summaries, not investment advice. Verify against the 目論見書 before subscribing.
