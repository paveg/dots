#!/usr/bin/env bash
# Fixture regression check for bench_metrics.py (writing-bench mechanical
# scoring, ADR 0006). Asserts hand-counted metrics on a fixture with known
# shape so metric-definition drift is caught before it skews a bench run.
# Hermetic: stdlib-only python3, no network.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
METRICS="${REPO_ROOT}/home/dot_claude/skills/writing-proofread/scripts/bench_metrics.py"
FIXTURE="${REPO_ROOT}/tests/skills/writing-bench/fixtures/known-counts.md"

out=$(python3 "${METRICS}" "${FIXTURE}")

assert_eq() {
  local label="$1" expr="$2" want="$3" got
  got=$(echo "${out}" | jq -r "${expr}")
  [[ "${got}" == "${want}" ]] || { echo "FAIL ${label}: want ${want}, got ${got}"; exit 1; }
}

assert_eq "sentences.total"              '.sentences.total'                12
assert_eq "sentences.over_60"            '.sentences.over_60'              1
assert_eq "paragraphs.total"             '.paragraphs.total'               3
assert_eq "paragraphs.over_150_chars"    '.paragraphs.over_150_chars'      0
assert_eq "paragraphs.over_4_sentences"  '.paragraphs.over_4_sentences'    1
assert_eq "sections.count"               '.sections.count'                 1
assert_eq "sections.over_400_chars"      '.sections.over_400_chars'        0
assert_eq "headings.max_depth"           '.headings.max_depth'             4
assert_eq "headings.over_h3"             '.headings.over_h3'               1
assert_eq "list_nesting.max_depth"       '.list_nesting.max_depth'         3
assert_eq "list_nesting.items_deeper_than_2" '.list_nesting.items_deeper_than_2' 1
assert_eq "lines.budget (no type)"       '.lines.budget'                   null

out=$(python3 "${METRICS}" --type pr "${FIXTURE}")
assert_eq "lines.budget (pr)"            '.lines.budget'                   40
assert_eq "lines.over_budget (pr)"       '.lines.over_budget'              false

echo "✓ writing-bench bench_metrics fixture checks passed"
