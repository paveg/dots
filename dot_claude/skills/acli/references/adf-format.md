# ADF (Atlassian Document Format) Reference

ADF is JSON-based format for rich text in Jira/Confluence.

## Document Structure

```json
{
  "type": "doc",
  "version": 1,
  "content": [
    // Array of block-level nodes
  ]
}
```

## Block-Level Nodes

### Heading

```json
{
  "type": "heading",
  "attrs": { "level": 1 },  // 1-6
  "content": [
    { "type": "text", "text": "Heading Text" }
  ]
}
```

### Paragraph

```json
{
  "type": "paragraph",
  "content": [
    { "type": "text", "text": "Paragraph content" }
  ]
}
```

### Bullet List

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
            { "type": "text", "text": "List item" }
          ]
        }
      ]
    }
  ]
}
```

### Ordered List

```json
{
  "type": "orderedList",
  "content": [
    {
      "type": "listItem",
      "content": [
        {
          "type": "paragraph",
          "content": [
            { "type": "text", "text": "Numbered item" }
          ]
        }
      ]
    }
  ]
}
```

### Task List (Checkboxes)

```json
{
  "type": "taskList",
  "attrs": { "localId": "tasklist-1" },
  "content": [
    {
      "type": "taskItem",
      "attrs": {
        "localId": "task-1",
        "state": "TODO"  // or "DONE"
      },
      "content": [
        { "type": "text", "text": "Task description" }
      ]
    }
  ]
}
```

### Code Block

```json
{
  "type": "codeBlock",
  "attrs": { "language": "python" },
  "content": [
    { "type": "text", "text": "print('hello')" }
  ]
}
```

### Blockquote

```json
{
  "type": "blockquote",
  "content": [
    {
      "type": "paragraph",
      "content": [
        { "type": "text", "text": "Quoted text" }
      ]
    }
  ]
}
```

### Rule (Horizontal Line)

```json
{
  "type": "rule"
}
```

### Table

```json
{
  "type": "table",
  "attrs": { "isNumberColumnEnabled": false, "layout": "default" },
  "content": [
    {
      "type": "tableRow",
      "content": [
        {
          "type": "tableHeader",
          "attrs": {},
          "content": [
            {
              "type": "paragraph",
              "content": [{ "type": "text", "text": "Header" }]
            }
          ]
        }
      ]
    },
    {
      "type": "tableRow",
      "content": [
        {
          "type": "tableCell",
          "attrs": {},
          "content": [
            {
              "type": "paragraph",
              "content": [{ "type": "text", "text": "Cell" }]
            }
          ]
        }
      ]
    }
  ]
}
```

## Inline Marks

Apply to text nodes via `marks` array.

### Bold

```json
{ "type": "text", "text": "bold", "marks": [{ "type": "strong" }] }
```

### Italic

```json
{ "type": "text", "text": "italic", "marks": [{ "type": "em" }] }
```

### Code (Inline)

```json
{ "type": "text", "text": "code", "marks": [{ "type": "code" }] }
```

### Link

```json
{
  "type": "text",
  "text": "Click here",
  "marks": [
    {
      "type": "link",
      "attrs": { "href": "https://example.com" }
    }
  ]
}
```

### Strikethrough

```json
{ "type": "text", "text": "deleted", "marks": [{ "type": "strike" }] }
```

### Combined Marks

```json
{
  "type": "text",
  "text": "bold and italic",
  "marks": [
    { "type": "strong" },
    { "type": "em" }
  ]
}
```

## Complete Example

```json
{
  "type": "doc",
  "version": 1,
  "content": [
    {
      "type": "heading",
      "attrs": { "level": 2 },
      "content": [{ "type": "text", "text": "Summary" }]
    },
    {
      "type": "paragraph",
      "content": [
        { "type": "text", "text": "This task involves " },
        { "type": "text", "text": "important", "marks": [{ "type": "strong" }] },
        { "type": "text", "text": " changes." }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 2 },
      "content": [{ "type": "text", "text": "Acceptance Criteria" }]
    },
    {
      "type": "taskList",
      "attrs": { "localId": "ac-1" },
      "content": [
        {
          "type": "taskItem",
          "attrs": { "localId": "ti-1", "state": "TODO" },
          "content": [{ "type": "text", "text": "Feature implemented" }]
        },
        {
          "type": "taskItem",
          "attrs": { "localId": "ti-2", "state": "TODO" },
          "content": [{ "type": "text", "text": "Tests passing" }]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 2 },
      "content": [{ "type": "text", "text": "References" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [
                {
                  "type": "text",
                  "text": "Documentation",
                  "marks": [{ "type": "link", "attrs": { "href": "https://example.com/docs" } }]
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```
