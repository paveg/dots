#!/usr/bin/env python3
"""Mechanical volume/shape metrics for writing-bench (ADR 0006).

Checks a Markdown document against the effort targets in
~/.claude/references/japanese-writing/norms.md ("Volume and shape") and
emits one JSON object. Prose scope: paragraphs and list items. Fenced
code, headings, tables, and blockquotes are excluded — the proofreader's
scope guards treat them as verbatim, and these metrics follow suit.

Counting rules:
- Character counts ignore whitespace.
- Sentences split on 。．！？!? ; a terminator-less fragment (typical
  bullet) counts as one sentence.
- A section is an h2 block; its char count covers prose and list lines
  down to the next h1/h2.
- List nesting depth is indent // 2 + 1 (two-space indents, repo style).

Complements lint.py (rhythm/statistics) — no overlap, no morphology.
"""

import argparse
import json
import re
import sys

SENTENCE_CHAR_LIMIT = 60
PARAGRAPH_CHAR_LIMIT = 150
PARAGRAPH_SENTENCE_LIMIT = 4
SECTION_CHAR_LIMIT = 400
HEADING_DEPTH_LIMIT = 3
LIST_NEST_LIMIT = 2
LINE_BUDGETS = {"pr": 40}

SENTENCE_SPLIT = re.compile(r"(?<=[。．！？!?])")
HEADING = re.compile(r"^(#{1,6})\s")
LIST_ITEM = re.compile(r"^(\s*)(?:[-*+]|\d+\.)\s+(.*)$")
FENCE = re.compile(r"^\s*(```|~~~)")


def nonws_len(text: str) -> int:
    return len(re.sub(r"\s", "", text))


def sentences_in(text: str) -> list[str]:
    return [s for s in (part.strip() for part in SENTENCE_SPLIT.split(text)) if s]


def analyze(source: str, doc_type: str | None) -> dict:
    lines = source.splitlines()

    sentences: list[str] = []
    paragraphs: list[list[str]] = []
    heading_depths: list[int] = []
    list_depths: list[int] = []
    section_chars: list[int] = []

    current_paragraph: list[str] = []
    in_fence = False
    in_section = False

    def close_paragraph() -> None:
        nonlocal current_paragraph
        if current_paragraph:
            paragraphs.append(current_paragraph)
            current_paragraph = []

    for line in lines:
        if FENCE.match(line):
            in_fence = not in_fence
            close_paragraph()
            continue
        if in_fence:
            continue

        heading = HEADING.match(line)
        if heading:
            close_paragraph()
            depth = len(heading.group(1))
            heading_depths.append(depth)
            if depth <= 2:
                in_section = depth == 2
                if in_section:
                    section_chars.append(0)
            continue

        stripped = line.strip()
        if not stripped or stripped.startswith(">") or stripped.startswith("|"):
            close_paragraph()
            continue

        item = LIST_ITEM.match(line)
        if item:
            close_paragraph()
            list_depths.append(len(item.group(1)) // 2 + 1)
            sentences.extend(sentences_in(item.group(2)))
            if in_section:
                section_chars[-1] += nonws_len(item.group(2))
            continue

        current_paragraph.append(stripped)
        sentences.extend(sentences_in(stripped))
        if in_section:
            section_chars[-1] += nonws_len(stripped)

    close_paragraph()

    paragraph_chars = [sum(nonws_len(l) for l in p) for p in paragraphs]
    paragraph_sentences = [len(sentences_in(" ".join(p))) for p in paragraphs]

    budget = LINE_BUDGETS.get(doc_type) if doc_type else None
    total_lines = len(lines)

    return {
        "sentences": {
            "total": len(sentences),
            "over_60": sum(1 for s in sentences if nonws_len(s) > SENTENCE_CHAR_LIMIT),
        },
        "paragraphs": {
            "total": len(paragraphs),
            "over_150_chars": sum(1 for c in paragraph_chars if c > PARAGRAPH_CHAR_LIMIT),
            "over_4_sentences": sum(
                1 for n in paragraph_sentences if n > PARAGRAPH_SENTENCE_LIMIT
            ),
        },
        "sections": {
            "count": len(section_chars),
            "over_400_chars": sum(1 for c in section_chars if c > SECTION_CHAR_LIMIT),
        },
        "headings": {
            "max_depth": max(heading_depths, default=0),
            "over_h3": sum(1 for d in heading_depths if d > HEADING_DEPTH_LIMIT),
        },
        "list_nesting": {
            "max_depth": max(list_depths, default=0),
            "items_deeper_than_2": sum(1 for d in list_depths if d > LIST_NEST_LIMIT),
        },
        "lines": {
            "total": total_lines,
            "budget": budget,
            "over_budget": total_lines > budget if budget is not None else None,
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("file", help="Markdown file to measure")
    parser.add_argument(
        "--type",
        choices=sorted(LINE_BUDGETS),
        help="artifact type with a document-level line budget",
    )
    args = parser.parse_args()

    with open(args.file, encoding="utf-8") as f:
        source = f.read()

    result = {"file": args.file, **analyze(source, args.type)}
    json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
    print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
