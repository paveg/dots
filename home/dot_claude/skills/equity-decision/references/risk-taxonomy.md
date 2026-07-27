> Adapted from [anthropics/financial-services](https://github.com/anthropics/financial-services) (Apache License 2.0). Modified for retail use without paid data sources.

# Risk Taxonomy — 5 Axes

Phase 4 of `equity-workflow.md` lists 5 risks. For each axis, the memo line states **whether the risk is materially active for this name today**, not generic warnings.

## 1. 💰 Debt

- **Active**: Net debt / EBITDA > 3.0×, OR upcoming refinancing > 20% of debt within 18 months, OR covenant headroom < 20%.
- **Latent**: ratio rising but still < 3.0×.
- **Inactive**: net cash, OR ratio < 1.5× with no near-term refinancing.

Source: 10-K Item 7 (Liquidity), 10-Q balance sheet, 有報「財政状態」.

## 2. ⚔️ Competition

- **Active**: market share losing > 2pp/year, OR a credible new entrant disclosed (e.g., 10-K Item 1A, S-1 of a competitor) in the last 2 years.
- **Latent**: moat narrowing but still dominant (>30% share); pricing power weakening.
- **Inactive**: structural moat, market share stable or growing.

Source: 10-K Item 1 (Business), Item 1A (Risk Factors), industry reports.

## 3. ⚖️ Regulation / Litigation

- **Active**: pending probe by a major regulator (DOJ, FTC, EU, JFTC), OR class action with damages claim > 5% of market cap, OR new rule (announced) that hits ≥10% of revenue.
- **Latent**: industry under increasing scrutiny but no specific action.
- **Inactive**: no disclosed material proceedings; regulation stable.

Source: 10-K Item 3 (Legal Proceedings), 8-K material disclosures, 有報「訴訟事件等の概要」.

## 4. 📚 Accounting / Disclosure

- **Active**: auditor changed in the last 2 years (especially mid-cycle), OR restatement filed (8-K Item 4.02), OR going-concern paragraph, OR repeated material weakness in ICFR.
- **Latent**: SBC > 20% of revenue, OR aggressive revenue recognition (long contracts, capitalized commissions ballooning), OR off-balance-sheet items > 10% of market cap.
- **Inactive**: clean opinion, stable auditor, no flags.

Source: 10-K Item 9A (ICFR), auditor's report, 有報「監査の状況」.

## 5. 🎯 Customer / Product / Geographic Concentration

- **Active**: top customer > 20% of revenue, OR top 3 customers > 50%, OR single product > 60% of revenue, OR single country > 70% with that country under political stress.
- **Latent**: top customer 10–20%, OR single product / country between 50–70%.
- **Inactive**: diversified across all three dimensions.

Source: 10-K Item 1 (Customers), segment notes, 有報「販売の状況」.

## How to write the memo line

For each axis in Phase 4, write a single line in this shape:

```
{emoji} **{Axis}**: {Active/Latent/Inactive} — {specific reason with number}.
```

Examples:

- `💰 **Debt**: Inactive — net cash $24B, no maturities < 24mo.`
- `⚔️ **Competition**: Latent — Nvidia share holding ~80% datacenter GPU, AMD MI300 ramp + Intel Gaudi3 watch.`
- `⚖️ **Regulation**: Active — China export controls on H100/H200 cut DC revenue ~15% in FY24.`
