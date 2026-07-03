---
name: claude-md-layout
description: |
  Design where a repository's agent knowledge lives — which conventions belong in
  which directory-level CLAUDE.md, and which "convention-definition" skills should be
  copied into CLAUDE.md and then deleted. Optimizes for what the model gets wrong
  without the note, not documentation coverage. Loads the session model's profile from
  ~/.claude/references/model-profiles/ to match its writing style.
  Use when onboarding a repo to Claude Code, after a model upgrade, or when CLAUDE.md
  has grown bloated or conventions are scattered across skills.
  Triggers: 「CLAUDE.md を設計」「階層別 CLAUDE.md」「作法を CLAUDE.md に移したい」.
argument-hint: Target repo path (defaults to the current repo)
---

# CLAUDE.md Layout Design

Target: $ARGUMENTS

Place the project-specific facts that make the model write wrong code or raise
wrong review comments at the deepest directory that is always read when touching
that code. The goal is a misconception catalog, not comprehensive documentation.

## Before you start

Load `~/.claude/references/model-profiles/<session-model-id>.md` and write every
entry in the style it prescribes (its Remove / Rewrite / Keep tables — e.g.
explicit scope over implicit, positive targets over negative bans, params over
prose). If no profile matches the session model, say so and fall back to the
nearest same-family profile.

## Steps

1. Map the project: layers, main directories, existing CLAUDE.md / docs / skills.
   If context is short, split areas across subagents and have them read in
   parallel; take their conclusions, not file dumps.
2. Collect the conventions an AI gets wrong. Source order, highest yield first:
   existing CLAUDE.md / skills / docs, then code (patterns that differ from the
   common convention for the language or framework). Mine PR comments and git
   history only to settle a specific residual doubt — the yield is heavy and
   unstable, so do not sweep them.
3. Find skills whose body is a convention definition (rules, layer rules, naming).
   Copy the content into the relevant directory's CLAUDE.md, then propose deleting
   the skill. Skills whose body is an automated procedure are out of scope.
4. Design placement. Put each item at the deepest level that is always read when
   touching that code. The root CLAUDE.md is loaded into every session, so keep
   only repo-wide items there. Propose files only for directories that earn one,
   not every directory.
5. Write each item as a looks-wrong-but-correct entry: what is correct, why it
   looks unnatural at first glance, and where the full detail lives.
6. Verify. In a fresh session, have a subagent (session model) run a typical task
   for the target directory once with and once without the proposed CLAUDE.md.
   Drop any item whose presence does not change the outcome.

## Constraints

- No general language best practices — anything true in every project.
- Nothing derivable by reading the code (function inventories, structure tours).
- No bold emphasis and no heavy tables in the generated CLAUDE.md — agent-facing
  text pays for that markup in context with no benefit.
- When in doubt, shorter. Only items proven by the with/without check survive.

## Output

- Placement design: which level holds which items, with the reason for each level.
- A draft CLAUDE.md for each proposed location.
- Skills to delete, each with its migration target (which CLAUDE.md now holds it).
- Notes from the with/without verification.

## Why moving convention-skills pays twice

A skill's `description` is loaded into every session — a standing context tax paid
whether or not the skill fires. A convention moved into a directory CLAUDE.md is
read only when that code is touched. Migrating it both places the knowledge where
it fires and removes the always-on cost.
