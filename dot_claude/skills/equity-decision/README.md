# equity-decision

A Claude Code skill that produces a structured purchase memo for an individual stock (US or JP). Adapted from [anthropics/financial-services](https://github.com/anthropics/financial-services) (Apache 2.0); reworked for retail use against free public data.

> Not investment advice. Outputs are research summaries.

## Quick start

```
/equity-decision NVDA                                # US ticker
/equity-decision 7203                                # JP code (Toyota)
/equity-decision NVDA "DC growth slowing"            # ticker + hypothesis
/equity-decision https://www.sec.gov/.../10-K.htm    # URL
/equity-decision --ja 9434                           # Force JP routing
/equity-decision --no-cache NVDA                     # Skip 24h cache
```

The skill emits a 100–200 line memo covering business, fundamentals (3-year trend), valuation (multiples + DCF), risks (5 axes), and a verdict (Buy/Watch/Pass + sizing + horizon). The memo ends with five deep-dive options you can pick from in the next turn.

## What's in scope (v1)

- US individual stocks (10-K / 10-Q / 8-K via SEC EDGAR + Yahoo Finance)
- JP individual stocks via Yahoo Finance Japan (price + multiples). 有報 / 決算短信 are read via manual URL/PDF paste — EDINET API auto-fetch is v1.1.

## What's not in scope (v1)

- ETF / index funds → v1.1
- EDINET API auto-fetch (requires free subscription key from disclosure2.edinet-fsa.go.jp) → v1.1
- Dividend-focused screens (yield + payout ratio + coverage) — different rubric
- Crypto, commodities, individual bonds
- Hong Kong / Shanghai / European listings
- Tax optimization (NISA balance, foreign tax credit) — needs personal account data

## Files

```
SKILL.md                       # skill entry, routing, output rules
references/equity-workflow.md  # the 5-phase template (this is what gets filled)
references/dcf-rubric.md       # WACC / growth / terminal defaults & guardrails
references/growth-stock-checks.md  # SBC, NRR, Rule of 40
references/risk-taxonomy.md    # 5 axes Active/Latent/Inactive scoring
references/data-sources.md     # EDGAR / EDINET / Yahoo / Damodaran query notes
scripts/fetch_yahoo.py         # `uv run scripts/fetch_yahoo.py NVDA`     (US + JP via .T)
scripts/fetch_edgar.py         # `uv run scripts/fetch_edgar.py NVDA`     (US filings)
```

## Smoke-test the fetchers

After Phase B is in:

```bash
cd ~/.claude/skills/equity-decision
uv run scripts/fetch_yahoo.py NVDA  | jq '.summary'
uv run scripts/fetch_yahoo.py 7203  | jq '.summary'   # JP auto-suffix .T
uv run scripts/fetch_edgar.py NVDA  | jq '.filings[0]'
```

Expected: each returns a JSON object with the documented shape (see each script's docstring).
