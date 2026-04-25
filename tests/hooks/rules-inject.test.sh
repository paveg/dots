#!/usr/bin/env bash
# Tests for executable_rules-inject.sh: single dispatcher that injects
# path-relevant rule files (chezmoi, react, drizzle) into additionalContext.
set -uo pipefail

hook="$HOOKS_DIR/executable_rules-inject.sh"
[[ -f $hook ]] || { echo "hook not found: $hook"; exit 1; }

run() { printf '%s' "$1" | bash "$hook"; }
contains() {
  echo "$1" | jq -e --arg s "$2" '.hookSpecificOutput.additionalContext | contains($s)' >/dev/null
}

# === No match: should produce no output ===
out=$(run '{"tool_input":{"file_path":"foo.py"}}')
[[ -z $out ]] || { echo "fired on .py: $out"; exit 1; }

out=$(run '{"tool_input":{}}')
[[ -z $out ]] || { echo "fired on missing file_path: $out"; exit 1; }

# === chezmoi: any file under chezmoi source tree ===
out=$(run '{"tool_input":{"file_path":"/Users/x/.local/share/chezmoi/dot_zshrc"}}')
contains "$out" "chezmoi" || { echo "chezmoi rule not injected: $out"; exit 1; }

# === react: .tsx / .jsx ===
out=$(run '{"tool_input":{"file_path":"src/App.tsx"}}')
contains "$out" "React Conventions" || { echo "react rule not injected for .tsx: $out"; exit 1; }

out=$(run '{"tool_input":{"file_path":"src/App.jsx"}}')
contains "$out" "React Conventions" || { echo "react rule not injected for .jsx: $out"; exit 1; }

# === drizzle: schema, config, drizzle/ dir ===
out=$(run '{"tool_input":{"file_path":"db/schema.ts"}}')
contains "$out" "Drizzle" || { echo "drizzle rule not injected for schema.ts: $out"; exit 1; }

out=$(run '{"tool_input":{"file_path":"drizzle.config.ts"}}')
contains "$out" "Drizzle" || { echo "drizzle rule not injected for drizzle.config.ts: $out"; exit 1; }

out=$(run '{"tool_input":{"file_path":"src/drizzle/migrations/0001_init.sql"}}')
contains "$out" "Drizzle" || { echo "drizzle rule not injected for drizzle/ path: $out"; exit 1; }

# === Multiple matches: schema.tsx hits both drizzle and react ===
out=$(run '{"tool_input":{"file_path":"db/schema.tsx"}}')
contains "$out" "Drizzle" || { echo "drizzle not injected for schema.tsx: $out"; exit 1; }
contains "$out" "React Conventions" || { echo "react not injected for schema.tsx: $out"; exit 1; }

# === Edge: file with .tsx in directory name but not extension ===
out=$(run '{"tool_input":{"file_path":"my.tsx.dir/note.md"}}')
[[ -z $out ]] || { echo "fired on non-tsx file with .tsx in path: $out"; exit 1; }

# === Performance check: single bash + jq invocation by design ===
# (verified by inspecting the dispatcher source — no per-rule subprocess)
