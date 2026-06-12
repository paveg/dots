# Harness Engineering

## Harness vs Guardrail

Sections in this file fall into two categories:

- **[Harness]** Pre-design — shapes how the agent runs *before* it acts
- **[Guardrail]** Post-verification — detects deviation *after* the agent acts

Harness is a design decision; guardrail is a mechanical check. Separating "is this pre-design or post-verification?" prevents rule bloat.

Push checks toward guardrails whenever a deterministic tool can do the job: **the stronger the mechanical verification, the more autonomy the agent can be safely given**.

## [Guardrail] Generator-Evaluator Separation

- Never self-assess quality of your own output as the final verdict
- When reviewing code you wrote, launch a separate agent that did not participate in generation
- When the main session only planned and subagents generated, the main session is a valid
  evaluator — no extra review subagent needed
- The evaluator should test behavior, not read implementation to form its judgment
- Subagent reports are hypotheses, not facts: verify load-bearing claims against primary
  sources (run the commands, read the files) before acting on them

## [Harness] Sprint Contracts

- Before implementation: agree on concrete "done" criteria with the user
- Done criteria must be verifiable (testable assertions, observable behavior, measurable outcomes)
- If criteria cannot be verified automatically, state which require manual verification
- For multi-turn implementation tasks, encode the contract via `/goal <criteria>` so the harness tracks completion across turns (shows live elapsed/turns/tokens overlay)

## [Guardrail] Review Discipline

### Giving reviews

- Review only changed code. Do not flag pre-existing issues unless they interact with changes
- Classify findings: CRITICAL (blocks ship) / IMPORTANT (should fix) / LOW (nice-to-have)
- Drop LOW findings. Present only CRITICAL and IMPORTANT
- For each fix: state whether it addresses the root cause or is a workaround

### Receiving reviews

- Do not blindly implement feedback — first verify the suggestion is technically correct
- If a reviewer's suggestion would break something, say so with evidence
- If feedback is vague or unclear, ask for clarification instead of guessing intent
- No performative agreement ("great suggestion!") — just evaluate and act

## [Guardrail] Oscillation Guard

- If a fix reverts a previous fix (A -> B -> A pattern), stop and escalate to the user
- When stuck in a fix loop (3+ attempts at the same issue), re-plan instead of retrying
- Maximum 5 review-fix iterations before presenting current state to user

## [Harness] Decision Records

- Record non-trivial technical decisions as ADRs (Architecture Decision Records)
- Check for existing ADR directory (`docs/adr/`, `docs/decisions/`, `adr/`, etc.) and follow that convention. If none exists, recommend `docs/adr/`
- Before making architectural choices, read existing ADRs for prior decisions and constraints
- Write ADRs in English; file naming `NNNN-short-description.md`; sections: Status / Context / Decision / Consequences
