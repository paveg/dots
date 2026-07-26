#!/usr/bin/env bash
# Tests for dot_claude/skills/context-diet/scripts/measure.py
#
# Builds a throwaway skills/ + rules/ tree so the parser is exercised against
# known byte counts. The load-bearing case is the folded YAML description
# (`>-`), which is what every real skill in this repo uses.
set -uo pipefail
cd "$(dirname "$0")"
SCRIPT="$(cd ../../.. && pwd)/dot_claude/skills/context-diet/scripts/measure.py"

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

mkdir -p "$workdir/skills/alpha/references" "$workdir/skills/beta" "$workdir/rules"

cat > "$workdir/skills/alpha/SKILL.md" <<'MD'
---
name: alpha
description: hello world
---

body line
MD
printf '0123456789' > "$workdir/skills/alpha/references/x.md"

cat > "$workdir/skills/beta/SKILL.md" <<'MD'
---
name: beta
description: >-
  folded one
  folded two
argument-hint: ignored
---

b
MD

cat > "$workdir/rules/always.md" <<'MD'
# Always
MD

cat > "$workdir/rules/scoped.md" <<'MD'
---
paths:
  - "**/*.ts"
---

# Scoped
MD

fail=0
expect() { # expect <label> <exact-line> <haystack>
  if grep -qxF -- "$2" <<<"$3"; then
    echo "  ok   $1"
  else
    echo "  FAIL $1 — expected exact line: $2"
    echo "$3" | sed 's/^/       /'
    fail=1
  fi
}

out=$(python3 "$SCRIPT" --format tsv --skills "$workdir/skills" --rules "$workdir/rules" 2>&1)
rc=$?
if [[ $rc -eq 0 ]]; then echo "  ok   exits 0"; else echo "  FAIL exit code $rc"; fail=1; fi

# description value only, frontmatter delimiters and other keys excluded
expect "plain description measured"  $'skill\talpha\t11\t9\t10' "$out"
# folded `>-` joins continuation lines with a single space: "folded one folded two"
expect "folded description measured" $'skill\tbeta\t21\t1\t0' "$out"

# a rule without paths: frontmatter is always-on; with paths: it is scoped
expect "unscoped rule is always-on"  $'rule\talways\t8\t0' "$out"
expect "paths: rule is scoped"       $'rule\tscoped\t0\t8' "$out"

# always-on total = every skill description + every unscoped rule
expect "always-on total"             $'total\talways_on\t40' "$out"
expect "on-invoke total"             $'total\ton_invoke\t10' "$out"
expect "on-demand total"             $'total\ton_demand\t18' "$out"

echo
if [[ $fail -eq 0 ]]; then echo "passed"; else echo "FAILED"; fi
exit "$fail"
