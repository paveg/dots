#!/usr/bin/env bash
# Test runner for dot_claude/hooks/*.sh
#
# Each *.test.sh in this directory is invoked with HOOKS_DIR set to the
# chezmoi source dir (dot_claude/hooks). Tests use bash to execute hook
# scripts directly, so the executable bit and chezmoi prefix do not matter.
set -uo pipefail

cd "$(dirname "$0")"
export HOOKS_DIR
HOOKS_DIR="$(cd "../../dot_claude/hooks" && pwd)"

pass=0
fail=0
failed_tests=()
out=$(mktemp)
trap 'rm -f "$out"' EXIT

for test in *.test.sh; do
  [[ -f $test ]] || continue
  name=${test%.test.sh}
  if bash "$test" >"$out" 2>&1; then
    printf '  ok   %s\n' "$name"
    pass=$((pass + 1))
  else
    printf '  FAIL %s\n' "$name"
    sed 's/^/       /' "$out"
    fail=$((fail + 1))
    failed_tests+=("$name")
  fi
done

echo
echo "passed: $pass  failed: $fail"
[[ $fail -eq 0 ]]
