---
name: acli
description: Atlassian CLI (acli) for Jira operations. Use when (1) creating Jira tickets/issues, (2) updating or editing existing tickets, (3) searching Jira issues, (4) viewing ticket details, (5) managing work items programmatically. Provides correct syntax and ADF format for descriptions.
---

# Atlassian CLI (acli)

CLI tool for Jira Cloud operations. Use `acli jira workitem` commands for issue management.

## Initial Setup

Before using acli, always confirm with user:

1. **Project Key**: Required for all operations
2. **Parent Epic/Ticket**: Required when creating sub-tasks or linking issues
3. **Issue Type**: Task, Bug, Story, etc.

```
AskUserQuestion examples:
- "What is the Jira project key?" (e.g., PROJ, TEAM)
- "What is the parent Epic key?" (e.g., PROJ-100)
- "What issue type should I use?" (Task, Bug, Story, Sub-task)
- "Are there any reference tickets I should check for format/style?"
```

**Important**: Always verify the parent ticket exists before creating sub-tasks:

```bash
acli jira workitem view PROJ-100
```

## Quick Reference

| Operation | Command |
|-----------|---------|
| View | `acli jira workitem view KEY-123` (positional arg, NOT `--key`) |
| View (JSON) | `acli jira workitem view KEY-123 --json` |
| View (fields) | `acli jira workitem view KEY-123 --fields summary,description` |
| Create | `acli jira workitem create --from-json file.json` |
| Create (inline) | `acli jira workitem create --project PROJ --type Task --summary "Title"` |
| Edit | `acli jira workitem edit --key "KEY-123" --summary "New title" --yes` |
| Edit (JSON) | `acli jira workitem edit --from-json file.json --yes` |
| Search | `acli jira workitem search --jql "project = PROJ"` |
| Search (count) | `acli jira workitem search --jql "project = PROJ" --count` |
| Delete | `acli jira workitem delete --key KEY-123 --yes` |
| Transition | `acli jira workitem transition --key KEY-123 --status "Done" --yes` |

### Syntax Differences (important!)

- **`view`**: Uses **positional argument** — `view KEY-123` (no `--key` flag)
- **`edit`/`delete`/`transition`**: Uses **`--key` flag** — `edit --key KEY-123`
- **`search`**: Uses **`--jql` flag** — `search --jql "project = PROJ"` (NOT positional)
- **`create`**: Uses **`--project`/`--type`/`--summary`** or `--from-json`
- **`edit` with JSON**: Uses **`--from-json`** (NOT `--file`)

## Ticket Templates

When creating tickets, ask user for reference tickets to match existing style:

```bash
# Check existing ticket format
acli jira workitem view PROJ-50
```

### Standard Ticket Structure

Recommended sections for task tickets:

1. **Summary** (概要): Brief description of the task
2. **Background/Investigation** (調査結果): Context, data, evidence
3. **Acceptance Criteria** (受け入れ条件): Checklist of completion criteria
4. **References** (参考資料): Links to documentation, Datadog, PRs, etc.

## Creating Tickets

Use `--from-json` with ADF (Atlassian Document Format) for proper formatting:

```bash
acli jira workitem create --from-json /tmp/ticket.json
```

### JSON Structure

```json
{
  "projectKey": "PROJ",
  "type": "Task",
  "parentIssueId": "PROJ-100",
  "summary": "Ticket title",
  "description": {
    "type": "doc",
    "version": 1,
    "content": [...]
  }
}
```

### Issue Types

| Type | Use Case |
|------|----------|
| Epic | Large feature/initiative grouping multiple tasks |
| Story | User-facing feature |
| Task | Technical work item |
| Bug | Defect fix |
| Sub-task | Child of another issue |

### ADF Content Types

See [references/adf-format.md](references/adf-format.md) for complete ADF reference.

**Common patterns:**

```json
// Heading
{"type": "heading", "attrs": {"level": 2}, "content": [{"type": "text", "text": "Title"}]}

// Paragraph
{"type": "paragraph", "content": [{"type": "text", "text": "Content"}]}

// Bullet list
{"type": "bulletList", "content": [
  {"type": "listItem", "content": [
    {"type": "paragraph", "content": [{"type": "text", "text": "Item"}]}
  ]}
]}

// Task list (checkboxes) - for acceptance criteria
{"type": "taskList", "attrs": {"localId": "list-1"}, "content": [
  {"type": "taskItem", "attrs": {"localId": "item-1", "state": "TODO"},
   "content": [{"type": "text", "text": "Task item"}]}
]}

// Code (inline)
{"type": "text", "text": "code here", "marks": [{"type": "code"}]}

// Link - for references
{"type": "text", "text": "Link text", "marks": [{"type": "link", "attrs": {"href": "https://..."}}]}
```

