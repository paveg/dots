---
name: trend-arbitrage
description: |
  End-to-end workflow for finding content, app, service, or product opportunities
  where search demand is high but quality supply is low (trend arbitrage).
  Use when: finding content gaps, keyword opportunities, niche research,
  analyzing whether a topic or idea is worth pursuing, or competitive gap analysis.
---

# Trend Arbitrage Skill

Find "Volume: High / Difficulty: Low" gaps in any market and turn them into
actionable content or product strategies. Based on the methodology of identifying
demand-supply mismatches before competitors notice them.

## Core Concept

Trend Arbitrage = Finding topics where **search demand is growing** but **quality supply is scarce**.

Three conditions must ALL be true:
1. **Breakout** — Search volume rising sharply in recent months
2. **Information Gap** — Top results are outdated, thin, or user-generated (Q&A sites, forums)
3. **High Intent** — Searchers want to solve a problem, buy something, or learn a specific skill

## Initial Classification

Before starting any phase, use `ask_user_input` to classify the opportunity type unless
the user has already made it clear. This determines which discovery methods, validation
criteria, and strategy templates to use.

**Always ask upfront:**

1. **What type of gap are you looking for?**
   - Content gap (blog, newsletter, guide, course)
   - App/Tool gap (SaaS, utility, mobile app)
   - Service gap (consulting, subscription service, productized service)
   - Product gap (digital product, template, dataset, curated list)

2. **What market or niche?** (free text if not already specified)

3. **What's your time horizon?**
   - Quick win (launch in 1-2 weeks)
   - Medium play (1-3 months to build)
   - Long-term bet (3-12 months, bigger moat)

The answers shape every subsequent phase — discovery sources, validation criteria,
strategy templates, and execution plans all differ by type.

## Workflow Overview

The skill operates in 4 phases. Run them sequentially or jump to any phase.

```
CLASSIFY  →  Phase 1: DISCOVER  →  Phase 2: VALIDATE  →  Phase 3: STRATEGIZE  →  Phase 4: EXECUTE
(Ask type)   (Find signals)        (Confirm the gap)      (Design the play)       (Create the plan)
```

Read `references/phases.md` for the detailed procedure of each phase.

## Phase 1: DISCOVER — Find Gap Signals

**Goal**: Generate a list of 5-10 candidate opportunities showing breakout signals.

**Inputs**: Determined by classification above. If anything is ambiguous, ask via `ask_user_input`.

**Methods by type** (use web_search for all):

### Content gaps:
1. Google Trends exploration — rising queries in the niche
2. Community pain points — Reddit, forums, Q&A sites with repeated unanswered questions
3. Supply-side audit — search results dominated by outdated/thin content

### App/Tool gaps:
1. "I wish there was an app for..." signals — Reddit, X/Twitter, Hacker News, Product Hunt comments
2. Existing tool complaints — App Store/Play Store reviews with recurring frustration patterns
3. Technology accessibility gaps — powerful tech (AI, APIs) that lacks a simple UI wrapper
4. Adjacent tool search — what tools exist in adjacent markets but not this one?

### Service gaps:
1. Hiring pain signals — "looking for [role]" posts with complaints about cost/quality/speed
2. Process pain — "how do I [task]" where answers are complex and people clearly want someone to do it for them
3. Freelancer marketplace gaps — Fiverr/Upwork categories with low ratings or sparse supply

### Product gaps:
1. Curation demand — "best [resources] for [niche]" with no definitive answer
2. Template/framework demand — "how to [process]" where a reusable template would save time
3. Data gaps — frequently asked questions requiring research that nobody has packaged

**Output**: A ranked table of candidates:

```
| # | Opportunity | Type | Signal Source | Trend Direction | Initial Assessment |
|---|-------------|------|--------------|-----------------|-------------------|
| 1 | ...         | App  | ...          | ↑↑ Breakout     | Promising         |
```

## Phase 2: VALIDATE — Confirm the Gap Exists

**Goal**: For top 3 candidates from Phase 1, produce a quantified gap score.

Validation criteria shift by opportunity type:

### For Content gaps:

**Demand Score (1-5)**: Based on search volume and community interest
**Supply Score (1-5, inverted)**: Based on quality/freshness of existing content
**Intent Score (1-5)**: From casual browsing (1) to purchase-ready (5)

