#!/usr/bin/env bash
# Test runner for dot_claude/hooks/*.sh
#
# Each *.test.sh in this directory is invoked with HOOKS_DIR set to the
# chezmoi source dir (dot_claude/hooks). Tests use bash to execute hook
# scripts directly, so the executable bit and chezmoi prefix do not matter.
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd -P)"
repo_root="$(cd "$script_dir/../.." && pwd -P)"
source_root="$repo_root"

if [[ -f "$repo_root/.chezmoiroot" ]]; then
  source_relative=""
  extra_line=""
  exec 3<"$repo_root/.chezmoiroot"
  IFS= read -r source_relative <&3 || [[ -n "$source_relative" ]]
  if IFS= read -r extra_line <&3 || [[ -n "$extra_line" ]]; then
    echo ".chezmoiroot must contain exactly one relative path" >&2
    exit 1
  fi
  exec 3<&-

  case "$source_relative" in
    "")
      echo ".chezmoiroot must not be empty" >&2
      exit 1
      ;;
    /*)
      echo ".chezmoiroot must be relative: $source_relative" >&2
      exit 1
      ;;
  esac
  case "/$source_relative/" in
    */../*)
      echo ".chezmoiroot must not contain parent traversal: $source_relative" >&2
      exit 1
      ;;
  esac

  if [[ ! -d "$repo_root/$source_relative" ]]; then
    echo "chezmoi source root not found: $repo_root/$source_relative" >&2
    exit 1
  fi
  source_root="$(cd "$repo_root/$source_relative" && pwd -P)"
  case "$source_root" in
    "$repo_root" | "$repo_root"/*) ;;
    *)
      echo "chezmoi source root escapes repository: $source_root" >&2
      exit 1
      ;;
  esac
fi

claude_source="$source_root/dot_claude"

if [[ ! -d "$claude_source/hooks" ]]; then
  echo "Claude source directory not found: $claude_source" >&2
  exit 1
fi

tmp_parent="${TMPDIR:-/tmp}"
tmp_parent="${tmp_parent%/}"
test_home="$(mktemp -d "$tmp_parent/dots-hook-tests.XXXXXX")"
case "$test_home" in
  "$tmp_parent"/dots-hook-tests.*) ;;
  *)
    echo "Unexpected temporary HOME: $test_home" >&2
    exit 1
    ;;
esac

cleanup() {
  case "$test_home" in
    "$tmp_parent"/dots-hook-tests.*)
      [[ ! -d "$test_home" ]] || rm -rf -- "$test_home"
      ;;
  esac
}
trap cleanup EXIT

ln -s "$claude_source" "$test_home/.claude"
export HOME="$test_home"
export HOOKS_DIR="$claude_source/hooks"

pass=0
fail=0
test_count=0
failed_tests=()
out="$test_home/test-output"

cd "$script_dir"
for test in *.test.sh; do
  [[ -f $test ]] || continue
  test_count=$((test_count + 1))
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

if ((test_count == 0)); then
  echo "No hook tests found in $script_dir" >&2
  exit 1
fi

echo
echo "tests: $test_count  passed: $pass  failed: $fail"
[[ $fail -eq 0 ]]
