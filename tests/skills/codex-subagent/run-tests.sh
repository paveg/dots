#!/usr/bin/env bash
# Tests for home/dot_claude/skills/codex-subagent/scripts/dispatch.sh
#
# Stubs `codex` via PATH; the stub records the assembled prompt and writes a
# minimal final message to the --output-last-message file, so dispatch.sh can
# be exercised without the real CLI.
set -uo pipefail
cd "$(dirname "$0")" || exit 1
SCRIPT="$(cd ../../.. && pwd)/home/dot_claude/skills/codex-subagent/scripts/dispatch.sh"

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT
mkdir -p "$workdir/bin"

cat >"$workdir/bin/codex" <<'FAKE'
#!/usr/bin/env bash
out=""
prev=""
for arg in "$@"; do
  [[ $prev == --output-last-message ]] && out=$arg
  prev=$arg
done
cat >"$CODEX_STUB_PROMPT"
printf 'STATUS: DONE\nRESULT: stub result\n' >"$out"
FAKE
chmod +x "$workdir/bin/codex"

export PATH="$workdir/bin:$PATH"
export CODEX_STUB_PROMPT="$workdir/prompt.txt"

pass=0
fail=0
check() {
  local name=$1 expected=$2 actual=$3
  if [[ "$actual" == "$expected" ]]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    echo "FAIL: $name (expected: $expected, actual: $actual)" >&2
  fi
}

# 1. stdin (heredoc) path keeps working
: >"$CODEX_STUB_PROMPT"
output=$(bash "$SCRIPT" --cd "$workdir" <<<'task-via-stdin' 2>&1)
check "stdin: exit 0" 0 $?
check "stdin: final message printed" 0 "$(grep -q 'STATUS: DONE' <<<"$output"; echo $?)"
check "stdin: task reached codex" 0 "$(grep -q 'task-via-stdin' "$CODEX_STUB_PROMPT"; echo $?)"
check "stdin: contract wraps task" 0 "$(grep -q '<subagent_contract>' "$CODEX_STUB_PROMPT"; echo $?)"

# 2. --task-file reads the task from a file (no stdin needed)
: >"$CODEX_STUB_PROMPT"
printf 'task-via-file\n' >"$workdir/task.md"
output=$(bash "$SCRIPT" --task-file "$workdir/task.md" --cd "$workdir" </dev/null 2>&1)
check "task-file: exit 0" 0 $?
check "task-file: final message printed" 0 "$(grep -q 'STATUS: DONE' <<<"$output"; echo $?)"
check "task-file: task reached codex" 0 "$(grep -q 'task-via-file' "$CODEX_STUB_PROMPT"; echo $?)"

# 3. --task-file with a missing file fails with a clear error
output=$(bash "$SCRIPT" --task-file "$workdir/nope.md" --cd "$workdir" </dev/null 2>&1)
status=$?
check "missing task-file: nonzero exit" 1 "$(((status == 0)) && echo 0 || echo 1)"
check "missing task-file: names the path" 0 "$(grep -q 'nope.md' <<<"$output"; echo $?)"

# 4. empty task is rejected
output=$(bash "$SCRIPT" --cd "$workdir" </dev/null 2>&1)
check "empty task: exit 64" 64 $?

echo "codex-subagent dispatch tests: $pass passed, $fail failed"
((fail == 0)) || exit 1
