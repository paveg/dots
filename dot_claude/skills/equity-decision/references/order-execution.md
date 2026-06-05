# Order execution plan (on request)

Turn a Phase 5 Verdict + Phase 3 valuation into a concrete, rule-based buy plan: limit prices, validity dates, share counts, % of buying power, and exit rules. Produce this **only when the user asks** ("how would I actually buy", "発注", "注文の入れ方", "自分ならどう買う", "指値いくら").

> Research summary, not investment advice. The user sets the budget and places the orders.

## Inputs you need (ask if missing)

1. **Position/theme budget `B`** — the single number the user decides. If they don't give one, propose a default and state the rationale (e.g. cap a thematic/aggressive sleeve at 5–8% of total assets when the portfolio is already concentrated in that theme; never auto-pick a number silently — see `design-decision-visibility`). Show the plan parameterized by `B` and a worked example.
2. **上限価格 (do-not-exceed)** = the Base-case fair value from Phase 3 DCF. Never plan a buy above intrinsic value.
3. **Tranche price levels** from Phase 3 scenarios:
   - T1 (打診) ≈ 上限 / Base fair value
   - T2 (本玉) ≈ midway between Base and Bear
   - T3 (追加) ≈ Bear fair value
4. **Per-name invalidation** = the testable KPIs from Phase 5 (used as fundamental stops).

## Hard rules (no exceptions)

1. **Never buy above 上限価格.** No market (成行) buys above intrinsic value — limit orders or price alerts only.
2. **Per-name cap**: one name ≤ ~35% of `B` (theme stays diversified).
3. **Always scale in 3 tranches** — default split T1 35% / T2 40% / T3 25%. No lump-sum.
4. **Time-space the tranches**: after a tranche fills, wait ≥ ~2 weeks before the next (avoid averaging into one spike).
5. **Validity dates**: every limit/alert has an expiry. If it doesn't fill by the date, **do not chase** — re-evaluate at the next earnings. Suggested: near-term tranche end-of-quarter; deep tranche end-of-year.
6. **Sleeve cap**: when cumulative theme cost hits the user's total-assets cap %, stop new entries.

## Order mechanics

### JP (单元 = 100 shares)
- **Check the 単元 cost first**: price × 100. Many quality names cost ¥0.5M–2.7M per 単元 — too big for a satellite. State this explicitly.
- If the 単元 exceeds the per-name budget → use **単元未満株** (SBI = S株 / 楽天 = かぶミニ) to size in ¥, not in 100-share blocks.
- **単元未満株 caveat**: usually no true 指値 (executed 成行 at next session's open; some brokers offer limited real-time). So for fractional, the "limit" is implemented as a **price alert → manual 成行 when touched**. Say so; don't promise a 指値 that the venue can't place.
- True 指値 / 逆指値 (auto stop-loss) only work on full 単元. Use 逆指値 for stops only when buying 単元.

### US
- Fractional shares + GTC limit orders are broadly available; stop-limit for exits.

## Sizing output

For each tranche express: **指値 (price) / 株数 (share count) / 金額 (¥ or $) / % of B / 期限 (validity)**. Round share counts to whole 単元未満株. Verify the tranche sum ≈ the per-name budget.

## Exit rules (set at entry)

- **Price stop**: high-volatility / leveraged names −20% from average cost; lower-beta "core" names −15%. Auto via 逆指値 on 単元; alert + manual on 単元未満株.
- **Fundamental stop**: each Phase 5 invalidation KPI — if any triggers, cut regardless of price.
- **Theme stop (top priority)**: tie to the leading indicator (e.g. for semis, the sign of the first derivative of contract ASP — same signal as the `memory-watch` skill). On a negative turn, halve the thematic sleeve. Do not move on news or price targets alone.

## Tax / account (JP)

- Put **loss-harvestable / aggressive** positions in 特定口座 (NISA can't offset losses, which breaks 損出し).
- Put **long-term core** positions in NISA 成長枠 (tax-free, holding for years).
- If funding from a 損出し sale, keep buy + realized loss in the same 特定口座 / same tax year.

## Output format

Group order tickets by timing so the user sees what acts now vs waits:

```
### 今すぐ（即日/今週）        ← only names already at/below 上限
| 銘柄 | 注文(指値/成行) | 株数 | 金額 | B% | 期限 |

### 押し目指値（〜Q末）         ← alerts for names above fair value
| 銘柄 | 指値 | 株数 | 金額 | B% |

### 深押し（〜年末、来たら拾う） ← Bear-case levels
| 銘柄 | 指値 | 株数 | 金額 | B% |
```

Then a **capital deployment schedule** (how much ¥ is committed now vs if all tranches fill) and the **exit rules** block. Close with the honest line: tranches that never fill = "too expensive, didn't buy" = a correct outcome, not a miss.
