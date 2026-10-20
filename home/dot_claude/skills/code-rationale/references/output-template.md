> Adapted from [cursor/plugins pstack `why`](https://github.com/cursor/plugins/tree/main/pstack/skills/why) (MIT License, Copyright (c) 2026 Lauren Tan). Rewritten to run inline in one session.

# Output Template

Write for the user, in this exact structure. Section headings and tier labels stay in English; the prose follows the user's language.

Rules from `references/epistemics.md` that govern every section:

1. Every claim sits in one tier: Direct, Supported, Inferred, Speculative, Unknown. The tier sets its section and its phrasing.
2. Every Direct or Supported claim carries a citation (PR #, ticket ID, doc URL, chat permalink, commit hash, or file:line).
3. Inferred and Speculative claims use hedged language ("appears to", "likely", "suggests", "one possibility is").
4. Never cite code as evidence for its own intent.
5. Document gaps. Don't fill them with plausible-sounding guesses.
6. Surface contradictions with both sources; don't pick one.
7. Check a hypothesis embedded in the question against the evidence independently.

---

### The Question

Restate the user's question in one or two sentences.

### The Code in Question

File paths, line ranges, key symbols. Two or three lines to orient a cold reader.

### What We Found

Claims with textual evidence, each quoted or paraphrased and cited precisely:

- **[Direct]** {Claim}. Source: [PR #123](url) / ticket ID / file:line. {Brief quote or paraphrase.}
- **[Supported]** {Claim}. Evidence: {list of items and what each contributes.}

`[Direct]` is single-source, explicit evidence. `[Supported]` is multiple indirect items converging on a conclusion.

### What We Can Reasonably Infer

Claims stated nowhere but well-supported by indirect evidence. Each bullet makes the inference chain visible and uses hedged language:

- **[Inferred]** {Hedged claim}. Reasoning: {the specific evidence and the inference step.}

Skip this section if there's nothing to infer.

### Competing Hypotheses

If the evidence fits multiple stories, present each. Don't force a winner the record doesn't support.

- **Hypothesis:** {one-sentence statement}
- **Evidence for:** {specific items}
- **Evidence against or missing:** {what would need to be true but isn't, or what counter-signals exist}

Skip this section if there's a single clear answer.

### What We Don't Know

Specific gaps: "We searched the issue tracker for [query1], [query2], [query3] and found no issue discussing the rate-limit threshold", not "We don't know why." Include:

- Questions that went unanswered
- Searches that returned nothing
- Sources that were unavailable, and why
- People who would likely know but whom you can't ask

If there are no gaps, say why the section is empty instead of padding it.

### Sources Consulted

One line per category, including the ones that returned nothing or were skipped, with the reason:

- **Source control**: {file paths}, {commits reviewed}, PRs #{numbers}, code comments, ADRs, and notes searched.
- **Issue tracker**: {ticket IDs and keyword searches}. Or "Not searched. No matching tool in this session."
- **Long-form documents**: {page titles and search queries}. Or "Not searched. No matching tool in this session."
- **Real-time chat**: {channels, date ranges, queries}. Or "Not searched. No matching tool in this session."
- **Infrastructure observability**: {dashboards, monitors, metrics, logs, traces, or incidents searched}. Or "Not searched. No matching tool in this session."
- **Error tracking**: {issues, events, or releases searched}. Or "Not searched. No matching tool in this session."
- **Product analytics**: {tables queried, time windows, and the numeric summaries that bore on the question}. Or "Not searched. No matching tool in this session."

A category skipped as provably irrelevant states that reason instead.

### Confidence Summary

One or two sentences on overall confidence and the result of the skeptic check, e.g.:

> The core rationale (A) is well-supported by direct PR and ticket evidence. The specific threshold value (100) is inferred from the surrounding context but not explicitly documented. Whether a customer request drove it could not be answered: no relevant tracker or document content surfaced, and chat search was unavailable. The skeptic check refuted one claim, which was downgraded to Inferred.

---

## Quality Check Before Presenting

Revise if any item fails:

1. Does every claim in "What We Found" have a citation? If not, add one or move it to Inferred or Hypotheses.
2. Is the phrasing tier-appropriate? Direct claims can use "because"; Inferred claims cannot.
3. Did you surface every contradiction you noticed, or quietly pick one?
4. Does "What We Don't Know" name specific gaps, or state why it is empty?
5. Did you check any hypothesis embedded in the question rather than rubber-stamp it?
6. Did you cite code as evidence for its own intent? Remove it.
7. Is the tone calibrated? A confident-sounding answer on weak evidence is the failure this skill exists to prevent.

The value of this output is its honesty, not its authority. A reader who takes it to the original author or an engineering lead should know what's known, what's inferred, and what's missing, so they can ask the right follow-up questions.
