# GitHub Issue Template for E2E Test Bugs

## Issue Creation Command

```bash
gh issue create --title "<type>: <concise description>" --body "$(cat <<'EOF'
## Summary

[1-2 sentence description of the problem]

## Reproduction Steps

1. Navigate to [URL]
2. [Action 1]
3. [Action 2]
4. [Expected behavior] does not occur / [Actual behavior] happens instead

## Cause

[API response or console error details]

| API | Method | Status |
|-----|--------|--------|
| `/api/xxx` | GET/POST | 4xx/5xx |

## Impact

- [User impact 1]
- [User impact 2]

## Technical Details

[Relevant source files or suspected root cause]

## Environment

- URL: [tested URL]
- Browser: Chrome

---
This issue was discovered via functional testing with Chrome in Claude.
EOF
)"
```

## Type Prefix

- `bug:` - Bugs / defects
- `fix:` - Issues requiring a fix
- `perf:` - Performance issues
- `a11y:` - Accessibility issues
- `ui:` - UI/UX issues

## Examples

### API Error

```bash
gh issue create --title "bug: Tag list API (GET /api/tags) returns 500" --body "..."
```

### UI Issue

```bash
gh issue create --title "ui: Dropdown menu renders off-screen on mobile" --body "..."
```

### Performance

```bash
gh issue create --title "perf: Article list initial load takes over 5 seconds" --body "..."
```
