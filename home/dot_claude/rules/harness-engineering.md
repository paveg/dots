# Harness Engineering

## Generator-Evaluator Separation

- Never let self-assessment of your own output be the final verdict. Use the cheapest evaluator that decides the question: a deterministic check that exercises the behavior (tests, type-check, build, render) when one exists; otherwise a separate agent (`workflow.md` picks which). Prose, rules, prompts, and claims of fact have no deterministic check, so they go to a separate evaluator unless the edit changes no meaning (typos, formatting); for them, "behavior" is what a fresh reader does with the text in a concrete scenario. A re-review after a fix is part of the same stage, bounded by the Oscillation Guard; don't add review rounds or reviewer agents beyond these stages
- The evaluator judges by behavior, not by reading the implementation: it may read the subject to design a check (which condition to break, which input to feed), but the verdict comes from what ran and what it returned. When the artifact under evaluation is a test suite, its behavior is failing on a deliberately broken subject: break one condition of the subject at a time and confirm the suite goes red. A green run of a test suite proves nothing about the suite
- Subagent reports are hypotheses, not facts: verify load-bearing claims against primary sources (run the commands, read the files) before acting on them. Counts, deletions, and "no longer applies" are load-bearing: when items are removed or merged, enumerate them before and after and account for every one; a summary that adds up is not evidence

## Sprint Contracts

- Before implementing, agree on concrete "done" criteria with the user: testable assertions, observable behavior, measurable outcomes. Say which require manual verification

## Review Discipline

- Giving: review only changed code, flagging pre-existing issues only when they interact with the change. Classify CRITICAL (blocks ship) / IMPORTANT (should fix) / LOW and present only CRITICAL and IMPORTANT. For each fix, say whether it addresses the root cause or is a workaround
- Receiving: verify a suggestion is technically correct before implementing it; if it would break something, say so with evidence; ask when feedback is vague. No performative agreement

## Oscillation Guard

- A fix that reverts a previous fix (A -> B -> A): stop and escalate to the user
- 3+ attempts at the same issue: re-plan instead of retrying. Maximum 5 review-fix iterations before presenting the current state to the user

## Decision Records

- Record non-trivial technical decisions as ADRs in the repo's existing ADR convention (directory, naming, sections); if none exists, recommend `docs/adr/`. Read existing ADRs before making architectural choices
