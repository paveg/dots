---
name: excalidraw-diagram
description: >-
  Create Excalidraw diagram files (.excalidraw JSON) that make a visual argument, and render them to PNG to check the result. Use when the user asks to visualize a workflow, architecture, data flow, system, process, or concept as a diagram, or says "draw", "diagram", "visualize", "excalidraw", "図にして", "ダイアグラムを作って", "可視化して".
---

# Excalidraw Diagram

Write a `.excalidraw` file by hand, render it, look at the PNG, and fix it until it reads well. The renderer runs offline in Chrome and makes no network requests.

## Principles

- A diagram argues something. Its structure should convey the meaning even with the labels covered: a fan-out looks like a fan-out, a loop looks like a loop.
- Every shape, color, and position carries information, or it goes.
- Show evidence for technical claims. A box labeled "queue" says little; a box showing `order.created` with a sample payload says a lot.

## Workflow

1. **Decide the depth.**
   - Simple or conceptual: few elements, labels only, no research.
   - Comprehensive or technical (architecture, protocol, pipeline): look up the real component names, event and API names, and data formats first (read the code, docs, or config at hand), then include concrete evidence: code or JSON snippets on dark blocks, real names, sample data.
2. **Plan the composition.** Write down the sections, the main flow, and the visual pattern for each concept before any JSON.
3. **Build the file.** Use `references/element-templates.md` for the JSON and `references/color-palette.md` for every color.
4. **Render and review.** Mandatory, every time.
5. **Fix and repeat** until the checklist passes. Expect 2 to 4 rounds.

## Layout

- Comprehensive diagrams have levels: a summary flow across the top, labeled sections below it, details inside each section.
- Prefer free-floating text with a typographic hierarchy (title, section heading, label, annotation). Use a container only when it means something: a component, a boundary, a grouped state. Keep well under a third of the text inside containers.
- Leave generous, even gaps between elements, and a larger gap between sections. Balance the composition; do not pile everything into one corner.

## Visual patterns

Choose the pattern that matches the idea, and vary patterns across the concepts in one diagram.

| Idea                             | Pattern                                                          |
| -------------------------------- | ---------------------------------------------------------------- |
| One source feeds many            | Fan-out: arrows radiating from one shape                         |
| Many sources become one          | Convergence: arrows meeting at one shape                         |
| Hierarchy                        | Tree: lines and text, no boxes                                   |
| Sequence over time               | Timeline: a line, small dots, labels beside the dots             |
| Repetition or feedback           | Cycle: arrows closing back on the start                          |
| Fuzzy or external system         | Cloud: overlapping ellipses                                      |
| Stages that transform the input  | Assembly line: shapes in a row with an arrow between each        |
| Comparison                       | Side by side: two parallel columns with matching rows            |
| Phase change or separate domains | Gap or section break: extra space, a divider line, a new heading |

## Shapes and color

- Ellipse: start, end, or an external actor. Diamond: decision. Rectangle: a process or component. No shape: a label or annotation.
- Colors are semantic. Take them from `references/color-palette.md`, one role per color throughout the diagram, and do not introduce others.

## Defaults

- `roughness: 0`, `opacity: 100`, `strokeWidth` 1 to 3 by emphasis (1 for structure, 2 for normal, 3 for the one thing that matters most).
- Text: `fontSize: 16`, `fontFamily: 3`, `textAlign: "center"` and `verticalAlign: "middle"` inside containers. A text element's `text` holds only the words a reader should see, never ids or notes.
- Wrapper: `type: "excalidraw"`, `version: 2`, `source`, `elements`, `appState` with a white `viewBackgroundColor`, and `files`.
- Change a default only when the user asks. A project may deliberately override these (for example `roughness: 1` and `fontFamily: 5` for a hand-drawn look); follow the project when it says so.

## Large diagrams

Build the file section by section across several edits instead of one giant write, so each part gets attention.

- Name ids by meaning (`ingest_box`, `arrow_ingest_queue`), never `el_37`.
- Give each section its own `seed` range.
- When an arrow crosses sections, set `startBinding` and `endBinding` on the arrow and add the arrow to both shapes' `boundElements`. Check both ends whenever either section changes.
- Write the elements directly. Do not write a generator script.

## Render and review

```bash
node ~/.claude/skills/excalidraw-diagram/renderer/render.mjs path/to/diagram.excalidraw
```

The PNG lands next to the input and its path is printed. Options: `--output <png>`, `--scale <n>` (default 2), `--width <px>` (default 1920), `--svg <svg>` (also write the SVG). Then **Read the PNG** and judge it twice:

1. Does it say what you intended? Is the structure visible, the flow readable, the emphasis on the right thing?
2. Does it have defects? Look for clipped or overlapping text, text overflowing its shape, arrows that cross shapes or miss their targets, uneven spacing, text too small or too faint to read, and a lopsided composition.

Edit the JSON, render again, and read the new PNG. Never report a diagram as finished from the JSON alone.

If the renderer reports a missing bundle, run the one-time setup. `chezmoi apply` does it automatically; to run it by hand:

```bash
cd ~/.claude/skills/excalidraw-diagram/renderer
pnpm install --frozen-lockfile
node build.mjs
```

The renderer needs Node, pnpm, and Google Chrome. If it exits non-zero listing blocked requests, the diagram references something outside the machine (for example a remote image URL); fix the diagram instead of loosening the renderer.

## Final checklist

- The structure argues the point without the labels.
- Depth matches the request; technical diagrams carry real names and evidence.
- Patterns vary and match their concepts; most text is free-floating.
- Shapes and colors are meaningful and come only from the palette.
- No clipped, overlapping, or tiny text; arrows connect the intended shapes; spacing is even and the composition is balanced.
- Every binding is consistent on both ends; ids are unique and descriptive.
- The last PNG was rendered from the final JSON and read.
