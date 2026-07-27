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

| Form      | Example                            | Routing                                                 |
| --------- | ---------------------------------- | ------------------------------------------------------- |
| US ticker | `NVDA`, `AAPL`                     | `^[A-Z]{1,5}$` → EDGAR + Yahoo Finance                  |
| JP code   | `7203`, `9984`                     | `^\d{4}$` → EDINET + Yahoo Finance (Japan)              |
| URL       | `https://www.sec.gov/.../10-K.htm` | Read page; infer symbol; route per above                |
| Mixed     | `NVDA "DC growth slowing"`         | Use the extra string as a hypothesis to test in Phase 5 |
| Flag      | `--ja 9434`                        | Force JP routing for ambiguous 4-digit                  |
| Flag      | `--no-cache NVDA`                  | Skip 24h cache, refetch                                 |

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
7. **Only if the user asks for an execution / order plan** ("発注", "注文の入れ方", "自分ならどう買う", "指値いくら"): read `references/order-execution.md` and produce a rule-based buy plan (指値 / 期限 / 株数 / 余力% / 撤退), grounded on the Phase 3 fair-value bands and Phase 5 invalidation KPIs.

## Data fetchers

Run these from `~/.claude/skills/equity-decision/scripts/` via `uv run`:

| When                          | Command                                             | Returns                                                                                           |
| ----------------------------- | --------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| US ticker → price + multiples | `uv run scripts/fetch_yahoo.py NVDA`                | quote, PE/PSR, market cap, TTM revenue/FCF                                                        |
| US ticker → recent filings    | `uv run scripts/fetch_edgar.py NVDA`                | latest 10-K, 10-Q, 5 × 8-K (with URLs)                                                            |
| JP ticker → price + multiples | `uv run scripts/fetch_yahoo.py 7203`                | same shape, auto `.T` suffix                                                                      |
| JP code → EDINET filings      | `uv run scripts/fetch_edinet.py 7203`               | latest 有報 + 半期報告書 (with URLs)                                                              |
| JP 有報本文 → 訴訟・監査      | `uv run scripts/fetch_edinet.py --sections {docID}` | `sections.audit`（監査の状況本文）+ `sections.litigation.matches`（訴訟/係争/損害賠償スニペット） |

Each script outputs JSON to stdout. On failure, exit code is non-zero and stderr contains `数字取得失敗: ...` — propagate that text into the memo, do not invent numbers.

`fetch_edinet.py` needs a Subscription-Key. Set `EDINET_SUBSCRIPTION_KEY`, or store it in 1Password at `op://Personal/EDINET/credential` (override path via `EDINET_OP_REF`).

## JP fallback when EDINET is unavailable

> EDINET が通る場合: まず `fetch_edinet.py {code}` で有報 docID を取得し、続けて `fetch_edinet.py --sections {docID}` で Phase 4 の ⚖️訴訟・📚監査 を一次情報から埋める（Phase 4 の手動補完は不要）。

EDINET API is occasionally down, key activation can be delayed, and the portal has had outages. When `fetch_edinet.py` exits non-zero for a JP ticker:

1. **Do NOT abort the memo.** Continue with Phase 2/3/5 using `fetch_yahoo.py {code}` only (it auto-suffixes `.T` and covers price + PE/PSR + market cap + TTM revenue / operating income / FCF).
2. In Phase 1 (segment breakdown) and Phase 4 (filings-sourced risks), write `数字取得失敗 — EDINET unavailable. Paste 有報 / 短信 URL to enable.` Then ask the user: _「有報か短信の URL があれば貼ってください。なければこのまま Yahoo の数字で進めます」_
3. If the user pastes a URL or PDF, fetch / read it and fill in Phase 1 + 4 from there.
4. The Verdict (Phase 5) can still ground itself on Phase 2 / 3 alone; flag the missing filings context in the Invalidation list.

This keeps JP coverage usable even when EDINET is offline.

## Fail-loud rules

- No hallucinated revenue / margin / multiples. If you can't source it, write "数字取得失敗".
- No "approximately" or "around" numbers without citing the source filing.
- DCF inputs (WACC, terminal growth) must be inside `references/dcf-rubric.md` guardrails or explicitly flagged.

### Yahoo distortion correction (JP especially)

`fetch_yahoo.py` is reliable for **price / marketCap / PER (when profitable) / PSR / beta**, but the following are frequently wrong — cross-check against IR BANK / 決算短信 actuals and **state which you adopted**:

- **`operatingIncome_ttm` (JP)** is often off by a large margin (wrong period, non-consolidated, or stale). Always prefer the company's disclosed 営業利益 (IR BANK `/results`, 決算短信). If Yahoo and the filing diverge, adopt the filing and note "Yahoo営業益は不採用".
- **PER when the company is loss-making / took an impairment** is a meaningless headline (it ignores the forward loss or is inflated by a one-off). Mark it `*` and read off forward/core earnings instead.
- **`revenue_ttm`** can be understated/lagged for some JP tickers, which then **distorts PSR**. If revenue conflicts with the latest 通期 actual, recompute PSR on the filing revenue and flag it (`※`).
- **Wrong quote / ambiguous ticker**: if price × shares ≠ marketCap, or a `.O`/foreign quote is returned instead of `.T`, the quote is suspect — verify via 日経 / IR BANK before using.
- When a value is corrected, show both (Yahoo vs adopted) so the reader can audit. Never silently pass a known-bad Yahoo figure into the memo.

## Disclaimer

This skill produces research summaries, not investment advice. Verify all numbers against primary filings before acting.
