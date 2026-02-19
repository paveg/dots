# Phases Reference — Detailed Procedures

## Phase 1: DISCOVER — Detailed Procedure

### Step 1.1: Define the Search Space

Ask the user (or infer from context):
- What market/niche? Be specific: "fitness" is too broad, "home workout equipment for small apartments in Japan" is good
- Who is the target audience? Demographics, language, expertise level
- What's the user's unfair advantage? (Domain expertise, existing audience, technical skill, geographic knowledge)

### Step 1.2: Mine Gap Signals

Use web_search to investigate signal sources **based on the classified opportunity type**.

#### For ALL types:

**Source A: Google Trends Data**
- Search: "[niche] site:trends.google.com" or "[niche] google trends rising"
- Search: "[niche] trending 2025 2026"
- Look for: "Breakout" labeled queries, steady upward trajectories over 12+ months

**Source B: Community Pain Points**
- Search: "[niche] site:reddit.com" — look for repeated questions with no good answers
- Search: "[niche] frustrating OR annoying OR wish there was"
- Search: "[niche] site:news.ycombinator.com" if tech-adjacent

#### For Content gaps, additionally:

**Source C: Content Supply Audit**
- For each candidate topic, search the topic directly
- Assess page 1 results: Are they fresh? Authoritative? Comprehensive?
- Red flags = opportunity: results from 2+ years ago, Q&A dominance, thin listicles

**Source D: Cross-Market Language Gaps**
- Search the topic in English AND the target language
- If great content exists in one language but not the other → localization arbitrage

#### For App/Tool gaps, additionally:

**Source C: Existing Tool Frustration**
- Search: "[niche] app review" or "[niche] tool alternative"
- Search: "[existing tool] complaints OR problems OR alternative"
- Check Product Hunt, App Store reviews for recurring UX frustrations
- Look for: people building hacky workarounds (spreadsheets, manual processes) for problems a tool should solve

**Source D: Technology Wrapper Opportunities**
- Search: "[new technology] for beginners" or "[API/framework] simple tool"
- When powerful tech is inaccessible to non-developers → wrapper opportunity (PhotoAI pattern)

#### For Service gaps, additionally:

**Source C: Hiring/Outsourcing Pain**
- Search: "hire [role] reddit" or "[service] too expensive OR too slow"
- Check freelancer marketplaces for categories with low satisfaction
- Look for: DIY tutorials that people clearly don't want to DIY ("just tell me the answer")

**Source D: Productized Service Precedents**
- Search: "[service] subscription OR unlimited OR flat rate"
- If the model exists in adjacent markets but not this one → service gap (Designjoy pattern)

#### For Product gaps, additionally:

**Source C: Curation Demand**
- Search: "best [resources] for [niche]" — is there a definitive list?
- Search: "[niche] resource list OR toolkit OR starter kit"
- If answers are scattered across many threads → curation product opportunity (Internet Pipes pattern)

**Source D: Template/Framework Demand**
- Search: "[process] template" or "[task] framework"
- If people keep asking for structured approaches to common tasks → template product

### Step 1.3: Score and Rank

For each discovered topic, assign a quick signal strength:
- ↑↑↑ Breakout: Explosive growth, minimal competition
- ↑↑ Growing: Steady growth, some competition forming
- ↑ Emerging: Early signals, unclear trajectory
- → Flat: Stable demand, may still have supply gaps
- ↓ Declining: Avoid unless you see a counter-trend

Present the top 5-10 as a ranked table.

---

## Phase 2: VALIDATE — Detailed Procedure

### Step 2.1: Demand Assessment

Assessment method depends on the opportunity type classified at the start.

**For Content gaps:**
1. Search the exact topic — note autocomplete suggestions volume
2. Search "[topic] statistics" or "[topic] market size"
3. Search "[topic] newsletter OR blog OR podcast" — many = proven demand
4. Check long-tail variations — more variations = deeper demand

**For App/Tool gaps:**
1. Count how many people are asking for this tool (Reddit threads, forum posts, tweets)
2. Search "[problem] workaround" — more workarounds = stronger unmet demand
3. Check if adjacent markets have tools that this market lacks
4. Search App Store / Product Hunt for similar tools — note ratings and review counts

**For Service gaps:**
1. Search freelancer marketplaces for this category — note volume and pricing
2. Count hiring posts and complaints about existing providers
3. Estimate willingness-to-pay from what people currently spend on inferior alternatives

**For Product gaps:**
1. Search for the resource — how often is it requested vs how well it's served?
2. Check if similar products sell in adjacent niches (social proof for the format)
3. Look at Gumroad, Lemon Squeezy, etc. for comparable product pricing/sales

Score 1-5 based on evidence found.

### Step 2.2: Supply Assessment

**For Content gaps** — audit search results:
- [ ] Are the top results from authoritative domains?
- [ ] Were they published/updated within the last 6 months?
- [ ] Do they comprehensively answer the query?
- [ ] Is there a definitive "best" resource?

**For App/Tool gaps** — audit existing solutions:
- [ ] Do existing tools solve the core problem?
- [ ] Is the UX acceptable for non-technical users?
- [ ] Is pricing accessible for the target audience?
- [ ] Are existing tools actively maintained and improving?

**For Service gaps** — audit existing providers:
- [ ] Can users easily find and hire someone for this?
- [ ] Are existing providers fast, reliable, and reasonably priced?
- [ ] Is the process frictionless (no meetings, clear deliverables)?
- [ ] Do existing providers have good reviews/reputation?

**For Product gaps** — audit existing products:
- [ ] Does a comprehensive, up-to-date version of this product exist?
- [ ] Is it easy to find and purchase?
- [ ] Is the quality good enough that there's no room for improvement?
- [ ] Is it priced appropriately for the target audience?

