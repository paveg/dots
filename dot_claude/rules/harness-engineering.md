---
alwaysApply: true
---

# Harness Engineering

## Generator-Evaluator Separation

- Never self-assess quality of your own output as the final verdict
- When reviewing code you wrote, launch a separate agent that did not participate in generation
- The evaluator should test behavior, not read implementation to form its judgment

## Sprint Contracts

- Before implementation: agree on concrete "done" criteria with the user
- Done criteria must be verifiable (testable assertions, observable behavior, measurable outcomes)
- If criteria cannot be verified automatically, state which require manual verification

## Review Discipline

- Review only changed code. Do not flag pre-existing issues unless they interact with changes
- Classify findings: CRITICAL (blocks ship) / IMPORTANT (should fix) / LOW (nice-to-have)
- Drop LOW findings. Present only CRITICAL and IMPORTANT
- For each fix: state whether it addresses the root cause or is a workaround

## Oscillation Guard

- If a fix reverts a previous fix (A -> B -> A pattern), stop and escalate to the user
- When stuck in a fix loop (3+ attempts at the same issue), re-plan instead of retrying
- Maximum 5 review-fix iterations before presenting current state to user

## Decision Records

- Record non-trivial technical decisions as ADRs (Architecture Decision Records)
- Check for existing ADR directory (`docs/adr/`, `docs/decisions/`, `adr/`, etc.) and follow that convention. If none exists, recommend `docs/adr/`
- Before making architectural choices, read existing ADRs for prior decisions and constraints
- ADR format: title, status, context, decision, consequences

## Harness Simplification

- Each guardrail encodes an assumption about what the model cannot do reliably
- Periodically question whether a guardrail is still necessary
- Remove ceremony that no longer prevents real failures
