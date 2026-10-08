#!/usr/bin/env python3
# PreToolUse(Write|Edit|MultiEdit|Bash) hook: block code comments that contain
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
#   5. Keep-in-sync instructions and provenance notes (Japanese patterns
#      only). The first should be enforced by a test or check; the second
#      belongs in the commit message.
# Japanese equivalents of 2 and 3 are matched as well.
#
# Where it runs:
#   - Write / Edit / MultiEdit: the content being written.
#   - Bash: when the command runs `git commit`, the diff the commit will
#     record (staged changes; HEAD vs worktree with -a / --all). This also
#     covers code written through Bash (heredocs, sed, one-off scripts). The
#     repo dir is the payload cwd, a leading `cd <path> &&`, or `git -C
#     <path>`. Any git failure or timeout allows the commit.
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
import os
import re
import shlex
import subprocess
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
        re.compile(
            r"以前は|従来は|旧仕様|今回の(?:変更|修正|対応)|新たに追加|"
            r"に変更した|を追加した|を修正した|対応のため"
        ),
        "temporal phrasing",
    ),
    (
        re.compile(r"から呼ばれ|から呼び出され|で使われ(?:る|て)|呼び出し元"),
        "caller / usage reference",
    ),
    (
        re.compile(
            r"(?:と|に)(?:一致|同期)させ|にも(?:足す|追加する|反映する)|"
            r"も合わせて(?:変更|更新)|(?:1|一)\s*つずつ足す|"
            r"(?:[A-Z][A-Z0-9_]{2,}|行)\s*に足す"
        ),
        "keep-in-sync instruction — enforce with a test or check instead",
    ),
    (
        re.compile(r"で取得した"),
        "provenance — belongs in the commit message",
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


GIT_COMMIT_COMMAND = re.compile(
    r"(?:^|[\s;&|(])git(?:\s+-C\s+(?P<git_dir>\S+))?\s+commit(?![\w-])"
)
LEADING_CD = re.compile(r"^\s*cd\s+(?P<cd_dir>\S+)\s*&&")
COMMIT_FLAGS_WITH_VALUE = "mFCcStu"
GIT_TIMEOUT_SECONDS = 5


def commit_covers_all_tracked(args: str) -> bool:
    try:
        lexer = shlex.shlex(args, posix=True, punctuation_chars=True)
        lexer.whitespace_split = True
        tokens = list(lexer)
    except ValueError:
        return False
    skip_next = False
    for token in tokens:
        if token in ("&&", "||", ";", "|", "&"):
            break
        if skip_next:
            skip_next = False
        elif token == "--all":
            return True
        elif token.startswith("-") and not token.startswith("--"):
            for position, flag in enumerate(token[1:], 1):
                if flag == "a":
                    return True
                if flag in COMMIT_FLAGS_WITH_VALUE:
                    skip_next = position == len(token) - 1
                    break
        elif token.startswith("--") and "=" not in token:
            skip_next = token in ("--message", "--file", "--author", "--date")
    return False


def commit_target(command: str, cwd: str) -> tuple[str, bool] | None:
    match = GIT_COMMIT_COMMAND.search(command)
    if not match:
        return None
    repo_dir = cwd or os.getcwd()
    cd = LEADING_CD.match(command)
    if cd:
        repo_dir = os.path.join(repo_dir, os.path.expanduser(cd.group("cd_dir").strip("\"'")))
    if match.group("git_dir"):
        repo_dir = os.path.join(repo_dir, os.path.expanduser(match.group("git_dir").strip("\"'")))
    return repo_dir, commit_covers_all_tracked(command[match.end():])


def commit_diff(repo_dir: str, covers_all_tracked: bool) -> str | None:
    base = "HEAD" if covers_all_tracked else "--cached"
    try:
        result = subprocess.run(
            [
                "git", "-C", repo_dir, "-c", "core.quotepath=off",
                "diff", base, "-U0", "--no-color", "--no-ext-diff",
            ],
            capture_output=True,
            timeout=GIT_TIMEOUT_SECONDS,
            env={**os.environ, "GIT_OPTIONAL_LOCKS": "0"},
        )
    except (OSError, subprocess.SubprocessError):
        return None
    if result.returncode != 0:
        return None
    return result.stdout.decode("utf-8", errors="replace")


def added_lines_by_file(diff: str) -> dict[str, list[str]]:
    by_file: dict[str, list[str]] = {}
    current: str | None = None
    in_hunk = False
    for line in diff.splitlines():
        if line.startswith("diff --git "):
            current, in_hunk = None, False
        elif line.startswith("@@"):
            in_hunk = True
        elif not in_hunk:
            if line.startswith("+++ b/"):
                current = line[len("+++ b/"):]
        elif line.startswith("+") and current is not None:
            by_file.setdefault(current, []).append(line[1:])
    return by_file


def commit_violations(command: str, cwd: str) -> list[tuple[str, str]]:
    target = commit_target(command, cwd)
    if target is None:
        return []
    diff = commit_diff(*target)
    if diff is None:
        return []
    hits: list[tuple[str, str]] = []
    for path, lines in added_lines_by_file(diff).items():
        if path.lower().endswith(PROSE_EXTENSIONS):
            continue
        hits.extend((f"{path}: {line}", label) for line, label in find_violations(lines))
    return hits


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0

    tool_name = payload.get("tool_name") or ""
    tool_input = payload.get("tool_input") or {}
    file_path = tool_input.get("file_path") or ""

    if tool_name == "Bash":
        violations = commit_violations(
            tool_input.get("command") or "", payload.get("cwd") or ""
        )
        commit_note = (
            "These lines are already in the file: remove the comment from the\n"
            "file, then re-stage it (git add) before committing again.\n\n"
        )
    elif tool_name in ("Write", "Edit", "MultiEdit"):
        if file_path.lower().endswith(PROSE_EXTENSIONS):
            return 0
        violations = find_violations(added_lines(tool_name, tool_input))
        commit_note = ""
    else:
        return 0
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
        f"{commit_note}"
        "Why these rot:\n"
        "  - Issue / PR / ticket numbers belong in the commit message or PR body,\n"
        "    not in code that will outlive them.\n"
        "  - Caller / usage references break the moment callers are renamed or moved.\n"
        "  - Temporal phrasing (\"previously\", \"now does\", \"as of v2\") goes stale\n"
        "    the next time the code is rewritten.\n"
        "  - Bare TODO / FIXME without an owner or target date is an unactionable\n"
        "    reminder that accumulates forever.\n"
        "  - Keep-in-sync instructions silently drift; a test or check that fails\n"
        "    when the copies diverge does not.\n"
        "  - Provenance (where a value was fetched from) is history, which the\n"
        "    commit message records.\n\n"
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