### For App/Tool gaps:

**Demand Score (1-5)**: Based on how many people are asking for this tool, workaround complexity
**Supply Score (1-5, inverted)**: Based on existing tools' quality, UX, and pricing gaps
**Feasibility Score (1-5)**: Can the user realistically build this? (replaces Intent for apps)

### For Service gaps:

**Demand Score (1-5)**: Based on hiring posts, freelancer marketplace activity, complaint volume
**Supply Score (1-5, inverted)**: Based on existing service providers' quality, speed, pricing
**Margin Score (1-5)**: Is the willingness-to-pay high enough for sustainable solo delivery?

### For Product gaps:

**Demand Score (1-5)**: Based on how often people search for / ask about this resource
**Supply Score (1-5, inverted)**: Does a good version of this product already exist?
**Packaging Score (1-5)**: How easily can scattered information be packaged into a sellable unit?

**Arbitrage Score** = Metric1 × Metric2 × Metric3 (max 125)

Produce a validation report. Read `references/validation-template.md` for the format.

**Thresholds**:
- Score ≥ 60: Strong GO — prioritize immediately
- Score 30-59: Conditional — worth pursuing if you have domain expertise
- Score < 30: PASS — not enough edge

## Phase 3: STRATEGIZE — Design the Play

**Goal**: For each GO topic, create a concrete strategy.

Determine the optimal **format** based on the gap type:

| Gap Type | Best Format | Example |
|----------|-------------|---------|
| No comprehensive guide exists | Long-form article/guide | "Complete Guide to X" |
| Info is scattered across forums | Curated resource list | "Internet Pipes" style |
| Existing tools are too complex | Simple tool/template | PhotoAI model |
| No localized version exists | Localized adaptation | JapanDrop-style newsletter |
| Information changes frequently | Newsletter/subscription | Milk Road model |
| People need ongoing help | Community or service | Designjoy model |

Strategy output must include:
1. **Positioning statement**: "For [audience] who [pain point], this is [format] that [unique value]"
2. **Content angle**: What specific angle differentiates from existing content
3. **Monetization path**: How this becomes revenue (ads, product, affiliate, service, subscription)
4. **Competitive moat**: Why copycats can't easily replicate (first-mover, curation quality, trust, community)
5. **Effort estimate**: Time to create MVP content/product
6. **Success metrics**: What to measure in the first 30/90 days

## Phase 4: EXECUTE — Create the Action Plan

**Goal**: Produce a concrete, time-boxed execution plan the user can start today.

Output a week-by-week plan:

**Week 1: Foundation**
- Keyword list (primary + long-tail)
- Content outline or product spec
- Distribution channel selection

**Week 2-3: Creation**
- Content/product creation milestones
- Draft → Review → Publish pipeline

**Week 4: Launch & Measure**
- Distribution plan (SEO, social, community seeding)
- Metrics tracking setup
- Iteration triggers (when to double down vs pivot)

If the user's project context is known (e.g., JapanDrop, Tuck), tailor the execution plan
to fit their existing infrastructure and tech stack.

## Usage Modes

**Quick scan**: User says "find opportunities in [niche]" → Classify, then run Phase 1 only
**Full analysis**: User says "analyze [specific topic/idea]" → Classify, then run Phase 2 + 3
**End-to-end**: User says "find and plan a new project" → Classify, then run all 4 phases
**Validation only**: User says "is [topic/app idea] worth pursuing?" → Classify, then Phase 2 only
**Recon**: User says "what gaps exist in [market]?" → Classify all 4 types, run Phase 1 across types

## Important Principles

1. **Data over intuition** — Always ground recommendations in searchable evidence, not guesses
2. **Be brutally honest** — If a gap doesn't exist or is closing fast, say so clearly
3. **Speed matters** — Trend windows close. Bias toward actionable speed over perfect analysis
4. **Localization is an edge** — For Japanese market content targeting English speakers (or vice versa), cross-language gaps are often the richest arbitrage opportunities
5. **AI content saturation** — In 2025-2026, generic AI-written content floods mid-tier keywords. Focus on gaps requiring human curation, original research, or unique perspective

## References

- `references/phases.md` — Detailed procedures for each phase
- `references/validation-template.md` — Gap validation report template
- `references/examples.md` — Real-world arbitrage case studies for pattern matching
