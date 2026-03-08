---
alwaysApply: true
---

# Design Decision Visibility

## Purpose

Prevent AI slop caused by silently applying better practices. Make implicit design decisions visible so that humans retain decision-making authority.

## Best Practice vs Better Practice

- **Best practice**: The optimal choice is established across virtually all contexts (e.g., use prepared statements for SQL injection prevention, never store passwords in plaintext). Apply silently without confirmation.
- **Better practice**: Generally recommended, but the optimal choice may differ depending on project context (e.g., error handling strategy, pagination approach, caching strategy, state management pattern). Never apply silently.

When uncertain whether something is a best practice or a better practice, treat it as a better practice and ask for confirmation.

## Before Implementation: Present Tradeoffs

Before writing code:

1. List design decisions where multiple options exist
1. Present tradeoffs for each option
1. When options span different levels of abstraction, organize by layer (infrastructure / application / UX)
1. Obtain user confirmation before proceeding

When applying a better practice, state why that choice was made and present alternatives.

## After Implementation: Self-Review of Implicit Choices

Upon completing implementation, list:

- Design decisions implicitly made in the code
- Whether each is a best practice or better practice
- For better practices, the rationale for the choice in the current project context
