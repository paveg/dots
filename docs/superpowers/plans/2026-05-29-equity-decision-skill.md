# `equity-decision` Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Claude Code skill `equity-decision` that produces a 1-page purchase memo for a US or JP stock when invoked with a ticker, walking 5 phases (business → fundamentals → valuation → risks → verdict) and ending with deep-dive options.

**Architecture:**

- chezmoi-managed source at `dot_claude/skills/equity-decision/`, deploys to `~/.claude/skills/equity-decision/`
- SKILL.md as entry; phase templates and rubrics in `references/`; data fetchers as PEP 723 standalone Python scripts in `scripts/`
- Adapted from anthropics/financial-services (Apache 2.0) but using only free data (SEC EDGAR, EDINET, Yahoo Finance, NYU Damodaran)
- v1 covers Phase A (skeleton, hand-fill) + Phase B (fetchers, automated). ETF (Phase C) and polish (Phase D) deferred

**Tech Stack:**

- Markdown for skill content (SKILL.md, references)
- Python 3.11+ via `uv run` (PEP 723 inline metadata) — no `devbox add`, no global pip
- Fetcher deps: `yfinance`, `requests`, `beautifulsoup4`
- Test deps: `pytest`, `requests-mock`
- chezmoi for deployment, justfile/devbox for repo lint

---

## Spec reference

[docs/superpowers/specs/2026-05-29-equity-decision-skill-design.md](../specs/2026-05-29-equity-decision-skill-design.md)

## File map

### Created files

```
dot_claude/skills/equity-decision/
├── SKILL.md                          # entry, frontmatter, routing summary
├── README.md                         # user-facing usage examples
├── references/
│   ├── equity-workflow.md            # 5 phase template (individual stock)
│   ├── dcf-rubric.md                 # WACC, growth, terminal value defaults
│   ├── growth-stock-checks.md        # SBC, NRR, Rule-of-40
│   ├── risk-taxonomy.md              # 5 axes Debt/Competition/Regulation/Accounting/Concentration
│   └── data-sources.md               # EDGAR / EDINET / Yahoo / Damodaran queries
└── scripts/
    ├── fetch_yahoo.py                # price + summary metrics via yfinance
    ├── fetch_edgar.py                # latest 10-K / 10-Q from SEC EDGAR
    ├── fetch_edinet.py               # 直近の有価証券報告書 from EDINET
    └── industry_medians.py           # Damodaran industry medians (cached CSV)

tests/skills/equity-decision/
├── conftest.py                       # pytest fixtures: ticker symbols, mock responses
├── test_fetch_yahoo.py
├── test_fetch_edgar.py
├── test_fetch_edinet.py
└── run-tests.sh                      # wrapper: uv run pytest in this dir

docs/superpowers/specs/2026-05-29-equity-decision-skill-design.md  # already exists
docs/superpowers/plans/2026-05-29-equity-decision-skill.md         # this file
```

### Modified files

- `justfile` — add a `test-skills` recipe that runs the pytest harness
- (optional, end) `.github/workflows/ci.yml` if Python lint is desired

---

## Phase A: Skeleton (hand-fill workflow)

End-state: Claude can be invoked as `/equity-decision NVDA`, will hand-fill the 5-phase template using web knowledge + any URL/PDF the user provides, no Python fetchers yet.

### Task 1: Create the SKILL.md entry

**Files:**

- Create: `dot_claude/skills/equity-decision/SKILL.md`

- [ ] **Step 1: Write SKILL.md with frontmatter and routing**

```markdown
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
| Mixed     | `NVDA "DC 売上の頭打ちが気になる"` | Use the extra string as a hypothesis to test in Phase 5 |
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

## Fail-loud rules

- No hallucinated revenue / margin / multiples. If you can't source it, write "数字取得失敗".
- No "approximately" or "around" numbers without citing the source filing.
- DCF inputs (WACC, terminal growth) must be inside `references/dcf-rubric.md` guardrails or explicitly flagged.

## Disclaimer

This skill produces research summaries, not investment advice. Verify all numbers against primary filings before acting.
```

- [ ] **Step 2: Smoke-check the frontmatter parses**

Run:

```bash
python3 -c "
import yaml, sys
with open('/Users/ryota/.local/share/chezmoi/dot_claude/skills/equity-decision/SKILL.md') as f:
    text = f.read()
assert text.startswith('---'), 'missing frontmatter'
fm = text.split('---', 2)[1]
parsed = yaml.safe_load(fm)
assert parsed['name'] == 'equity-decision', f'name mismatch: {parsed}'
assert 'description' in parsed and len(parsed['description']) > 50, 'description too short'
print('OK:', parsed['name'])
"
```

Expected: `OK: equity-decision`

- [ ] **Step 3: Commit**

```bash
cd /Users/ryota/.local/share/chezmoi
git add dot_claude/skills/equity-decision/SKILL.md
git commit -m "feat(skills): scaffold equity-decision SKILL.md"
```

---

### Task 2: Write the individual-stock 5-phase workflow reference

**Files:**

- Create: `dot_claude/skills/equity-decision/references/equity-workflow.md`

- [ ] **Step 1: Write the template**

