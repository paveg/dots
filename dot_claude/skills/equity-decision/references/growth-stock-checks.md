> Adapted from [anthropics/financial-services](https://github.com/anthropics/financial-services) (Apache License 2.0).
> Modified for retail use without paid data sources.

# Growth Stock Checks

Extra checks to run during Phase 2 (Fundamentals) when the company is high-growth (revenue CAGR > 20%) or tech / SaaS. Surface findings in the **Comment** column of the Fundamentals table or in Phase 4 Risks.

## SBC (Stock-Based Compensation)

- Compute **SBC / Revenue** and **SBC / FCF** for each of the last 3 years.
- **Yellow flag**: SBC > 10% of revenue OR SBC > 50% of GAAP net income.
- **Red flag**: SBC > 20% of revenue OR FCF goes negative when SBC is subtracted.
- Always show **FCF − SBC** (the "real" cash flow to shareholders) in the memo alongside reported FCF.

## Dilution

- Compute **YoY growth in diluted share count**.
- **Yellow flag**: >3% per year.
- **Red flag**: >5% per year, or buybacks barely offsetting SBC.

## Rule of 40 (SaaS)

For SaaS or recurring-revenue businesses: **Revenue growth % + FCF margin % ≥ 40**.

- Above 40 → healthy. Above 60 → exceptional.
- Below 40 → either growth or profitability needs to improve.

## NRR (Net Revenue Retention)

If disclosed (most SaaS companies report it):

- **<100%**: churn problem.
- **100–110%**: stable.
- **110–130%**: healthy land-and-expand.
- **>130%**: best in class.

## TAM Reality Check

When the company quotes a TAM:

- Is the TAM defined per-product or per-market-vertical? (Per-product is more credible.)
- What's the **current penetration** (revenue / TAM)? At <5%, runway is real. At >25%, growth is decelerating soon.
- Cross-check TAM against an independent estimate (e.g., a sector analyst report).

## Working Capital Tricks

Watch for revenue growth that doesn't translate to FCF:

- DSO (Days Sales Outstanding) climbing year over year → channel stuffing or quality of revenue declining.
- Inventory turns falling → product not selling through.
- Deferred revenue declining despite reported growth → real growth slowing.
