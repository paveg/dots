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

## When Uncertain

- Ask the user about test location, framework, or naming conventions rather than guessing
- If multiple test patterns exist in the project, ask which to follow

## Exceptions

TDD does not apply to contexts without test frameworks:

- Dotfiles configuration and templates
- CI/CD pipeline definitions
- Shell scripts without a test harness
- Declarative config files (JSON, YAML, TOML)