````markdown
> Adapted from [anthropics/financial-services](https://github.com/anthropics/financial-services) (Apache License 2.0). Modified for retail use without paid data sources.

# Individual Stock Workflow — 5 Phase Template

When the skill is invoked with an individual stock ticker (US or JP), fill this exact template. Keep total output to 100–200 lines.

## Template

```markdown
# {Company Name} ({TICKER}) — Purchase Memo

_Generated: {YYYY-MM-DD} | Last close: {currency}{price} ({30d %} ↑↓)_

> Research summary only — not investment advice.

## 1. What they do

{Two- or three-sentence business description, ≤80 chars per sentence}

| Segment | % of revenue (FY{N}) | YoY growth |
| ------- | -------------------- | ---------- |
| {Seg 1} | {%}                  | {%}        |
| {Seg 2} | {%}                  | {%}        |
| {Seg 3} | {%}                  | {%}        |

Customer concentration: {one line — top customer %, top-5 %, or "not disclosed"}

## 2. Fundamentals (3y trend)

| Metric                         | FY-2 | FY-1 | FY (TTM) | Comment                |
| ------------------------------ | ---- | ---- | -------- | ---------------------- |
| Revenue ({currency})           | …    | …    | …        | CAGR {%}               |
| Gross / Operating / Net margin | …    | …    | …        | {trend}                |
| FCF margin                     | …    | …    | …        | {SBC-adjusted? yes/no} |
| ROIC                           | …    | …    | …        | {vs WACC}              |
| Net debt / EBITDA              | …    | …    | …        | {trend}                |
| Diluted share count Δ          | …    | …    | …        | {SBC dilution rate %}  |

## 3. Valuation

**Multiples (vs sector median)**:

|             | This | Sector median | Gap  |
| ----------- | ---- | ------------- | ---- |
| PER (TTM)   | …    | …             | +{%} |
| PSR         | …    | …             | +{%} |
| EV / EBITDA | …    | …             | +{%} |
| EV / FCF    | …    | …             | +{%} |

**DCF (5y + terminal)** — guardrails per `dcf-rubric.md`:

| Scenario | 売上 CAGR | Terminal g | WACC | Fair value / share |
| -------- | --------- | ---------- | ---- | ------------------ |
| Bear     | …         | …          | …    | {currency}{value}  |
| Base     | …         | …          | …    | {currency}{value}  |
| Bull     | …         | …          | …    | {currency}{value}  |

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

**Verdict**: {Buy / Watch / Pass} **Suggested sizing**: {Small <2% / Medium 2–5% / Large >5%} of portfolio **Time horizon**: {6mo / 1–3y / 5y+}

---

深掘りする？

1. valuation を変数いじって再計算 (WACC / terminal / 売上 CAGR)
2. risks #N をフィリングから根拠引用つきで再構成
3. 競合 X 社との指標横並び比較
4. 直近 3 四半期の earnings call 言及トピック差分
5. KPI モニタを 5 つに絞り込む
```
````

## Filling rules

- **Numbers must be sourced.** If a metric can't be pulled from a filing or Yahoo Finance, write `n/a — 数字取得失敗`. Never invent a number.
- **Invalidation KPIs must be testable.** A line like "Macro turns sour" is invalid. A line like "Q3 で Data Center YoY が +30% を下回る" is valid.
- **Thesis claims must reference data in earlier phases.** No claim should rely on information not shown in Phases 1–4.
- **Verdict mapping**:
  - **Buy**: thesis grounded, current price in bear or base range, no Tier-1 risks active
  - **Watch**: thesis interesting but waiting on a catalyst or price → "what specifically would trigger?"
  - **Pass**: thesis weak, valuation in bull range, or ≥1 unmitigated Tier-1 risk

````

- [ ] **Step 2: Quick lint — check the file is valid markdown with 5 numbered sections**

Run:
```bash
grep -E "^## [1-5]\." /Users/ryota/.local/share/chezmoi/dot_claude/skills/equity-decision/references/equity-workflow.md
````

Expected: 5 lines matching `## 1.` through `## 5.`

- [ ] **Step 3: Commit**

```bash
cd /Users/ryota/.local/share/chezmoi
git add dot_claude/skills/equity-decision/references/equity-workflow.md
git commit -m "feat(skills): equity-decision 5-phase workflow template"
```

---

### Task 3: Write the DCF rubric

**Files:**

- Create: `dot_claude/skills/equity-decision/references/dcf-rubric.md`

- [ ] **Step 1: Write the rubric**

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
cd /Users/ryota/.local/share/chezmoi
git add dot_claude/skills/equity-decision/references/dcf-rubric.md
git commit -m "feat(skills): equity-decision DCF rubric with guardrails"
```

---

### Task 4: Write growth-stock checks

**Files:**

- Create: `dot_claude/skills/equity-decision/references/growth-stock-checks.md`

- [ ] **Step 1: Write the checks file**

```markdown
> Adapted from [anthropics/financial-services](https://github.com/anthropics/financial-services) (Apache License 2.0). Modified for retail use without paid data sources.

# Growth Stock Checks

Extra checks to run during Phase 2 (Fundamentals) when the company is high-growth (revenue CAGR > 20%) or tech / SaaS. Surface findings in the **Comment** column of the Fundamentals table or in Phase 4 Risks.

## SBC (Stock-Based Compensation)

- Compute **SBC / Revenue** and **SBC / FCF** for each of the last 3 years.
- **Yellow flag**: SBC > 10% of revenue OR SBC > 50% of GAAP net income.
- **Red flag**: SBC > 20% of revenue OR FCF goes negative when SBC is subtracted.
- Always show **FCF — SBC** (the "real" cash flow to shareholders) in the memo alongside reported FCF.

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
```

- [ ] **Step 2: Commit**

```bash
cd /Users/ryota/.local/share/chezmoi
git add dot_claude/skills/equity-decision/references/growth-stock-checks.md
git commit -m "feat(skills): equity-decision growth-stock checks reference"
```

---

### Task 5: Write the risk taxonomy

**Files:**

- Create: `dot_claude/skills/equity-decision/references/risk-taxonomy.md`

- [ ] **Step 1: Write the file**

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
cd /Users/ryota/.local/share/chezmoi
git add dot_claude/skills/equity-decision/references/risk-taxonomy.md
git commit -m "feat(skills): equity-decision risk taxonomy reference"
```

---

### Task 6: Write the data-sources reference

**Files:**

- Create: `dot_claude/skills/equity-decision/references/data-sources.md`

- [ ] **Step 1: Write the file**

```markdown
> Adapted from [anthropics/financial-services](https://github.com/anthropics/financial-services) (Apache License 2.0). Modified for retail use without paid data sources.

# Data Sources

Free, retail-accessible sources used by the skill. Each source includes the URL pattern, what's available, and known limits.

## US Equities

### SEC EDGAR

- **Company ticker → CIK map** (one-time fetch, cache yearly): `GET https://www.sec.gov/files/company_tickers.json`
- **Latest filings index**: `GET https://data.sec.gov/submissions/CIK{cik_10digit}.json`
- **Filing body**: assembled from the recent filings index (returns `accessionNumber`, `primaryDocument`): `GET https://www.sec.gov/Archives/edgar/data/{cik}/{accession_no_dashes}/{primary_document}`
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

### EDINET

- **Document list** (per date): `GET https://disclosure.edinet-fsa.go.jp/api/v2/documents.json?date=YYYY-MM-DD&type=2`
- **Document body** (PDF or XBRL): `GET https://disclosure.edinet-fsa.go.jp/api/v2/documents/{docID}?type=2`
- **No auth key required** (as of 2026); rate limit is unstated but conservative — keep to ≤1 RPS.
- Filter by `docTypeCode`:
  - `120` — 有価証券報告書 (annual)
  - `140` — 四半期報告書 (quarterly)
  - `160` — 半期報告書

To find a 4-digit securities code → EDINET CIK (`edinetCode`): use the document listing's `secCode` field.

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
```

- [ ] **Step 2: Commit**

```bash
cd /Users/ryota/.local/share/chezmoi
git add dot_claude/skills/equity-decision/references/data-sources.md
git commit -m "feat(skills): equity-decision data-sources reference"
```

---

### Task 7: Write the user-facing README

**Files:**

- Create: `dot_claude/skills/equity-decision/README.md`

- [ ] **Step 1: Write the README**

```markdown
# equity-decision

A Claude Code skill that produces a structured purchase memo for an individual stock (US or JP). Adapted from [anthropics/financial-services](https://github.com/anthropics/financial-services) (Apache 2.0); reworked for retail use against free public data.

> Not investment advice. Outputs are research summaries.

## Quick start
```

/equity-decision NVDA # US ticker /equity-decision 7203 # JP code (Toyota) /equity-decision NVDA "DC growth slowing" # ticker + hypothesis /equity-decision https://www.sec.gov/.../10-K.htm # URL /equity-decision --ja 9434 # Force JP routing /equity-decision --no-cache NVDA # Skip 24h cache

```

The skill emits a 100–200 line memo covering business, fundamentals (3-year trend), valuation (multiples + DCF), risks (5 axes), and a verdict (Buy/Watch/Pass + sizing + horizon). The memo ends with five deep-dive options you can pick from in the next turn.

## What's in scope (v1)

- US individual stocks (10-K / 10-Q / 8-K via SEC EDGAR + Yahoo Finance)
- JP individual stocks (有価証券報告書 via EDINET + Yahoo Finance Japan)

## What's not in scope (v1)

- ETF / index funds → coming in v1.1
- Dividend-focused screens (yield + payout ratio + coverage) — different rubric
- Crypto, commodities, individual bonds
- Hong Kong / Shanghai / European listings
- Tax optimization (NISA balance, foreign tax credit) — needs personal account data

## Files

```

SKILL.md # skill entry, routing, output rules references/equity-workflow.md # the 5-phase template (this is what gets filled) references/dcf-rubric.md # WACC / growth / terminal defaults & guardrails references/growth-stock-checks.md # SBC, NRR, Rule of 40 references/risk-taxonomy.md # 5 axes Active/Latent/Inactive scoring references/data-sources.md # EDGAR / EDINET / Yahoo / Damodaran query notes scripts/fetch_yahoo.py # `uv run scripts/fetch_yahoo.py NVDA` scripts/fetch_edgar.py # `uv run scripts/fetch_edgar.py NVDA` scripts/fetch_edinet.py # `uv run scripts/fetch_edinet.py 7203` scripts/industry_medians.py # `uv run scripts/industry_medians.py software`

````

## Smoke-test the fetchers

After Phase B is in:

```bash
cd ~/.claude/skills/equity-decision
uv run scripts/fetch_yahoo.py NVDA  | jq '.summary'
uv run scripts/fetch_edgar.py NVDA  | jq '.filings[0]'
uv run scripts/fetch_edinet.py 7203 | jq '.docs[0]'
````

Expected: each returns a JSON object with the documented shape (see each script's docstring).

````

- [ ] **Step 2: Commit**

```bash
cd /Users/ryota/.local/share/chezmoi
git add dot_claude/skills/equity-decision/README.md
git commit -m "docs(skills): equity-decision user-facing README"
````

---

### Task 8: Phase A end-to-end manual smoke test

This is a manual step — no automated test, just a check that Claude can use the skill as-is to produce a usable memo.

- [ ] **Step 1: chezmoi apply (with user confirmation)**

Confirm with user first (per chezmoi rule). Then:

```bash
chezmoi diff | head -50
# user reviews
chezmoi apply --force
ls ~/.claude/skills/equity-decision/   # expect: SKILL.md, README.md, references/
```

- [ ] **Step 2: Restart Claude Code or invoke skill detection**

Open a new Claude Code session in any project. Confirm `/equity-decision` is listed.

- [ ] **Step 3: Run the smoke test**

In the new session:

```
/equity-decision NVDA
```

Expected:

- Claude reads `references/equity-workflow.md`
- Asks the user (or attempts to recall from training) for numbers since no fetchers yet
- Emits a memo following the 5-phase structure
- Ends with the "深掘りする？" menu

If Claude invents numbers without flagging, the SKILL.md hallucination rule isn't strong enough — return to Task 1 and tighten the wording.

- [ ] **Step 4: Tag the commit (optional but useful)**

```bash
cd /Users/ryota/.local/share/chezmoi
git tag equity-decision-v1.0-phase-a -m "Phase A: skeleton, hand-fill workflow"
```

---

## Phase B: Fetchers

End-state: `/equity-decision NVDA` runs `scripts/fetch_yahoo.py NVDA` (and EDGAR / EDINET as appropriate), pulls live data, and fills the memo automatically.

### Task 9: Add a pytest harness under tests/skills

**Files:**

- Create: `tests/skills/equity-decision/conftest.py`
- Create: `tests/skills/equity-decision/run-tests.sh`
- Modify: `justfile` (add `test-skills` recipe)

- [ ] **Step 1: Create the conftest**

`tests/skills/equity-decision/conftest.py`:

```python
"""Shared fixtures for equity-decision fetcher tests."""
import sys
from pathlib import Path

import pytest

SCRIPTS_DIR = Path(__file__).resolve().parents[3] / "dot_claude" / "skills" / "equity-decision" / "scripts"
sys.path.insert(0, str(SCRIPTS_DIR))


@pytest.fixture
def us_tickers() -> list[str]:
    return ["NVDA", "AAPL"]


@pytest.fixture
def jp_tickers() -> list[str]:
    return ["7203", "9984"]
```

- [ ] **Step 2: Create the runner script**

`tests/skills/equity-decision/run-tests.sh`:

```bash
#!/usr/bin/env bash
# Test runner for dot_claude/skills/equity-decision/scripts/*.py
# Runs all pytest tests in this directory using `uv run`.
set -euo pipefail

cd "$(dirname "$0")"

uv run --with pytest --with requests-mock --with yfinance --with beautifulsoup4 \
  python -m pytest -v --tb=short
```

- [ ] **Step 3: Add `test-skills` recipe to justfile**

In `justfile`, append:

```makefile
# Run skill fetcher tests
test-skills:
    bash tests/skills/equity-decision/run-tests.sh
```

- [ ] **Step 4: Verify the harness wires up (no tests yet, no assertions)**

Create an empty `tests/skills/equity-decision/test_smoke.py`:

```python
def test_harness_loads():
    """Trivial: confirms pytest can be invoked via the runner."""
    assert True
```

Run:

```bash
cd /Users/ryota/.local/share/chezmoi
just test-skills
```

Expected: `1 passed`.

- [ ] **Step 5: Commit**

```bash
git add tests/skills/equity-decision/conftest.py tests/skills/equity-decision/run-tests.sh tests/skills/equity-decision/test_smoke.py justfile
git commit -m "test(skills): add pytest harness for equity-decision fetchers"
```

---

### Task 10: `fetch_yahoo.py` — write the failing test

**Files:**

- Create: `tests/skills/equity-decision/test_fetch_yahoo.py`

- [ ] **Step 1: Write the failing test**

```python
"""Tests for scripts/fetch_yahoo.py.

The script's contract:
- argv[1] is the ticker (US: AAPL; JP: 7203 — auto-suffixed .T inside the script)
- prints JSON to stdout with shape: {ticker, market, price, summary: {pe, psr, marketCap, ...}, financials: {...}}
- exits 0 on success, 1 on hard failure (network, unknown ticker)
"""
import json
import subprocess
import sys
from pathlib import Path

import pytest

SCRIPT = Path(__file__).resolve().parents[3] / "dot_claude" / "skills" / "equity-decision" / "scripts" / "fetch_yahoo.py"


def run_script(*args: str) -> dict:
    """Run the script via uv run, return parsed JSON or raise."""
    result = subprocess.run(
        ["uv", "run", str(SCRIPT), *args],
        capture_output=True,
        text=True,
        timeout=30,
    )
    if result.returncode != 0:
        pytest.fail(f"script exited {result.returncode}\nstdout: {result.stdout}\nstderr: {result.stderr}")
    return json.loads(result.stdout)


def test_us_ticker_returns_expected_shape():
    data = run_script("AAPL")
    assert data["ticker"] == "AAPL"
    assert data["market"] == "US"
    assert isinstance(data["price"], (int, float))
    assert data["price"] > 0
    assert "pe" in data["summary"]
    assert "marketCap" in data["summary"]


def test_jp_ticker_auto_suffix():
    data = run_script("7203")
    assert data["ticker"] == "7203"
    assert data["market"] == "JP"
    assert data["price"] > 0
    assert "pe" in data["summary"]


def test_unknown_ticker_exits_nonzero():
    result = subprocess.run(
        ["uv", "run", str(SCRIPT), "ZZZNOTAREALTICKER"],
        capture_output=True,
        text=True,
        timeout=30,
    )
    assert result.returncode != 0
    assert "数字取得失敗" in result.stderr or "not found" in result.stderr.lower()
```

- [ ] **Step 2: Run the test, confirm it fails (Red)**

```bash
cd /Users/ryota/.local/share/chezmoi
just test-skills
```

Expected: `3 failed` (script doesn't exist yet).

---

### Task 11: `fetch_yahoo.py` — implement and pass

**Files:**

- Create: `dot_claude/skills/equity-decision/scripts/fetch_yahoo.py`

- [ ] **Step 1: Implement**

```python
#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "yfinance>=0.2.40",
# ]
# ///
"""fetch_yahoo.py — Yahoo Finance quote + summary metrics for a ticker.

Usage:
    uv run fetch_yahoo.py <TICKER>

Examples:
    uv run fetch_yahoo.py NVDA   # US
    uv run fetch_yahoo.py 7203   # JP (auto .T suffix)

Output (stdout, JSON):
    {
      "ticker": "AAPL",
      "market": "US",
      "price": 192.34,
      "summary": {
        "pe": 31.2,
        "psr": 8.1,
        "marketCap": 3000000000000,
        "beta": 1.25,
        "dividendYield": 0.005
      },
      "financials": {
        "revenue_ttm": 385000000000,
        "operatingIncome_ttm": 120000000000,
        "freeCashFlow_ttm": 100000000000
      }
    }

Exits 1 with a message on stderr if the ticker is unknown or fetch fails.
"""
import json
import re
import sys

import yfinance as yf


def detect_market(raw_ticker: str) -> tuple[str, str]:
    """Return (yahoo_symbol, market_label)."""
    if re.fullmatch(r"\d{4}", raw_ticker):
        return f"{raw_ticker}.T", "JP"
    return raw_ticker.upper(), "US"


def fetch_summary(raw_ticker: str) -> dict:
    yahoo_symbol, market = detect_market(raw_ticker)
    ticker = yf.Ticker(yahoo_symbol)
    info = ticker.info or {}

    if not info or not info.get("regularMarketPrice"):
        raise ValueError(f"数字取得失敗: ticker {raw_ticker!r} not found on Yahoo Finance")

    return {
        "ticker": raw_ticker,
        "market": market,
        "price": info.get("regularMarketPrice"),
        "summary": {
            "pe": info.get("trailingPE"),
            "psr": info.get("priceToSalesTrailing12Months"),
            "marketCap": info.get("marketCap"),
            "beta": info.get("beta"),
            "dividendYield": info.get("dividendYield"),
        },
        "financials": {
            "revenue_ttm": info.get("totalRevenue"),
            "operatingIncome_ttm": info.get("ebitda"),  # closest proxy in info dict
            "freeCashFlow_ttm": info.get("freeCashflow"),
        },
    }


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: fetch_yahoo.py <TICKER>", file=sys.stderr)
        return 2
    try:
        data = fetch_summary(sys.argv[1])
    except Exception as e:
        print(f"数字取得失敗: {e}", file=sys.stderr)
        return 1
    json.dump(data, sys.stdout, ensure_ascii=False)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

- [ ] **Step 2: Run the test, confirm it passes (Green)**

```bash
cd /Users/ryota/.local/share/chezmoi
just test-skills
```

Expected: `3 passed`. (Note: network-dependent; if Yahoo is throttled, the tests may flake. Re-run once.)

- [ ] **Step 3: Commit**

```bash
git add dot_claude/skills/equity-decision/scripts/fetch_yahoo.py tests/skills/equity-decision/test_fetch_yahoo.py
git commit -m "feat(skills): fetch_yahoo.py — Yahoo Finance quote/summary fetcher"
```

---

### Task 12: `fetch_edgar.py` — write the failing test

**Files:**

- Create: `tests/skills/equity-decision/test_fetch_edgar.py`

- [ ] **Step 1: Write the failing test**

```python
"""Tests for scripts/fetch_edgar.py.

Contract:
- argv[1] is the US ticker
- prints JSON with shape: {ticker, cik, filings: [{form, filedDate, accessionNumber, primaryDocument, url}]}
- only the latest 10-K, 10-Q, and most recent 8-Ks (top 5) need be returned
- exits 1 on unknown ticker
"""
import json
import subprocess
from pathlib import Path

import pytest

SCRIPT = Path(__file__).resolve().parents[3] / "dot_claude" / "skills" / "equity-decision" / "scripts" / "fetch_edgar.py"


def run_script(*args: str) -> dict:
    result = subprocess.run(
        ["uv", "run", str(SCRIPT), *args],
        capture_output=True,
        text=True,
        timeout=30,
    )
    if result.returncode != 0:
        pytest.fail(f"script exited {result.returncode}\nstderr: {result.stderr}")
    return json.loads(result.stdout)


def test_known_us_ticker_returns_filings():
    data = run_script("AAPL")
    assert data["ticker"] == "AAPL"
    assert data["cik"].isdigit() and len(data["cik"]) <= 10
    assert isinstance(data["filings"], list) and len(data["filings"]) > 0
    forms = {f["form"] for f in data["filings"]}
    assert "10-K" in forms, f"no 10-K in filings: {forms}"


def test_unknown_ticker_exits_nonzero():
    result = subprocess.run(
        ["uv", "run", str(SCRIPT), "ZZZNOTAREALTICKER"],
        capture_output=True,
        text=True,
        timeout=30,
    )
    assert result.returncode != 0
    assert "数字取得失敗" in result.stderr or "not found" in result.stderr.lower()
```

- [ ] **Step 2: Run, confirm fail (Red)**

```bash
just test-skills
```

Expected: `2 failed`.

---

### Task 13: `fetch_edgar.py` — implement and pass

**Files:**

- Create: `dot_claude/skills/equity-decision/scripts/fetch_edgar.py`

- [ ] **Step 1: Implement**

```python
#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "requests>=2.31",
# ]
# ///
"""fetch_edgar.py — SEC EDGAR filings for a US ticker.

Usage:
    uv run fetch_edgar.py <TICKER>

Output (stdout, JSON):
    {
      "ticker": "AAPL",
      "cik": "320193",
      "filings": [
        {"form": "10-K", "filedDate": "2024-11-01", "accessionNumber": "...", "primaryDocument": "aapl-20240928.htm", "url": "https://www.sec.gov/..."},
        {"form": "10-Q", ...},
        {"form": "8-K", ...},
        ...
      ]
    }

Returns the most recent 10-K, most recent 10-Q, and top-5 most recent 8-Ks.
Exits 1 if ticker → CIK lookup fails or network errors.
"""
import json
import sys

import requests

UA = "equity-decision-skill (pavegy@gmail.com)"
TICKER_MAP_URL = "https://www.sec.gov/files/company_tickers.json"


def lookup_cik(ticker: str) -> str:
    """Return zero-padded 10-digit CIK for a US ticker."""
    r = requests.get(TICKER_MAP_URL, headers={"User-Agent": UA}, timeout=10)
    r.raise_for_status()
    rows = r.json().values()
    upper = ticker.upper()
    for row in rows:
        if row["ticker"].upper() == upper:
            return str(row["cik_str"]).zfill(10)
    raise ValueError(f"数字取得失敗: EDGAR ticker→CIK miss for {ticker!r}")


def fetch_filings(ticker: str) -> dict:
    cik_padded = lookup_cik(ticker)
    cik = cik_padded.lstrip("0") or "0"
    submissions_url = f"https://data.sec.gov/submissions/CIK{cik_padded}.json"
    r = requests.get(submissions_url, headers={"User-Agent": UA}, timeout=15)
    r.raise_for_status()
    payload = r.json()

    recent = payload["filings"]["recent"]
    rows = list(zip(
        recent["form"],
        recent["filingDate"],
        recent["accessionNumber"],
        recent["primaryDocument"],
    ))

    selected = []
    forms_seen = {"10-K": 0, "10-Q": 0, "8-K": 0}
    for form, filed, accession, prim in rows:
        if form == "10-K" and forms_seen["10-K"] == 0:
            forms_seen["10-K"] += 1
        elif form == "10-Q" and forms_seen["10-Q"] == 0:
            forms_seen["10-Q"] += 1
        elif form == "8-K" and forms_seen["8-K"] < 5:
            forms_seen["8-K"] += 1
        else:
            continue
        acc_clean = accession.replace("-", "")
        selected.append({
            "form": form,
            "filedDate": filed,
            "accessionNumber": accession,
            "primaryDocument": prim,
            "url": f"https://www.sec.gov/Archives/edgar/data/{cik}/{acc_clean}/{prim}",
        })
        if all(v >= (1 if k != "8-K" else 5) for k, v in forms_seen.items()):
            break

    return {"ticker": ticker.upper(), "cik": cik, "filings": selected}


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: fetch_edgar.py <TICKER>", file=sys.stderr)
        return 2
    try:
        data = fetch_filings(sys.argv[1])
    except Exception as e:
        print(f"数字取得失敗: {e}", file=sys.stderr)
        return 1
    json.dump(data, sys.stdout, ensure_ascii=False)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

- [ ] **Step 2: Run, confirm pass (Green)**

```bash
just test-skills
```

Expected: `5 passed` (3 yahoo + 2 edgar).

- [ ] **Step 3: Commit**

```bash
git add dot_claude/skills/equity-decision/scripts/fetch_edgar.py tests/skills/equity-decision/test_fetch_edgar.py
git commit -m "feat(skills): fetch_edgar.py — SEC EDGAR filings fetcher"
```

---

### Task 14: `fetch_edinet.py` — write the failing test

**Files:**

- Create: `tests/skills/equity-decision/test_fetch_edinet.py`

- [ ] **Step 1: Write the failing test**

```python
"""Tests for scripts/fetch_edinet.py.

Contract:
- argv[1] is a 4-digit JP securities code (e.g., 7203)
- prints JSON with shape: {ticker, edinetCode, docs: [{docTypeCode, docDescription, submitDateTime, docID, url}]}
- returns the most recent 有価証券報告書 (docTypeCode "120") and most recent 四半期報告書 (docTypeCode "140")
- exits 1 on unknown code or network failure
"""
import json
import subprocess
from pathlib import Path

import pytest

SCRIPT = Path(__file__).resolve().parents[3] / "dot_claude" / "skills" / "equity-decision" / "scripts" / "fetch_edinet.py"


def run_script(*args: str) -> dict:
    result = subprocess.run(
        ["uv", "run", str(SCRIPT), *args],
        capture_output=True,
        text=True,
        timeout=60,
    )
    if result.returncode != 0:
        pytest.fail(f"script exited {result.returncode}\nstderr: {result.stderr}")
    return json.loads(result.stdout)


def test_toyota_returns_yuho():
    data = run_script("7203")
    assert data["ticker"] == "7203"
    assert data["edinetCode"].startswith("E"), f"edinetCode shape: {data['edinetCode']}"
    docs = data["docs"]
    type_codes = {d["docTypeCode"] for d in docs}
    assert "120" in type_codes, f"no 有報 returned: {type_codes}"


def test_unknown_code_exits_nonzero():
    result = subprocess.run(
        ["uv", "run", str(SCRIPT), "0000"],
        capture_output=True,
        text=True,
        timeout=60,
    )
    assert result.returncode != 0
    assert "数字取得失敗" in result.stderr
```

- [ ] **Step 2: Run, confirm fail (Red)**

```bash
just test-skills
```

Expected: `2 failed`.

---

### Task 15: `fetch_edinet.py` — implement and pass

**Files:**

- Create: `dot_claude/skills/equity-decision/scripts/fetch_edinet.py`

- [ ] **Step 1: Implement**

```python
#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "requests>=2.31",
# ]
# ///
"""fetch_edinet.py — EDINET filings for a 4-digit JP securities code.

Usage:
    uv run fetch_edinet.py <CODE>

Output (stdout, JSON):
    {
      "ticker": "7203",
      "edinetCode": "E02144",
      "docs": [
        {"docTypeCode": "120", "docDescription": "有価証券報告書", "submitDateTime": "...", "docID": "S100...", "url": "https://disclosure..."},
        {"docTypeCode": "140", ...}
      ]
    }

Walks back up to 400 calendar days to find the most recent 有報 (docTypeCode 120)
and 四半期報告書 (140) matching the secCode.
Exits 1 on unknown code or network failure.
"""
import datetime as dt
import json
import sys
import time
from typing import Iterator

import requests

API = "https://disclosure.edinet-fsa.go.jp/api/v2/documents.json"
TARGET_TYPES = ("120", "140")  # 有報, 四半期報告書
MAX_DAYS_BACK = 400


def iter_days(start: dt.date, days: int) -> Iterator[dt.date]:
    for i in range(days):
        yield start - dt.timedelta(days=i)


def fetch_docs(sec_code: str) -> dict:
    code_padded = sec_code.zfill(4) + "0"  # EDINET secCode is 5-digit (4-digit + trailing 0)
    today = dt.date.today()
    found: dict[str, dict] = {}
    edinet_code = None

    for day in iter_days(today, MAX_DAYS_BACK):
        if all(t in found for t in TARGET_TYPES):
            break
        params = {"date": day.isoformat(), "type": "2"}
        r = requests.get(API, params=params, timeout=15)
        if r.status_code != 200:
            time.sleep(1.0)
            continue
        for item in r.json().get("results", []):
            if item.get("secCode") != code_padded:
                continue
            edinet_code = edinet_code or item.get("edinetCode")
            t = item.get("docTypeCode")
            if t in TARGET_TYPES and t not in found:
                found[t] = {
                    "docTypeCode": t,
                    "docDescription": item.get("docDescription"),
                    "submitDateTime": item.get("submitDateTime"),
                    "docID": item.get("docID"),
                    "url": f"https://disclosure.edinet-fsa.go.jp/api/v2/documents/{item['docID']}?type=2",
                }
        time.sleep(0.3)

    if not edinet_code:
        raise ValueError(f"数字取得失敗: EDINET secCode→edinetCode miss for {sec_code!r}")

    return {
        "ticker": sec_code,
        "edinetCode": edinet_code,
        "docs": [found[t] for t in TARGET_TYPES if t in found],
    }


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: fetch_edinet.py <4-digit-secCode>", file=sys.stderr)
        return 2
    try:
        data = fetch_docs(sys.argv[1])
    except Exception as e:
        print(f"数字取得失敗: {e}", file=sys.stderr)
        return 1
    json.dump(data, sys.stdout, ensure_ascii=False)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

- [ ] **Step 2: Run, confirm pass (Green)**

```bash
just test-skills
```

Expected: `7 passed`. Note: EDINET tests are slow (walking days backward); test_toyota may take 30-60s.

- [ ] **Step 3: Commit**

```bash
git add dot_claude/skills/equity-decision/scripts/fetch_edinet.py tests/skills/equity-decision/test_fetch_edinet.py
git commit -m "feat(skills): fetch_edinet.py — EDINET 有報/短信 fetcher"
```

---

### Task 16: Update SKILL.md to reference the fetchers

**Files:**

- Modify: `dot_claude/skills/equity-decision/SKILL.md`

- [ ] **Step 1: Add a "Data fetchers" section after "## Workflow"**

Find:

```markdown
## Fail-loud rules
```

Insert before it:

```markdown
## Data fetchers

Run these from `~/.claude/skills/equity-decision/scripts/` via `uv run`:

| When                          | Command                               | Returns                                    |
| ----------------------------- | ------------------------------------- | ------------------------------------------ |
| US ticker → price + multiples | `uv run scripts/fetch_yahoo.py NVDA`  | quote, PE/PSR, market cap, TTM revenue/FCF |
| US ticker → recent filings    | `uv run scripts/fetch_edgar.py NVDA`  | latest 10-K, 10-Q, 5 × 8-K (with URLs)     |
| JP ticker → price + multiples | `uv run scripts/fetch_yahoo.py 7203`  | same shape, auto `.T` suffix               |
| JP code → EDINET filings      | `uv run scripts/fetch_edinet.py 7203` | latest 有報 + 四半期報告書 (with URLs)     |

Each script outputs JSON to stdout. On failure, exit code is non-zero and stderr contains "数字取得失敗: ..." — propagate that text into the memo, do not invent numbers.
```

- [ ] **Step 2: Commit**

```bash
git add dot_claude/skills/equity-decision/SKILL.md
git commit -m "feat(skills): SKILL.md links to data fetchers"
```

---

### Task 17: End-to-end smoke test with real data

- [ ] **Step 1: chezmoi apply (with user confirmation)**

```bash
cd /Users/ryota/.local/share/chezmoi
chezmoi diff | head -50      # user reviews
chezmoi apply --force
```

- [ ] **Step 2: Smoke test each fetcher from the deployed location**

```bash
cd ~/.claude/skills/equity-decision
uv run scripts/fetch_yahoo.py NVDA  | jq '.ticker, .price, .summary.pe'
uv run scripts/fetch_yahoo.py 7203  | jq '.ticker, .price, .summary.pe'
uv run scripts/fetch_edgar.py NVDA  | jq '.filings | map(.form)'
uv run scripts/fetch_edinet.py 7203 | jq '.docs | map(.docTypeCode)'
```

Expected:

- Yahoo: a valid price and PE for both tickers
- EDGAR: a list including at least "10-K" and "10-Q"
- EDINET: a list including "120" (有報)

If any returns "数字取得失敗", debug that fetcher before moving on.

- [ ] **Step 3: End-to-end skill invocation**

In a new Claude Code session:

```
/equity-decision NVDA
```

Expected: Claude runs the fetchers via Bash, fills the 5-phase memo with real numbers, ends with the 深掘りする？ menu.

If Claude doesn't use the fetchers automatically, tighten the workflow in SKILL.md (Task 1 / Task 16) to instruct fetcher invocation explicitly.

- [ ] **Step 4: Tag**

```bash
cd /Users/ryota/.local/share/chezmoi
git tag equity-decision-v1.0 -m "v1: Phase A + Phase B, US + JP individual stocks"
```

---

## Self-review checklist (done while writing this plan)

- [x] **Spec coverage**: every requirement in the spec is mapped to a task above.
  - Skill structure (Section 1) → Task 1 (SKILL.md), Task 7 (README), Phase A workflow tasks
  - Individual stock 5-phase workflow (Section 2) → Task 2 (equity-workflow.md), Tasks 3–5 (rubrics)
  - ETF 4-phase workflow (Section 3) → out of scope for v1, noted in plan header
  - Output format (Section 4) → Task 2 (template) and Task 16 (fetcher hook)
  - Data sources (Section 5) → Task 6 (reference) + Tasks 11/13/15 (fetchers)
  - Phasing (Section 6) → Phase A = Tasks 1–8, Phase B = Tasks 9–17
  - Done criteria #1–8 → satisfied by Tasks 8 (Phase A smoke) + 17 (Phase B smoke)
- [x] **Placeholder scan**: no TBD / TODO / "add error handling" / "similar to" left in the plan.
- [x] **Type consistency**: fetcher JSON shapes are documented in each test file's docstring and matched in each implementation's docstring. `数字取得失敗` is the consistent failure marker across fetchers, tests, and SKILL.md.

---

## Execution

Plan complete and saved to `docs/superpowers/plans/2026-05-29-equity-decision-skill.md`.

Two execution options:

1. **Subagent-Driven (recommended)** — one fresh subagent per task, two-stage review between tasks, fast iteration.
2. **Inline Execution** — execute tasks in this session with checkpoints.

Which approach?
