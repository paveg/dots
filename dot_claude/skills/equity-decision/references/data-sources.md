> Adapted from [anthropics/financial-services](https://github.com/anthropics/financial-services) (Apache License 2.0).
> Modified for retail use without paid data sources.

# Data Sources

Free, retail-accessible sources used by the skill. Each source includes the URL pattern, what's available, and known limits.

## US Equities

### SEC EDGAR

- **Company ticker → CIK map** (one-time fetch, cache yearly):
  `GET https://www.sec.gov/files/company_tickers.json`
- **Latest filings index**: `GET https://data.sec.gov/submissions/CIK{cik_10digit}.json`
- **Filing body**: assembled from the recent filings index (returns `accessionNumber`, `primaryDocument`):
  `GET https://www.sec.gov/Archives/edgar/data/{cik}/{accession_no_dashes}/{primary_document}`
- **User-Agent required**: SEC blocks requests without a UA. Use `User-Agent: <name> <email>`.
- **Rate limit**: 10 requests/second across all SEC endpoints.

Key forms:

- `10-K`: annual report → Phase 1 (Item 1, 1A), Phase 4 (Item 1A, 3, 9A)
- `10-Q`: quarterly → updated balance sheet for Phase 2
- `8-K`: material events → check for Item 4.02 (restatements), Item 5.02 (auditor change)
- `DEF 14A`: proxy → SBC and dilution details

### Yahoo Finance (via `yfinance`)

- Quote, summary, key statistics (PE, PSR, market cap, beta).
- Historical price (5-year daily for `30d %` and CAGR calculations).
- Quarterly and annual income statement, balance sheet, cash flow.
- **Rate limit**: undocumented; treat as soft. Add 1s sleep between calls.
- **Reliability**: API breaks occasionally. Use Stooq as fallback (Phase D).

## JP Equities

### EDINET — deferred to v1.1

- **Status (2026-05)**: EDINET v2 now requires a `Subscription-Key` header. Free key obtainable from <https://disclosure2.edinet-fsa.go.jp/>.
- v1 of this skill does NOT auto-fetch EDINET. For JP 有報 / 短信, paste the URL or PDF text alongside the ticker.
- Once a key is configured (planned v1.1):
  - **Document list** (per date): `GET https://disclosure.edinet-fsa.go.jp/api/v2/documents.json?date=YYYY-MM-DD&type=2`
  - **Document body** (PDF or XBRL): `GET https://disclosure.edinet-fsa.go.jp/api/v2/documents/{docID}?type=2`
  - Filter by `docTypeCode`: `120` 有価証券報告書 / `140` 四半期報告書 / `160` 半期報告書
  - 4-digit securities code → `edinetCode` resolution: use the document listing's `secCode` field (4-digit ticker + trailing `0`)

### TDnet (適時開示)

- Per-day index HTML: `https://www.release.tdnet.info/inbs/I_list_001_{YYYYMMDD}.html`
- Use for 8-K-equivalent events (短信 release, M&A announcement, guidance revisions).
- **Scraping** — fragile. Treat as best-effort.

### Yahoo Finance Japan (via `yfinance`)

- Tickers as `{code}.T` (e.g., `7203.T` for Toyota).
- Same surface as US; slightly fewer historical data points.

## Industry medians

### NYU Damodaran

- Annual update; CSV download URLs (cache for one year):
  - `https://pages.stern.nyu.edu/~adamodar/New_Home_Page/datafile/pedata.html` (PE by sector)
  - `https://pages.stern.nyu.edu/~adamodar/New_Home_Page/datafile/wacc.html` (WACC by sector)
  - `https://pages.stern.nyu.edu/~adamodar/New_Home_Page/datafile/Betas.html` (betas)
- For JP equities, use US sector as proxy unless Damodaran's `globalEquity` table covers the sector explicitly.

## Cache

- All sources cached at `~/.cache/equity-decision/{source}-{ticker}-{YYYY-MM-DD}.json`
- TTL 24h for prices and recent filings; 1 year for Damodaran tables.
- `--no-cache` flag forces refetch.

## Failure behaviour

- Network error → 1 retry → write "数字取得失敗 — manual entry required" in the memo. Never hallucinate.
- Symbol resolution fails → state which lookup failed (e.g., "EDGAR ticker→CIK miss for XYZ").
- HTTP 429 → exponential backoff (2s, 4s, 8s) up to 3 attempts.
