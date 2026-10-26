#!/usr/bin/env bash
# Regression check for the yomiyasu scripts that home/.chezmoiexternal.toml
# pulls into writing-proofread/scripts/yomiyasu/. Downloads the pinned archive,
# then pins the lint finding counts on the shared fixtures and the
# --fail-on meaning-risk contract of yomiyasu_diff.py, so a version bump that
# changes behavior goes red before it is merged.
#
# NOTE: When a bump changes the counts on purpose, update the expected counts
# below in the same PR.
#
# Non-hermetic: downloads the archive. Wired into `test-skills`.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
EXTERNAL_TOML="${REPO_ROOT}/home/.chezmoiexternal.toml"
FIXTURES="${REPO_ROOT}/home/dot_claude/skills/writing-proofread/scripts/fixtures"
SMELLY_FIXTURE="${FIXTURES}/ai-smelly.md"
NATURAL_FIXTURE="${FIXTURES}/natural.md"

EXPECTED_SMELLY_FINDINGS=13
EXPECTED_NATURAL_FINDINGS=0

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

url="$(python3 -I -c '
import sys, tomllib
print(tomllib.load(open(sys.argv[1], "rb"))[".claude/skills/writing-proofread/scripts/yomiyasu"]["url"])
' "${EXTERNAL_TOML}")"
curl -fsSL --retry 3 -o "${tmpdir}/yomiyasu.tar.gz" "${url}"
python3 -I -c '
import sys, tarfile
wanted = {"yomiyasu_lint.py", "yomiyasu_diff.py", "markdown_visibility.py"}
with tarfile.open(sys.argv[1]) as archive:
    for member in archive.getmembers():
        parts = member.name.split("/")
        if member.isfile() and parts[1:4] == ["skills", "yomiyasu", "scripts"] and parts[-1] in wanted and len(parts) == 5:
            member.name = parts[-1]
            archive.extract(member, sys.argv[2], filter="data")
' "${tmpdir}/yomiyasu.tar.gz" "${tmpdir}"
LINT="${tmpdir}/yomiyasu_lint.py"
DIFF="${tmpdir}/yomiyasu_diff.py"
[ -f "${LINT}" ] && [ -f "${DIFF}" ] && [ -f "${tmpdir}/markdown_visibility.py" ] \
  || { echo "FAIL: ${url} did not contain the expected scripts" >&2; exit 1; }
echo "fetched: ${url}"

pass_count=0

fail() {
  echo "FAIL: $1" >&2
  echo "yomiyasu regression check FAILED." >&2
  exit 1
}

json_field() {
  python3 -I -c '
import json, sys
print(json.load(open(sys.argv[1], encoding="utf-8"))[sys.argv[2]])
' "$1" "$2"
}

check_lint() {
  local label="$1" fixture="$2" expected="$3"
  local out="${tmpdir}/lint.json" status=0
  python3 -I "${LINT}" "${fixture}" --json >"${out}" || status=$?
  [ "${status}" -eq 0 ] || fail "${label}: lint exited ${status}, expected 0"

  local findings candidates
  findings="$(python3 -I -c '
import json, sys
print(len(json.load(open(sys.argv[1], encoding="utf-8"))["findings"]))
' "${out}")"
  candidates="$(json_field "${out}" candidate_count)"
  [ "${findings}" = "${candidates}" ] || fail "${label}: findings (${findings}) != candidate_count (${candidates})"
  [ "${findings}" = "${expected}" ] || fail "${label}: expected ${expected} findings, got ${findings}"
  echo "PASS: ${label}: ${findings} findings"
  pass_count=$((pass_count + 1))
}

# Asserts the --fail-on meaning-risk contract: exit code and
# fail_on_meaning_risk_count agree with the expected verdict.
check_diff() {
  local label="$1" old="$2" new="$3" expect_risk="$4"
  shift 4
  local out="${tmpdir}/diff.json" status=0
  printf '%s\n' "${old}" >"${tmpdir}/old.md"
  printf '%s\n' "${new}" >"${tmpdir}/new.md"
  python3 -I "${DIFF}" "${tmpdir}/old.md" "${tmpdir}/new.md" --json --fail-on meaning-risk "$@" >"${out}" || status=$?

  local risk_count
  risk_count="$(json_field "${out}" fail_on_meaning_risk_count)"
  if [ "${expect_risk}" = yes ]; then
    [ "${status}" -eq 1 ] || fail "${label}: expected exit 1 (meaning risk), got ${status}"
    [ "${risk_count}" -ge 1 ] || fail "${label}: expected fail_on_meaning_risk_count >= 1, got ${risk_count}"
  else
    [ "${status}" -eq 0 ] || fail "${label}: expected exit 0 (no meaning risk), got ${status}"
    [ "${risk_count}" -eq 0 ] || fail "${label}: expected fail_on_meaning_risk_count 0, got ${risk_count}"
  fi
  echo "PASS: ${label}: exit=${status} fail_on_meaning_risk_count=${risk_count}"
  pass_count=$((pass_count + 1))
}

check_lint "lint ai-smelly.md" "${SMELLY_FIXTURE}" "${EXPECTED_SMELLY_FINDINGS}"
check_lint "lint natural.md" "${NATURAL_FIXTURE}" "${EXPECTED_NATURAL_FINDINGS}"

check_diff "diff dropped number" \
  'この機能は3つの設定を使用できる。' 'この機能は設定を使用できる。' yes
check_diff "diff できる -> 必ずできる (--doc-type pr)" \
  'この機能は設定を使用できる。' 'この機能は設定を必ず使用できる。' yes --doc-type pr
check_diff "diff identical pair" \
  'この機能は3つの設定を使用できる。' 'この機能は3つの設定を使用できる。' no

echo "yomiyasu regression check PASSED (${pass_count} cases)."
