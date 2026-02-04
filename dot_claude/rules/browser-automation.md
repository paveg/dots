---
alwaysApply: false
globs: []
description: "Browser automation (chrome-in-claude) best practices"
---

# Browser Automation

- Prefer click-and-type over form_input (especially for textareas)
- After filling any form field, read back all visible field values to verify no unintended changes
- Operate one field at a time: set value → verify → move to next
