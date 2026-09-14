# Harness Engineering

## Generator-Evaluator Separation

- Never let self-assessment of your own output be the final verdict. Code you wrote is reviewed by a separate agent that did not generate it; when the main session only planned and subagents generated, the main session is a valid evaluator
- The evaluator tests behavior; it does not read the implementation to form its judgment
- Subagent reports are hypotheses, not facts: verify load-bearing claims against primary sources (run the commands, read the files) before acting on them

## Sprint Contracts

- Before implementing, agree on concrete "done" criteria with the user: testable assertions, observable behavior, measurable outcomes. Say which require manual verification
- For multi-turn implementation, encode the contract via `/goal <criteria>` so the harness tracks completion across turns

## Review Discipline

- Giving: review only changed code, flagging pre-existing issues only when they interact with the change. Classify CRITICAL (blocks ship) / IMPORTANT (should fix) / LOW and present only CRITICAL and IMPORTANT. For each fix, say whether it addresses the root cause or is a workaround
- Receiving: verify a suggestion is technically correct before implementing it; if it would break something, say so with evidence; ask when feedback is vague. No performative agreement

## Oscillation Guard

- A fix that reverts a previous fix (A -> B -> A): stop and escalate to the user
- 3+ attempts at the same issue: re-plan instead of retrying. Maximum 5 review-fix iterations before presenting the current state to the user

## Decision Records

- Record non-trivial technical decisions as ADRs. Follow the repo's existing ADR directory convention (`docs/adr/`, `docs/decisions/`, `adr/`, …); if none exists, recommend `docs/adr/`. Read existing ADRs before making architectural choices
- English; file naming `NNNN-short-description.md`; sections: Status / Context / Decision / Consequences
