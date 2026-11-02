# Color palette

Every color in a diagram comes from this file. Pick a color for what the element _means_, not for decoration, and keep one meaning per color across the whole diagram. To retheme, edit this file only.

## Roles

| Role               | Stroke    | Fill      | Use for                                            |
| ------------------ | --------- | --------- | -------------------------------------------------- |
| Neutral / default  | `#1f2933` | `#f3f4f6` | ordinary steps, containers, anything with no claim |
| Primary / process  | `#1d4ed8` | `#dbeafe` | the main flow, core components                     |
| Success / output   | `#15803d` | `#dcfce7` | results, healthy states, approved paths            |
| Decision / caution | `#b45309` | `#fef3c7` | branches, gates, things to watch                   |
| Error / danger     | `#b91c1c` | `#fee2e2` | failures, blocked paths, risks                     |
| Accent / external  | `#6d28d9` | `#ede9fe` | third-party systems, boundaries, one highlight     |
| Muted / structure  | `#6b7280` | none      | leader lines, timeline spine, secondary arrows     |

Use `backgroundColor: "transparent"` when an element needs no fill. Fill with the pale tone only when the shape carries meaning; do not fill every box.

## Text

| Use                            | Color                                           |
| ------------------------------ | ----------------------------------------------- |
| Titles and primary labels      | `#111827`                                       |
| Secondary labels, descriptions | `#4b5563`                                       |
| Emphasis tied to a role        | the role's stroke color                         |
| Text on a dark block           | `#e5e7eb`, with the accents from the next table |

## Evidence blocks (code, JSON, sample data)

| Part                | Color     |
| ------------------- | --------- |
| Block fill          | `#111827` |
| Block stroke        | `#374151` |
| Plain code text     | `#e5e7eb` |
| Keys, keywords      | `#93c5fd` |
| Strings, values     | `#86efac` |
| Comments, secondary | `#9ca3af` |

## Canvas

- Background: `#ffffff` (`appState.viewBackgroundColor`)
- Never put role-colored text on a role-colored fill of a different role
