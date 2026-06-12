# `gh pr` body: never backslash-escape backticks

## Rule

- Single-quoted heredocs (`<<'EOF' ... EOF`) perform **no** interpolation. Backslashes are literal. Never "protect" a backtick by writing it as backslash-backtick inside one — the backslash persists into the saved Markdown.
- For any PR body containing code fences, mermaid blocks, or otherwise backtick-heavy Markdown: write the body to a file with the `Write` tool, then pass it as `gh pr edit --body-file <path>` (or `gh pr create --body-file`). `Write` bypasses shell quoting entirely, which removes the entire failure mode.
- After any `gh pr create` / `gh pr edit`, verify the result by fetching the body back and inspecting code-fence lines. Any fence line with a leading backslash means the body is broken — strip the backslashes from the local file and re-push with `--body-file`.

Verification snippet:

```sh
gh pr view <N> --repo <owner>/<repo> --json body -q '.body' \
  | awk '/^\\`/ {print NR": "$0}'
```

(A fence line starting with a literal backslash is the bug signature.)

## Why

`<<'EOF'` is intentionally non-interpolating. Escaping backticks "to be safe" is the exact failure mode: the shell leaves the backslash in place, and GitHub then renders `backslash-backslash-backslash-mermaid` as literal text instead of opening a code fence. This has broken mermaid diagrams in real PRs (paveg/gontainer #2) more than once. The reactive fix is always the same strip-and-re-push, so the preventive discipline is to stop emitting the backslashes in the first place.

## When to include mermaid

For PRs touching architecture, flows, state, or cross-system interactions: embed a mermaid diagram in the body. A diagram up front makes review faster than bulleted prose. Structural refactors should show before/after side-by-side (authoring rules: see `markdown-formatting.md`).

## How to apply

Whenever constructing a PR body with non-trivial Markdown (mermaid, code fences, nested backticks):

1. Default path — `Write` the body to a scratch file (e.g. `/tmp/pr_body.md`), then `gh pr edit N --body-file /tmp/pr_body.md`.
2. Only use inline heredoc bodies for plain prose with no code fences at all.
3. Always re-fetch the body and eyeball the first code-fence line after editing.
