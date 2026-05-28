#!/usr/bin/env python3
# PreToolUse(Write|Edit|MultiEdit) hook: block code comments that contain
# patterns known to rot quickly. The existing rules in
# ~/.claude/rules/development-principles.md already forbid these, but
# instructions alone have not held — this turns the policy into a
# deterministic check so it survives context-window pressure.
#
# What counts as a rot-prone comment:
#   1. Issue / PR / ticket references ("// added for #123", "# fixes PR-456").
#      Context belongs in commit messages, not comments.
#   2. Caller / usage references ("// used by handleSubmit", "called from
#      the auth handler"). These break the moment callers move.
#   3. Temporal phrasing ("previously", "now does X", "deprecated as of",
#      "as of 2024"). Code evolves; this dates itself.
#   4. Bare TODO / FIXME without an owner (@name) or date (YYYY-MM-DD).
#      Unactionable reminders accumulate forever.
#
# Skipped:
#   - Prose extensions (.md, .mdx, .txt, .rst, .adoc) — issue refs and
#     temporal language are legitimate there.
#   - For Edit / MultiEdit, only lines present in new_string but not in
#     old_string are scanned, so touching code near an existing rot
#     comment does not retroactively block the edit.
#
# Reads Claude Code hook JSON from stdin; emits a deny JSON on stdout
# when blocking, otherwise exits silently.

import json
import re
import sys

PROSE_EXTENSIONS = (".md", ".mdx", ".txt", ".rst", ".adoc")

ROT_PATTERNS = [
    (
        re.compile(r"\b(issue|pr|ticket)\s*[#-]?\s*\d+\b", re.I),
        "issue / PR / ticket reference",
    ),
    (
        re.compile(r"(?:^|\s)#\d{2,}\b"),
        "issue number (#NNN)",
    ),
    (
        re.compile(
            r"\b(?:used\s+by|called\s+(?:from|by)|"
            r"added\s+(?:for|in|to\s+(?:support|handle))|"
            r"needed\s+for(?:\s+the)?|"
            r"for\s+the\s+\S.*?\s+(?:flow|handler|component|page))\b",
            re.I,
        ),
        "caller / usage reference",
    ),
    (
        re.compile(
            r"\b(?:previously|used\s+to|was\s+changed|"
            r"now\s+(?:does|returns|handles)|"
            r"deprecated\s+as\s+of|legacy\s+code|"
            r"since\s+v\d|as\s+of\s+\d{4})\b",
            re.I,
        ),
        "temporal phrasing",
    ),
    (
        re.compile(r"\b(TEMP(?:ORARY)?|HACK|XXX)\s*:", re.I),
        "TEMP/HACK/XXX marker",
    ),
]

TODO_PATTERN = re.compile(r"\b(TODO|FIXME)\b", re.I)
TODO_OWNER_OR_DATE = re.compile(r"\(@[\w-]+\)|\d{4}-\d{2}-\d{2}")

# Comment-marker extraction. Order matters — try HTML/SQL/block before
# line-style. Each pattern uses lookarounds so URLs (http://), CSS hex
# colors (#ff0099), Python floor division (x // 2 — value caught, but
# safe since no rot terms hit numeric content), and shebangs (#!) are
# not mistaken for comments.
COMMENT_REGEXES = (
    re.compile(r"<!--(.*?)(?:-->|$)"),
    re.compile(r"(?<![:/])//(.*)"),
    re.compile(r"/\*(.*?)(?:\*/|$)"),
    re.compile(r"(?:^|\s)--(.*)"),
    re.compile(r"(?:(?<=^)|(?<=\s))#(?!!)(.*)"),
)


def extract_comment_text(line: str) -> str | None:
    if line.lstrip().startswith("#!"):
        return None
    for pattern in COMMENT_REGEXES:
        match = pattern.search(line)
        if match:
            return match.group(1)
    return None


def added_lines(tool_name: str, tool_input: dict) -> list[str]:
    if tool_name == "Write":
        return (tool_input.get("content") or "").splitlines()
    if tool_name == "Edit":
        old = set((tool_input.get("old_string") or "").splitlines())
        new = (tool_input.get("new_string") or "").splitlines()
        return [line for line in new if line not in old]
    if tool_name == "MultiEdit":
        result: list[str] = []
        for edit in tool_input.get("edits") or []:
            old = set((edit.get("old_string") or "").splitlines())
            new = (edit.get("new_string") or "").splitlines()
            result.extend(line for line in new if line not in old)
        return result
    return []


def find_violations(lines: list[str]) -> list[tuple[str, str]]:
    hits: list[tuple[str, str]] = []
    for line in lines:
        comment = extract_comment_text(line)
        if comment is None:
            continue
        matched_label: str | None = None
        for pattern, label in ROT_PATTERNS:
            if pattern.search(comment):
                matched_label = label
                break
        if matched_label is None and TODO_PATTERN.search(comment):
            if not TODO_OWNER_OR_DATE.search(comment):
                matched_label = "TODO/FIXME without owner (@name) or date (YYYY-MM-DD)"
        if matched_label:
            hits.append((line.strip(), matched_label))
    return hits


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0

    tool_name = payload.get("tool_name") or ""
    tool_input = payload.get("tool_input") or {}
    file_path = tool_input.get("file_path") or ""

    if file_path.lower().endswith(PROSE_EXTENSIONS):
        return 0
    if tool_name not in ("Write", "Edit", "MultiEdit"):
        return 0

    violations = find_violations(added_lines(tool_name, tool_input))
    if not violations:
        return 0

    sample = "\n".join(
        f"  {idx}. {line}\n     → {label}"
        for idx, (line, label) in enumerate(violations[:5], 1)
    )
    overflow = f"\n  …and {len(violations) - 5} more." if len(violations) > 5 else ""
    reason = (
        "Comment(s) that tend to rot blocked.\n\n"
        f"{sample}{overflow}\n\n"
        "Why these rot:\n"
        "  - Issue / PR / ticket numbers belong in the commit message or PR body,\n"
        "    not in code that will outlive them.\n"
        "  - Caller / usage references break the moment callers are renamed or moved.\n"
        "  - Temporal phrasing (\"previously\", \"now does\", \"as of v2\") goes stale\n"
        "    the next time the code is rewritten.\n"
        "  - Bare TODO / FIXME without an owner or target date is an unactionable\n"
        "    reminder that accumulates forever.\n\n"
        "How to fix:\n"
        "  - Delete the comment if the code is self-explanatory.\n"
        "  - Rewrite it to describe the WHY (a constraint, invariant, surprise).\n"
        "  - Move task context to the commit message / PR description.\n"
        "  - For TODOs: add an owner — TODO(@username) — or a target date —\n"
        "    TODO 2026-12-31."
    )

    json.dump(
        {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": reason,
            }
        },
        sys.stdout,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
