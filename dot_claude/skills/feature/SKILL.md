---
name: feature
description: |
  Guided feature development with harness engineering principles.
  Sprint contracts, architecture design, implementation, evaluation, and quality review.
  Use when building new features or significant enhancements.
argument-hint: Optional feature description
---

# Feature Development

You are helping a developer implement a new feature. Follow a systematic approach: understand the codebase deeply, agree on done criteria, design architecture, implement, evaluate, and review.

## Core Principles

- **Generator-Evaluator separation**: implementation and quality assessment use different agents/contexts
- **Sprint contracts**: agree on verifiable "done" criteria before writing code
- **Scope discipline**: review only what changed
- **Ask clarifying questions**: resolve all ambiguities before designing. Wait for user answers
- **Understand before acting**: read and comprehend existing code patterns first
- **Use TodoWrite**: track all progress throughout

---

## Phase 1: Discovery

**Goal**: Understand what needs to be built

Initial request: $ARGUMENTS

**Actions**:
1. Create todo list with all phases
2. If feature unclear, ask user for:
   - What problem are they solving?
   - What should the feature do?
   - Any constraints or requirements?
3. Summarize understanding and confirm with user

---

## Phase 2: Codebase Exploration

**Goal**: Understand relevant existing code and patterns

**Actions**:
1. Launch 2-3 code-explorer agents in parallel. Each agent should:
   - Trace through the code comprehensively, focusing on abstractions, architecture, and control flow
   - Target a different aspect (similar features, architecture, UI patterns, etc.)
   - Return a list of 5-10 key files to read
2. Read all files identified by agents to build deep understanding
3. Present comprehensive summary of findings and patterns

---

## Phase 3: Clarifying Questions

**Goal**: Fill in gaps and resolve all ambiguities before designing

**CRITICAL**: DO NOT SKIP this phase.

**Actions**:
1. Review codebase findings and original feature request
2. Identify underspecified aspects: edge cases, error handling, integration points, scope boundaries, design preferences, backward compatibility, performance needs
3. Present all questions to user in a clear, organized list
4. **Wait for answers before proceeding**

---

## Phase 4: Sprint Contract

**Goal**: Agree on concrete "done" criteria before any design or implementation

**Actions**:
1. Propose acceptance criteria based on the feature request and clarified requirements:
   - Each criterion must be verifiable (testable assertion, observable behavior, or command output)
   - Classify as **must-have** or **nice-to-have**
2. For each criterion, state how it will be verified (automated test, manual check, command output)
3. Present to user and iterate until agreed
4. Record the contract in TodoWrite

**Example contract**:
```
Must-have:
- [ ] User can create a new project from the dashboard (verify: click through UI)
- [ ] API returns 400 for invalid input (verify: test case)
- [ ] Data persists across page reload (verify: manual check)

Nice-to-have:
- [ ] Loading state shown during API call (verify: visual check)
```

---

## Phase 5: Architecture Design

**Goal**: Design implementation approach with trade-offs

**Actions**:
1. Launch 2-3 code-architect agents in parallel with different focuses:
   - Minimal changes (smallest change, maximum reuse)
   - Clean architecture (maintainability, elegant abstractions)
   - Pragmatic balance (speed + quality)
2. Review all approaches and form your recommendation
3. Present to user: brief summary of each, trade-offs, **your recommendation with reasoning**
4. **Ask user which approach they prefer**

---

## Phase 6: Implementation

**Goal**: Build the feature

**DO NOT START WITHOUT USER APPROVAL**

**Actions**:
1. Wait for explicit user approval of architecture
2. Break the implementation into bite-sized tasks (each completable in a few minutes):
   - Each task specifies exact files to modify, what to change, and how to verify
   - Record tasks in TodoWrite
3. For each task:
   - Launch a subagent with clear context (sprint contract, architecture, task spec)
   - Verify the task's output before moving to the next
4. Follow codebase conventions strictly
5. Update todos as you progress

---

## Phase 7: Evaluation

**Goal**: Verify the implementation against sprint contract criteria

**Actions**:
1. Run the test suite. Fix failures before proceeding
2. Launch an evaluator agent (separate from implementation context) to:
   - Check each acceptance criterion from the sprint contract
   - Grade each: **PASS** / **FAIL** / **PARTIAL** with evidence
   - For FAIL/PARTIAL: determine if it's a missing feature or a bug
3. If any must-have criterion fails: fix and re-evaluate (max 3 iterations)
4. Present evaluation results to user with sprint contract checklist

The evaluator agent should test behavior (run commands, check output), not just read code.

---

## Phase 8: Quality Review

**Goal**: Catch bugs, simplify code, ensure conventions

**Actions**:
1. Launch 2 code-reviewer agents scoped to changed files only (`git diff`):
   - Agent 1: bugs, logic errors, security (confidence >= 80)
   - Agent 2: project conventions, simplicity, DRY
2. Triage findings:
   - Classify: CRITICAL / IMPORTANT / LOW
   - Drop LOW
   - For each proposed fix: state root cause vs workaround
3. Apply oscillation guard: if a fix reverts a previous change, stop and consult user
4. Max 5 review-fix iterations
5. Present remaining findings to user

---

## Phase 9: Summary

**Goal**: Document what was accomplished

**Actions**:
1. Mark all todos complete
2. Check sprint contract: mark each criterion as met/unmet
3. Summarize:
   - What was built
   - Key decisions made
   - Files modified
   - Any unmet nice-to-have criteria
   - Suggested next steps
