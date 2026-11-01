#!/usr/bin/env bash
# Fixture regression check: verify home/dot_claude/skills/writing-proofread/scripts/lint.py
# detects the expected number of findings on the vendored fixtures. Catches
# drift caused by re-vendoring lint.py/textcore.py or editing the fixtures
# (e.g. a fixture edit that accidentally introduces/removes a detectable
# pattern) before it lands in a commit.
#
# NOTE: If you intentionally re-vendor scripts or edit
# home/dot_claude/skills/writing-proofread/scripts/fixtures/, update
# the expected counts below to match (see scripts/NOTICE.md for the update
# procedure).
#
# Non-hermetic: downloads sudachidict on first `uv run`. Wired into the
# `test-skills` justfile recipe, not `test-skill-scripts`.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
LINT="${REPO_ROOT}/home/dot_claude/skills/writing-proofread/scripts/lint.py"
CALQUES="${REPO_ROOT}/home/dot_claude/skills/writing-proofread/scripts/calques.py"
SMELLY_FIXTURE="${REPO_ROOT}/home/dot_claude/skills/writing-proofread/scripts/fixtures/ai-smelly.md"
NATURAL_FIXTURE="${REPO_ROOT}/home/dot_claude/skills/writing-proofread/scripts/fixtures/natural.md"

# Expected finding counts. Update these if you deliberately re-vendor
# lint.py/textcore.py or edit the fixtures.
EXPECTED_SMELLY_DEFAULT=22
EXPECTED_SMELLY_EXPERIMENTAL=29
EXPECTED_NATURAL_DEFAULT=0
EXPECTED_NATURAL_EXPERIMENTAL=0

count_findings() {
  local file="$1"
  shift
  local json_out lint_status
  json_out="$(mktemp)"
  local cleanup_json_out="${json_out}"
  trap 'rm -f "${cleanup_json_out}"' RETURN

  set +e
  uv run "${LINT}" "${file}" --json "$@" >"${json_out}"
  lint_status=$?
  set -e

  if [ "${lint_status}" -ne 0 ]; then
    echo "error: lint run failed (exit=${lint_status}) for ${file} $*" >&2
    return 1
  fi

  local out py_status
  set +e
  out="$(python3 -c '
import json, sys
print(len(json.load(sys.stdin)["findings"]))
' <"${json_out}")"
  py_status=$?
  set -e

  if [ "${py_status}" -ne 0 ]; then
    echo "error: failed to parse lint JSON output (exit=${py_status}) for ${file} $*" >&2
    return 1
  fi

  echo "${out}"
}

fail=0

check() {
  local label="$1" expected="$2" actual="$3"
  case "${actual}" in
    ''|*[!0-9]*)
      echo "FAIL: ${label}: could not determine actual finding count (got '${actual}')" >&2
      fail=1
      return
      ;;
  esac
  if [ "${actual}" -ne "${expected}" ]; then
    echo "FAIL: ${label}: expected ${expected} findings, got ${actual} (diff: $((actual - expected)))" >&2
    fail=1
  else
    echo "OK: ${label}: ${actual} findings"
  fi
}

check "ai-smelly.md (default)" "${EXPECTED_SMELLY_DEFAULT}" "$(count_findings "${SMELLY_FIXTURE}")"
check "ai-smelly.md (--experimental)" "${EXPECTED_SMELLY_EXPERIMENTAL}" "$(count_findings "${SMELLY_FIXTURE}" --experimental)"
check "natural.md (default)" "${EXPECTED_NATURAL_DEFAULT}" "$(count_findings "${NATURAL_FIXTURE}")"
check "natural.md (--experimental)" "${EXPECTED_NATURAL_EXPERIMENTAL}" "$(count_findings "${NATURAL_FIXTURE}" --experimental)"

calques_words() {
  local text="$1" input
  input="$(mktemp)"
  printf '%s\n' "${text}" >"${input}"
  uv run "${CALQUES}" --json "${input}" | python3 -c '
import json, sys
print(" ".join(hit["word"] for hit in json.load(sys.stdin)))
'
  rm -f "${input}"
}

check_calques() {
  local label="$1" text="$2" expected="$3" actual
  actual="$(calques_words "${text}")"
  if [ "${actual}" != "${expected}" ]; then
    echo "FAIL: ${label}: expected calques '${expected}', got '${actual}'" >&2
    fail=1
  else
    echo "OK: ${label}: calques '${actual}'"
  fi
}

check_calques "calques.py flags a motion verb" "人間が握る。" "握る"
check_calques "calques.py stays quiet on plain prose" "今日は天気が良いので散歩に行く。" ""

if [ "${fail}" -ne 0 ]; then
  echo "Fixture regression check FAILED." >&2
  exit 1
fi

echo "Fixture regression check PASSED."
