#!/usr/bin/env python3
"""Measure agent-context cost by when it is paid: always, on invoke, or on demand."""

import argparse
import sys
from dataclasses import dataclass, field
from pathlib import Path

FRONTMATTER_FENCE = "---"


def split_frontmatter(text: str) -> tuple[list[str], str]:
    lines = text.splitlines()
    if not lines or lines[0].strip() != FRONTMATTER_FENCE:
        return [], text.strip()
    for i in range(1, len(lines)):
        if lines[i].strip() == FRONTMATTER_FENCE:
            return lines[1:i], "\n".join(lines[i + 1 :]).strip()
    return [], text.strip()


def _block_scalar(body_lines: list[str], style: str) -> str:
    dedented = [line.strip() for line in body_lines]
    if style.startswith("|"):
        return "\n".join(dedented).strip()
    folded: list[str] = []
    for line in dedented:
        if not line:
            folded.append("\n")
        elif folded and folded[-1] != "\n":
            folded.append(" " + line)
        else:
            folded.append(line)
    return "".join(folded).strip()


def read_description(frontmatter: list[str]) -> str:
    for i, line in enumerate(frontmatter):
        if not line.startswith("description:"):
            continue
        inline = line[len("description:") :].strip()
        if inline and not inline.startswith(("|", ">")):
            return inline.strip("\"'")
        collected = []
        for follow in frontmatter[i + 1 :]:
            if follow.strip() and not follow.startswith((" ", "\t")):
                break
            collected.append(follow)
        return _block_scalar(collected, inline or ">")
    return ""


def has_paths_scope(frontmatter: list[str]) -> bool:
    return any(line.startswith("paths:") for line in frontmatter)


@dataclass
class Totals:
    always_on: int = 0
    on_invoke: int = 0
    on_demand: int = 0


@dataclass
class Report:
    skills: list[tuple[str, int, int, int]] = field(default_factory=list)
    rules: list[tuple[str, int, int]] = field(default_factory=list)
    totals: Totals = field(default_factory=Totals)


def measure_skills(root: Path, report: Report) -> None:
    for skill_file in sorted(root.glob("*/SKILL.md")):
        frontmatter, body = split_frontmatter(skill_file.read_text(encoding="utf-8"))
        desc = len(read_description(frontmatter))
        refs_dir = skill_file.parent / "references"
        refs = sum(
            len(p.read_text(encoding="utf-8").strip())
            for p in sorted(refs_dir.rglob("*"))
            if p.is_file()
        )
        report.skills.append((skill_file.parent.name, desc, len(body), refs))
        report.totals.always_on += desc
        report.totals.on_invoke += len(body)
        report.totals.on_demand += refs


def measure_rules(root: Path, report: Report) -> None:
    for rule_file in sorted(root.glob("*.md")):
        frontmatter, body = split_frontmatter(rule_file.read_text(encoding="utf-8"))
        scoped = has_paths_scope(frontmatter)
        always = 0 if scoped else len(body)
        on_demand = len(body) if scoped else 0
        report.rules.append((rule_file.stem, always, on_demand))
        report.totals.always_on += always
        report.totals.on_demand += on_demand


def emit_tsv(report: Report, out) -> None:
    for name, desc, body, refs in report.skills:
        print(f"skill\t{name}\t{desc}\t{body}\t{refs}", file=out)
    for name, always, on_demand in report.rules:
        print(f"rule\t{name}\t{always}\t{on_demand}", file=out)
    print(f"total\talways_on\t{report.totals.always_on}", file=out)
    print(f"total\ton_invoke\t{report.totals.on_invoke}", file=out)
    print(f"total\ton_demand\t{report.totals.on_demand}", file=out)


def emit_table(report: Report, out) -> None:
    if report.skills:
        print("SKILLS — sorted by always-on cost (the description)", file=out)
        print(f"{'always':>7} {'on-invoke':>10} {'on-demand':>10}  name", file=out)
        for name, desc, body, refs in sorted(report.skills, key=lambda r: -r[1]):
            flag = "  <- no references/" if refs == 0 and body > 4000 else ""
            print(f"{desc:>7} {body:>10} {refs:>10}  {name}{flag}", file=out)
    if report.rules:
        print("\nRULES — always-on unless paths:-scoped", file=out)
        print(f"{'always':>7} {'on-demand':>10}  name", file=out)
        for name, always, on_demand in sorted(report.rules, key=lambda r: -r[1]):
            print(f"{always:>7} {on_demand:>10}  {name}", file=out)
    t = report.totals
    print(
        f"\nTOTAL chars  always-on {t.always_on}  on-invoke {t.on_invoke}"
        f"  on-demand {t.on_demand}",
        file=out,
    )


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--skills", type=Path, action="append", default=[])
    parser.add_argument("--rules", type=Path, action="append", default=[])
    parser.add_argument("--format", choices=("table", "tsv"), default="table")
    args = parser.parse_args(argv)

    if not args.skills and not args.rules:
        parser.error("pass at least one --skills or --rules directory")

    report = Report()
    for root in args.skills:
        measure_skills(root, report)
    for root in args.rules:
        measure_rules(root, report)

    (emit_tsv if args.format == "tsv" else emit_table)(report, sys.stdout)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