Each unchecked box increases the Supply score (more gaps = higher opportunity).

### Step 2.3: Third Metric Assessment

The third metric varies by type:

**Content → Intent**: Informational low (1-2), Informational high (3), Commercial (4), Transactional (5)
**App/Tool → Feasibility**: Can the user build this with their skills and available time? (1=impossible, 5=weekend project)
**Service → Margin**: Is willingness-to-pay sufficient for sustainable solo delivery? (1=razor thin, 5=premium pricing)
**Product → Packaging**: How easily can scattered info be packaged into a sellable unit? (1=very complex, 5=straightforward curation)

### Step 2.4: Calculate and Report

Arbitrage Score = Demand × Supply Gap × [Third Metric] (max 125)

Present using the validation template from `references/validation-template.md`.

---

## Phase 3: STRATEGIZE — Detailed Procedure

### Step 3.1: Identify the Gap Type

Based on Phase 2 findings, classify the primary gap:

| Gap Type | Key Indicator | Best Response |
|----------|--------------|---------------|
| **Comprehensiveness gap** | No single thorough resource | Definitive guide or course |
| **Freshness gap** | All content is outdated | Updated, current resource |
| **Format gap** | Info exists but wrong format | Repackage (video → text, scattered → curated) |
| **Accessibility gap** | Content too technical/jargon-heavy | Simplified, beginner-friendly version |
| **Localization gap** | Content doesn't exist in target language | Translated/adapted version |
| **Curation gap** | Info is scattered everywhere | Curated collection (like Internet Pipes) |
| **Tool gap** | People describe wanting a tool that doesn't exist | Build a simple tool/template |
| **Community gap** | People discussing but no hub exists | Forum, newsletter, or community |

### Step 3.2: Design the Value Proposition

Fill in: "For **[specific audience]** who **[specific pain]**, **[product name]** is a **[format]** that **[key benefit]**, unlike **[current alternatives]** which **[their weakness]**."

### Step 3.3: Choose Monetization Model

Match to the gap type and user's capabilities:

| Model | Best When | Revenue Timing | Effort |
|-------|-----------|---------------|--------|
| SEO + Affiliate | Commercial intent keywords | Medium-term (3-6 months) | Medium |
| Digital product (ebook, course) | Comprehensiveness/curation gap | Quick if audience exists | High upfront |
| Newsletter + sponsorship | Freshness gap, ongoing topic | Slow build (6-12 months) | Ongoing medium |
| SaaS/Tool | Tool gap | Medium-term | High upfront |
| Consulting/Service | Expertise gap | Immediate | Time-intensive |
| Ad revenue (blog/YouTube) | High-volume informational | Slow (6-12 months) | Ongoing medium |

### Step 3.4: Define Competitive Moat

Every strategy must answer: "When competitors notice this gap (and they will within 6-18 months), why will I still win?"

Strong moats:
- **First-mover + brand**: Being THE known resource (hard to displace once established)
- **Curation quality**: Taste and judgment that AI can't replicate
- **Community lock-in**: Users stay for the network, not just the content
- **Unique data/access**: Original research, insider knowledge, geographic advantage
- **Cross-language advantage**: Bridging markets that competitors in either market can't

Weak moats (avoid relying on these alone):
- "I write better" — AI is closing this gap rapidly
- "I was first" — without brand building, first-mover advantage fades
- "I work harder" — not sustainable or scalable

### Step 3.5: Estimate Effort and Timeline

Be realistic. For a solo creator:
- Blog post / SEO article: 1-3 days
- Comprehensive guide / ebook: 1-4 weeks
- Curated resource collection: 1-2 weeks
- Newsletter setup + first issues: 1 week setup + ongoing
- Simple tool/template: 1-2 weeks (if technical)
- Course: 4-8 weeks

Factor in the user's existing infrastructure. If they already have a blog, newsletter system, etc., reduce estimates accordingly.

---

## Phase 4: EXECUTE — Detailed Procedure

### Step 4.1: Week 1 Plan — Foundation

**Day 1-2: Keyword Architecture**
- Primary keyword (the main gap topic)
- 5-10 long-tail variations (for supporting content)
- Related keywords (for internal linking / content cluster)

**Day 3-4: Content Blueprint**
- For articles: Detailed outline with H2/H3 structure
- For products: Feature spec / table of contents
- For newsletters: First 4 issue topics + format template

**Day 5: Distribution Strategy**
- Primary channel (SEO, social, community, email)
- Secondary channels for amplification
- Specific subreddits, forums, or communities to seed

### Step 4.2: Week 2-3 Plan — Creation

Provide specific daily milestones:
- Day-by-day creation schedule
- Review checkpoints (self-review, peer review if available)
- Quality gates: Does each piece match the gap identified in Phase 2?

### Step 4.3: Week 4 Plan — Launch & Iterate

**Launch checklist**:
- [ ] Content/product live and accessible
- [ ] SEO basics: title, meta description, schema markup
- [ ] Shared in 2-3 relevant communities (non-spammy, value-first)
- [ ] Tracking in place (analytics, search console, revenue tracking)

**Iteration triggers** (check at 30 and 90 days):
- Traffic growing? → Double down, create supporting content
- Ranking but not converting? → Improve CTA, add lead magnet
- Not ranking? → Check: is content comprehensive enough? Build backlinks
- Gap closing (competitors entering)? → Differentiate or pivot to adjacent gap

### Step 4.4: Integration with User's Projects

If the user has existing projects, show how this arbitrage play fits:
- Which existing infrastructure to reuse (domain, newsletter list, social accounts)
- How to cross-promote with existing content
- Tech stack alignment (prefer user's known tools)
- Whether this should be a standalone project or extension of existing work