### Including References

Always include relevant links in tickets:

```json
{
  "type": "bulletList",
  "content": [
    {
      "type": "listItem",
      "content": [
        {
          "type": "paragraph",
          "content": [
            { "type": "text", "text": "Datadog URL", "marks": [
              { "type": "link", "attrs": { "href": "https://app.datadoghq.com/logs?..." } }
            ]}
          ]
        }
      ]
    },
    {
      "type": "listItem",
      "content": [
        {
          "type": "paragraph",
          "content": [
            { "type": "text", "text": "Related PR", "marks": [
              { "type": "link", "attrs": { "href": "https://github.com/..." } }
            ]}
          ]
        }
      ]
    }
  ]
}
```

## Editing Tickets

Use `--from-json` with `issues` array to specify targets:

```bash
acli jira workitem edit --from-json /tmp/edit.json --yes
```

### Edit JSON Structure

```json
{
  "issues": ["PROJ-123", "PROJ-124"],
  "description": {
    "type": "doc",
    "version": 1,
    "content": [...]
  }
}
```

**Important flags:**
- `--yes`: Skip confirmation prompt (required for automation)
- `--key`: Specify target issues inline (e.g., `--key "KEY-1,KEY-2"`)
- `--from-json`: Use JSON file with `issues` array for complex edits (ADF descriptions)

**Common mistakes:**
- `--key` and `--from-json` cannot be used together — use `issues` array inside JSON instead
- For simple field edits (summary, assignee), prefer inline: `edit --key KEY-123 --summary "New" --yes`
- For description edits (ADF), use `--from-json` with `issues` array in JSON

## Linking Issues

### Issue Links (blocks, relates to, etc.)

```bash
acli jira workitem link --help
```

### Parent-Child Relationships

Set `parentIssueId` in create JSON for Epic-Task relationships.

## Bulk Operations

### Create Multiple Tickets

Loop through data and create JSON for each:

```bash
for item in "Item1" "Item2" "Item3"; do
  # Generate JSON with proper ADF
  cat > /tmp/ticket.json << EOF
  {...}
EOF
  acli jira workitem create --from-json /tmp/ticket.json
done
```

### Edit Multiple Tickets

Include all keys in `issues` array:

```json
{
  "issues": ["PROJ-1", "PROJ-2", "PROJ-3"],
  "summary": "Updated title"
}
```

## Common Workflows

### Create Task Under Epic

1. Ask user for project key and parent Epic
2. Verify parent Epic exists: `acli jira workitem view EPIC-KEY`
3. Ask if there are reference tickets for format
4. Generate JSON with `parentIssueId`
5. Create with `--from-json`

### Update Ticket Description

1. View current ticket: `acli jira workitem view PROJ-123`
2. Generate edit JSON with `issues` array
3. Include new ADF description
4. Run with `--yes` flag

### Create Tickets with References

1. Gather all reference URLs (Datadog, GitHub, docs)
2. Include as links in description using ADF link marks
3. Verify links are accessible

## Troubleshooting

| Error | Cause | Solution |
|-------|-------|----------|
| `unknown flag: --key` on `view` | `view` takes positional arg | Use `view KEY-123` not `view --key KEY-123` |
| JQL passed as positional arg to `search` | `search` requires `--jql` flag | Use `search --jql "..."` not `search "..."` |
| `unknown flag: --file` on `edit` | Flag does not exist | Use `--from-json` not `--file` |
| `INVALID_INPUT` | Bad ADF format | Validate JSON structure |
| `flags cannot be used together` | `--key` with `--from-json` on `edit` | Use `issues` array in JSON |
| Markdown not rendering | Plain text description | Use ADF format |
| Confirmation prompt blocking | Missing `--yes` | Add `--yes` flag for non-interactive environments |
| `Issue does not exist` | Wrong key or no permission | Verify key with `view` first |
| JQL `!=` operator errors | Operator or quoting issue | Use `NOT IN (Done, Canceled)` instead of `!= Done` |

## References

- [ADF Format Reference](references/adf-format.md) - Complete ADF syntax guide
- Run `acli jira workitem --help` for all available commands
- Run `acli jira workitem create --generate-json` for JSON template
- Run `acli jira workitem edit --generate-json` for edit JSON template
