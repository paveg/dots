---
alwaysApply: false
description: "React/JSX conventions for component design and hook usage"
globs:
  - "**/*.tsx"
  - "**/*.jsx"
---

# React Conventions

## Avoid useEffect

- Do not reach for `useEffect` unless there is a clear, justified reason (e.g., external system synchronization)
- Prefer derived state (`useMemo`), event handlers, or framework data-fetching primitives (TanStack Query, loader/action)
- If `useEffect` seems necessary, explain why in a comment

## Function Style

- Prefer arrow functions or function declarations over class components
- Use class definitions only when a library explicitly requires it (e.g., Error Boundaries before React 19)

## Reusability

- Design components to be reusable by default — accept props, avoid hardcoded values
- Extract shared logic into custom hooks
- Keep components focused on a single responsibility

## Library Preferences

- Use **Valibot** over Zod for client-side schema validation (smaller bundle, tree-shakeable)
- Use **TanStack Query** over SWR for data fetching
- For public API implementations, use **Zod + Scalar** (Zod schemas for OpenAPI generation, Scalar for API documentation UI)
