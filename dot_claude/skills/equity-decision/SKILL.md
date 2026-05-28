---
name: equity-decision
description: |
  Generate a 1-page purchase memo for a US or JP individual stock (ETF support in v1.1).
  Walks 5 phases — business, fundamentals, valuation, risks, verdict — and ends with deep-dive options.
  Use when (1) the user asks "should I buy <TICKER>?", (2) the user wants a fundamental review of a specific company, (3) the user pastes a 10-K / 有報 / IR URL and asks for an analysis. Skip for ETF / index / dividend-focused questions in v1.
argument-hint: <TICKER or URL> [extra context]
---

# `equity-decision` skill

Produces a structured purchase memo for an individual stock (US or JP). Adapted from [anthropics/financial-services](https://github.com/anthropics/financial-services) (Apache 2.0); modified for retail use without paid data sources.

> ⚠️ **Not investment advice.** Outputs are research summaries based on public filings and market data. Verify numbers against primary sources; the final decision is the user's.

## Inputs

| Form | Example | Routing |
|---|---|---|
| US ticker | `NVDA`, `AAPL` | `^[A-Z]{1,5}$` → EDGAR + Yahoo Finance |
| JP code | `7203`, `9984` | `^\d{4}$` → EDINET + Yahoo Finance (Japan) |
| URL | `https://www.sec.gov/.../10-K.htm` | Read page; infer symbol; route per above |
| Mixed | `NVDA "DC growth slowing"` | Use the extra string as a hypothesis to test in Phase 5 |
| Flag | `--ja 9434` | Force JP routing for ambiguous 4-digit |
| Flag | `--no-cache NVDA` | Skip 24h cache, refetch |

## Output

A single markdown memo of 100–200 lines, matching `references/equity-workflow.md` exactly. After the memo, always append:

```
深掘りする？
  1. valuation を変数いじって再計算 (WACC / terminal / 売上 CAGR)
  2. risks #N をフィリングから根拠引用つきで再構成
  3. 競合 X 社との指標横並び比較
  4. 直近 3 四半期の earnings call 言及トピック差分
  5. KPI モニタを 5 つに絞り込む
```

## Workflow

1. Detect market from ticker (see Inputs).
2. Read `references/equity-workflow.md` to load the 5-phase template.
3. Run the fetchers in `scripts/` (Phase B+ only). For Phase A: ask the user for numbers, or have them paste a 10-K URL.
4. Fill the memo template phase-by-phase. **If a number cannot be fetched or sourced, write "数字取得失敗 — manual entry required" — never make up a number.**
5. Apply rubrics from `references/dcf-rubric.md`, `references/growth-stock-checks.md`, `references/risk-taxonomy.md`.
6. Emit the memo, then the deep-dive menu.

## Fail-loud rules

- No hallucinated revenue / margin / multiples. If you can't source it, write "数字取得失敗".
- No "approximately" or "around" numbers without citing the source filing.
- DCF inputs (WACC, terminal growth) must be inside `references/dcf-rubric.md` guardrails or explicitly flagged.

## Disclaimer

This skill produces research summaries, not investment advice. Verify all numbers against primary filings before acting.
