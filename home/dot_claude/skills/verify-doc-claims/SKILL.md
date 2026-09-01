---
name: verify-doc-claims
description: >-
  Decompose a document's factual claims into a table and force each row to
  cite evidence opened in this session, so unverified statements hidden by
  fluent prose become physically visible. Rows without evidence are marked
  unverified — never fabricated. Use on 「この doc 検証して」「ファクトチェックして」
  「根拠あるか確認して」"verify claims", and before committing docs / ADRs /
  READMEs / runbooks you just wrote.
argument-hint: "<md paths> (defaults to *.md changed in git diff)"
---

# verify-doc-claims

Doc errors come from statements that could be written without checking, not from ignorance. While writing, verified and unverified sentences look identical — both come out equally fluent. A standing "be careful" mindset cannot catch this; it takes a separate audit pass over the finished artifact, and the lever is the forced output format: one claim per table row with an evidence column that is either filled or visibly empty.

## Scope

Factual claims only — things that can be verified: external specs (AWS / GitHub / middleware behavior, limits, defaults), other repos' implementations, operational steps ("running X causes Y"), numbers (timeouts, TTLs, versions, quotas). Exclude opinions/tradeoffs, future plans, and definitions; mixing them bloats the table until it stops working.

## Procedure

1. **Pick targets**: the given paths, else `*.md` from `git diff --name-only` (or `git diff main --name-only`).
2. **Split into claims**: one row per claim. Split compound sentences — errors hide in the second half. Sloppy splitting defeats the whole pass.
3. **Verify per failure type**:

| Type                     | How it breaks                                      | Verification                                                                 |
| ------------------------ | -------------------------------------------------- | ---------------------------------------------------------------------------- |
| Design vs implementation | "decided" written as "works"                       | grep the artifact (workflow / script / code); absent means unimplemented     |
| Second-hand copy         | ADR / old docs treated as primary                  | Trace to the primary source; an ADR is not evidence                          |
| Spec from memory         | External defaults/limits written unfetched         | WebFetch official docs; confirm quotably                                     |
| Stale reference          | Old local clone; pinned SHA / line numbers drifted | `git fetch` then `git show origin/main:<path>`; compare pins to current main |
| Unread adjacent source   | Linked file summarized without opening             | Open it and cite the lines                                                   |

4. **Emit the table**: `| claim | type | evidence | verdict |`. Evidence may only be something opened in this session — `file:line`, command output, fetched URL section. "I know", "generally", "probably" are not evidence. Verdict is binary: 確認済 / 未確認 — "almost certain" collapses to 未確認; a middle value would absorb everything.
5. **Resolve every 未確認 row** (never leave one and move on): verify it, mark the doc text itself as unverified/unimplemented, or delete the statement.

## Discipline

- Never fabricate a citation to fill the table. `—` + 未確認 is a correct output, not a failure; the deliverable is a table that shows where the unverified spots are.
- Distrust your own sentences most — feeling sure at generation time is exactly why verification was skipped.
- Apply the same verification to reviewer suggestions before adopting them.
- A zero-hit grep proves absence only against a fetched remote ref; zero hits in a stale clone prove nothing.
- New facts discovered while verifying (constraints the doc missed) are reported as candidate additions.
