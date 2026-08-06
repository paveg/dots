---
name: pr-description
description: >-
  Rewrite an existing PR's description into a fixed layout (overview → mermaid →
  review guide → notes → links), with a per-commit verification table that cuts
  the reviewer's tracking cost. Use when asked to 「PR description を更新して」
  「PR 本文を書いて」「PR 説明を簡潔に」「PR description を簡潔に」
  「mermaid を使って PR をまとめて」,
  "rewrite the PR description", or after stacking commits on a pipeline PR.
  Args: <PR URL or number>... [-R owner/repo] [extra context]
argument-hint: "<PR URL or number>... [-R owner/repo]"
---

# pr-description

## Scope

Rewrite the body of an existing PR into a layout reviewers can verify commit by commit. Creating a new PR is out of scope (that belongs to code-flow:commit-push-pr).

Multiple PRs in one invocation are fine: run Steps 1–4 for each PR in turn. Ask the language question (Step 2) once and reuse the answer for the whole batch.

## Workflow

### Step 1: Gather current state and resolve the PR template

```bash
gh pr view <N> -R <owner/repo> --json title,body,commits --jq '{title, body, commits: [.commits[].messageHeadline]}'
gh pr diff <N> -R <owner/repo> --name-only   # understand the change before writing verification steps; drop --name-only to read hunks (--stat does not exist in gh)
```

- If the existing body contains **auto-generated blocks** (`<!-- code-flow-usage-json:start -->` … `end -->`, bot `<details>` blocks, etc.), set them aside and re-append them verbatim at the end of the new body. Never delete them
- **Find the PR template and follow it.** Search order: `.github/PULL_REQUEST_TEMPLATE.md` → `.github/pull_request_template.md` → files under `.github/PULL_REQUEST_TEMPLATE/` → repo root and `docs/`. Without a local clone, fetch via `gh api repos/<owner>/<repo>/contents/.github/PULL_REQUEST_TEMPLATE.md --jq .content | base64 -d`
  - Template **exists**: use its heading structure and comment instructions as the skeleton, and pour the Step 2 elements (mermaid, review-guide table, notes) into the semantically matching sections. Do not delete or rename required template headings
  - Template **absent**: use the default five-section layout from Step 2

### Step 2: Confirm the body language, then compose

First confirm the writing language via `AskUserQuestion` (options: English (Recommended) / Japanese / match the repo's existing PRs). Skip the question if the user already specified a language when invoking the skill.

Five elements to include. With a template, map them into its sections; without one, use them as headings in this order. Not every section is mandatory — omit any with nothing to say.

1. **Overview** — one paragraph on what the PR is for and which follow-up work it feeds into; background links inline
2. **Mermaid** — one diagram capturing the structure of the change: `flowchart LR` for pipelines, before/after side by side for structural refactors, ≤10 nodes, real names (no `ServiceA`). Omit when the change has no structure worth diagramming (e.g. a single-file tweak)
3. **Review guide** — a table per commit (or change group): `| Commit | What | How to verify |`. "How to verify" must be actionable: a runnable command, or something concrete to compare against (a precedent PR, `diff -r`, …)
4. **Notes** — decisions applied and their rationale, including preemptive answers to "why not X?"
5. **Links** — full URLs of dependent PRs, precedent PRs, and issues

Formatting discipline:

- Prose: one paragraph per line (a PR body is a hard-break surface where every newline renders as `<br>`; never wrap mid-paragraph)
- Japanese bodies follow `~/.claude/rules/japanese-writing.md` (avoid the mechanical bold-plus-colon bullet template)
- Concision first. Leave out anything that does not help review (work logs, chronology)

### Step 3: Apply (always via body-file)

**Write the body to a scratch file (in the session scratchpad directory) with the Write tool and pass it via `--body-file`.** Never embed it inline through a heredoc — backtick escaping corrupts fences (details: `~/.claude/rules/gh-pr-body.md`).

```bash
gh pr edit <N> -R <owner/repo> --body-file <scratch>/pr-body.md
```

### Step 4: Verify (mandatory, never skip)

Fetch the body back and confirm the fences are intact before reporting completion:

````bash
gh pr view <N> -R <owner/repo> --json body -q '.body' | grep -n '^\\`'   # zero output = OK (no $-sigils here: argument splicing rewrites them)
gh pr view <N> -R <owner/repo> --json body -q '.body' | grep -n '^```mermaid'          # opening fence present (skip if no mermaid)
````

If any fence line starts with a backslash, fix the local file and re-push it.

## Completion checklist

- [ ] Searched for a PR template and followed its heading structure when one exists
- [ ] Confirmed the body language via AskUserQuestion (or skipped because the user specified it)
- [ ] Set aside and re-appended auto-generated blocks
- [ ] Mermaid uses real-name labels and ≤10 nodes (or was deliberately omitted)
- [ ] Every "How to verify" entry in the review guide is actionable
- [ ] No mid-paragraph line breaks in prose
- [ ] Ran the Step 4 verification commands (the mermaid fence check only when a mermaid is present) and included the results in the completion report
