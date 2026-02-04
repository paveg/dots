---
name: browser-e2e-test
description: |
  E2E testing workflow for web applications using Chrome in Claude.
  Automates functional testing, bug detection, and GitHub Issue creation.
  Use when: (1) running functional tests on web apps, (2) verifying staging/production behavior,
  (3) finding bugs and creating Issues, (4) capturing UI behavior with screenshots
---

# Browser E2E Test

E2E testing workflow for web applications using Chrome in Claude.

## Workflow

### 1. Setup

```
1. tabs_context_mcp to get browser context
2. tabs_create_mcp to create a new test tab
3. Confirm project structure (root, API endpoints)
4. TodoWrite to create a test plan
```

### 2. Test Execution

For each feature under test:

```
1. navigate to the page
2. wait (2s) for page load
3. screenshot to capture current state
4. read_page (filter: interactive) to get actionable elements
5. Prefer click-and-type over form_input (especially for textareas)
6. After each field input, read back all visible field values to verify no unintended changes
7. screenshot to capture result
8. read_network_requests to check API responses
9. read_console_messages (onlyErrors: true) to check for errors
```

### 3. Issue Recording

When a problem is found:
- Record API status codes (especially 4xx, 5xx)
- Record console errors
- Record reproduction steps
- Record screenshot IDs

### 4. Issue Creation

Create a GitHub Issue for each discovered problem via `gh issue create`.
See [references/issue-template.md](references/issue-template.md) for the template.

## Chrome in Claude Tips

### Page Interaction
- Use `read_page` with `filter: interactive` to get only buttons/links/inputs
- Use `ref` parameter for click targets (more stable than coordinates)
- Use `hover` to reveal elements that only appear on hover

### Debugging
- `read_network_requests` captures requests made after the first call
- `read_console_messages` works the same way — call it early to start capturing
- Filter by API pattern: `urlPattern: "/api/"`

### Caveats
- Avoid triggering alert dialogs (they block all interaction)
- Always use tab IDs from fresh tabs_context_mcp calls
- Add appropriate `wait` after interactions

## Cleanup

After testing is complete:
1. Delete any test data created during the session
2. Mark all TodoWrite tasks as complete
3. Output a test results summary
