---
name: ui-design-standards
description: UI quality bar for implementing and reviewing frontend code — design-spec fidelity, the repo's own design tokens, complete interaction states, and accessibility. Use when (1) implementing UI from design specs or mockups, (2) reviewing frontend/UI code, (3) creating new UI components.
---

# UI Design Standards

A quality bar for UI work in any framework. The repo's existing design system outranks everything here: find it first, then apply this bar inside it.

## Before writing UI

- Locate the token source the repo already uses (CSS variables, Tailwind config, a `theme/` module, a component library) and the nearest existing component that does something similar. Reuse both. Create a new token file or theme structure only when none exists, and say that you did.
- With a design spec: match layout, spacing, typography, color, radius, shadow, and hierarchy to the spec. Do not add elements or redesign; a spec gap is a question for the user, not a design decision.
- Without a spec: models fall back on a few default looks, and "avoid a generic look" just swaps one default for another. Name the concrete patterns to avoid instead (the session model's profile in `~/.claude/references/model-profiles/` lists its known defaults), then check which default the first result used and extend the list.

## Done means

- Every value comes from the token source — no literal colors, magic spacing, or one-off inline styles for patterns that recur.
- Every interactive element has hover, focus-visible, active, and disabled states; async views have loading, error, and empty states.
- Semantic elements first (`button`, `a`, `label`, landmarks); ARIA only where no element fits; keyboard reachable; text contrast meets WCAG AA.
- Layout holds at the repo's breakpoints.
- Components take props/composition for variation instead of copies, and stay shallow enough to read.
- Missing assets (icons, illustrations) match the existing set's style; SVG for icons.

Verify by rendering, not by reading: run the app or the component's story and look at each state (a browser tool or screenshot when available). Say which states you rendered and which you could not.

## Reviewing UI code

Report every finding with evidence (`file:line`, a screenshot, or the rendered state), each tagged CRITICAL (wrong behavior, inaccessible, breaks the spec), IMPORTANT (hardcoded values, missing states, deviates from tokens or neighboring components), or LOW (naming, minor structure). Filtering for what to show the user happens after, not during, the review.

| Area          | Check                                                                  |
| ------------- | ---------------------------------------------------------------------- |
| Spec          | Matches the design, no unrequested elements                            |
| Tokens        | No literal colors, spacing, radii, or shadows outside the token source |
| States        | hover / focus-visible / active / disabled / loading / error / empty    |
| Accessibility | Semantics, labels, keyboard path, contrast                             |
| Reuse         | Uses existing components instead of a near-duplicate                   |
| Rendering     | No avoidable re-renders on hot paths                                   |
