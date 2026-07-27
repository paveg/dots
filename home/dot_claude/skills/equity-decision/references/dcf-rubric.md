> Adapted from [anthropics/financial-services](https://github.com/anthropics/financial-services) (Apache License 2.0). Modified for retail use without paid data sources.

# DCF Rubric — Defaults and Guardrails

Used by Phase 3 of `equity-workflow.md`. The skill produces a 3-scenario DCF (Bear / Base / Bull); each scenario must respect these guardrails.

## Inputs and defaults

| Input                             | Default                                              | Guardrail                                                     |
| --------------------------------- | ---------------------------------------------------- | ------------------------------------------------------------- |
| Forecast horizon                  | 5 years                                              | Fixed                                                         |
| Revenue CAGR (Bear / Base / Bull) | sector median × {0.5 / 1.0 / 1.5}                    | ±50% around base; cap at 30% even for hyper-growth            |
| Operating margin (steady state)   | average of last 3y                                   | ±5pp from history unless step-change argued                   |
| Tax rate                          | 25% (US) / 30% (JP)                                  | Override only if disclosed effective rate ≠ statutory ≥ 5pp   |
| WACC                              | 8% (US large-cap) / 7% (US tech) / 6% (JP large-cap) | ±2pp; cite source in memo if outside                          |
| Terminal growth                   | 2.5%                                                 | Hard cap 3.5%; never exceed long-term GDP+1                   |
| Net debt                          | from latest 10-Q / 短信                              | Use book value; flag if off-balance-sheet ≥ 10% of market cap |

## Method (skill internal)

1. Build 5-year revenue projection per scenario.
2. Apply operating margin to derive EBIT; subtract tax → NOPAT.
3. Add back D&A, subtract capex and working-capital changes → FCF.
4. Discount each year's FCF at WACC.
5. Terminal value = year-5 FCF × (1+g) / (WACC − g). Discount to PV.
6. Sum → enterprise value. Subtract net debt → equity value. Divide by diluted shares → fair value/share.

## Sanity checks (apply before emitting numbers)

- **Bull < Base × 2.0**: if Bull/Base > 2.0, the bull scenario is unrealistic — tighten growth or margin assumption.
- **Bear > Base × 0.4**: if Bear/Base < 0.4, the base case is fragile — recheck steady-state margin.
- **All scenarios > current price**: usually means consensus is too pessimistic OR assumptions are too aggressive. Flag in the memo.
- **All scenarios < current price**: market is pricing growth/option value the model doesn't capture. Note in Phase 5 Invalidation.

## When to skip DCF

- Companies with negative FCF for ≥3 years and no path to profitability → use rNPV, PSR, or "not valued" with reason.
- Financials (banks / insurers): DCF on FCF is misleading; use dividend discount model or P/TBV instead.
- Holding companies / SOTP candidates: use sum-of-the-parts; DCF would mask segment economics.

If skipping, state which alternative was used and why.
