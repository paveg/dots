> Adapted from [anthropics/financial-services](https://github.com/anthropics/financial-services) (Apache License 2.0).
> Modified for retail use without paid data sources.

# Individual Stock Workflow — 5 Phase Template

When the skill is invoked with an individual stock ticker (US or JP), fill this exact template. Keep total output to 100–200 lines.

## Template

````markdown
# {Company Name} ({TICKER}) — Purchase Memo
*Generated: {YYYY-MM-DD} | Last close: {currency}{price} ({30d %} ↑↓)*

> Research summary only — not investment advice.

## 1. What they do

{Two- or three-sentence business description, ≤80 chars per sentence}

| Segment | % of revenue (FY{N}) | YoY growth |
|---|---|---|
| {Seg 1} | {%} | {%} |
| {Seg 2} | {%} | {%} |
| {Seg 3} | {%} | {%} |

Customer concentration: {one line — top customer %, top-5 %, or "not disclosed"}

## 2. Fundamentals (3y trend)

| Metric | FY-2 | FY-1 | FY (TTM) | Comment |
|---|---|---|---|---|
| Revenue ({currency}) | … | … | … | CAGR {%} |
| Gross / Operating / Net margin | … | … | … | {trend} |
| FCF margin | … | … | … | {SBC-adjusted? yes/no} |
| ROIC | … | … | … | {vs WACC} |
| Net debt / EBITDA | … | … | … | {trend} |
| Diluted share count Δ | … | … | … | {SBC dilution rate %} |

## 3. Valuation

**Multiples (vs sector median)**:

| | This | Sector median | Gap |
|---|---|---|---|
| PER (TTM) | … | … | +{%} |
| PSR | … | … | +{%} |
| EV / EBITDA | … | … | +{%} |
| EV / FCF | … | … | +{%} |

**DCF (5y + terminal)** — guardrails per `dcf-rubric.md`:

| Scenario | 売上 CAGR | Terminal g | WACC | Fair value / share |
|---|---|---|---|---|
| Bear | … | … | … | {currency}{value} |
| Base | … | … | … | {currency}{value} |
| Bull | … | … | … | {currency}{value} |

→ Current {currency}{price} is in the **{bear/base/bull}** range. Upside +{%}, downside −{%}.

## 4. Risks

- 💰 **Debt**: {one line — net debt / EBITDA, refinancing schedule, covenants}
- ⚔️ **Competition**: {one line — main rival(s), structural moat trend}
- ⚖️ **Regulation / litigation**: {one line — pending probes, ongoing litigation cited in 10-K Item 3 / 有報 訴訟}
- 📚 **Accounting / disclosure**: {one line — auditor change, restatements, SBC magnitude, working-capital tricks}
- 🎯 **Customer concentration**: {one line — top customer share, single-product dependency}

## 5. Verdict

**Thesis (why buy now)**:
1. {claim grounded in Phase 2 or 3 data}
2. {claim}
3. {claim}

**Invalidation (these would break the thesis)**:
1. {testable KPI — e.g., "Q3 で Data Center YoY が +30% を下回る"}
2. {testable KPI}
3. {testable KPI}

**Verdict**: {Buy / Watch / Pass}
**Suggested sizing**: {Small <2% / Medium 2–5% / Large >5%} of portfolio
**Time horizon**: {6mo / 1–3y / 5y+}

---

深掘りする？
  1. valuation を変数いじって再計算 (WACC / terminal / 売上 CAGR)
  2. risks #N をフィリングから根拠引用つきで再構成
  3. 競合 X 社との指標横並び比較
  4. 直近 3 四半期の earnings call 言及トピック差分
  5. KPI モニタを 5 つに絞り込む
````

## Filling rules

- **Numbers must be sourced.** If a metric can't be pulled from a filing or Yahoo Finance, write `n/a — 数字取得失敗`. Never invent a number.
- **Invalidation KPIs must be testable.** A line like "Macro turns sour" is invalid. A line like "Q3 で Data Center YoY が +30% を下回る" is valid.
- **Thesis claims must reference data in earlier phases.** No claim should rely on information not shown in Phases 1–4.
- **Verdict mapping**:
  - **Buy**: thesis grounded, current price in bear or base range, no Tier-1 risks active
  - **Watch**: thesis interesting but waiting on a catalyst or price → "what specifically would trigger?"
  - **Pass**: thesis weak, valuation in bull range, or ≥1 unmitigated Tier-1 risk
