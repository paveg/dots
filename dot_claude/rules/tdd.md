---
alwaysApply: true
---

# Test-Driven Development

## Red-Green-Refactor Cycle

1. **Red**: Write a failing test that describes the desired behavior
2. Confirm the test fails for the expected reason
3. **Green**: Write the minimal implementation to make the test pass
4. Confirm all tests pass
5. **Refactor**: Improve code quality while keeping tests green

## Rules

- Never write production code without a corresponding failing test
- One test = one behavior. Keep incremental steps small
- Run tests after each step; show Red before Green
- Do not skip the Red step — a test that has never failed proves nothing

## Common Rationalizations to Reject

| Excuse | Why it's wrong |
| :----- | :------------- |
| "This is too simple to test" | Simple code breaks too. The test takes 30 seconds to write |
| "I'll write tests after" | A test that has never failed proves nothing about your code |
| "I'll keep the existing code as reference" | You will adapt it. That IS test-after development |
| "I already tested it manually" | Ad-hoc verification ≠ systematic regression coverage |
| "TDD will slow me down" | Debugging without tests is slower. Always |
| "This is different because…" | It's not. Start over with a failing test |

## When Uncertain

- Ask the user about test location, framework, or naming conventions rather than guessing
- If multiple test patterns exist in the project, ask which to follow

## Exceptions

TDD does not apply to contexts without test frameworks:

- Dotfiles configuration and templates
- CI/CD pipeline definitions
- Shell scripts without a test harness
- Declarative config files (JSON, YAML, TOML)

## Applying TDD to the Harness Itself

Rules and hooks under `~/.claude/` are also code; they deserve the same Red-Green-Refactor discipline before being committed.

1. **Red**: Reproduce the failure pattern *without* the new rule/hook in place. Confirm the agent fails the way you expect
2. **Green**: Add the rule or hook. Confirm the same scenario is now blocked or corrected
3. **Refactor**: In a fresh session, probe edge cases — paraphrased prompts, adjacent tasks — to confirm the rule is not just memorized to one phrasing

A rule added without a Red step is indistinguishable from cargo culting. If you cannot articulate the concrete failure it prevents, do not add it.
