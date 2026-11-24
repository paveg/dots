#!/usr/bin/env bash
# Verify auto-mux execs the multiplexer only for a terminal session, not for a shell asked to run a command.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd "$script_dir/../.." && pwd -P)"
auto_mux="$repo_root/home/dot_config/zsh/init/auto-mux.zsh"

for required_command in script zsh; do
  command -v "$required_command" >/dev/null 2>&1 || {
    echo "required command not found: $required_command" >&2
    exit 1
  }
done

test_root="$(mktemp -d "${TMPDIR:-/tmp}/dots-auto-mux.XXXXXX")"
trap 'rm -rf "$test_root"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

mkdir -p "$test_root/bin" "$test_root/zdotdir"
cat >"$test_root/bin/herdr" <<EOF
#!/bin/sh
echo herdr-started >"$test_root/herdr.marker"
EOF
chmod +x "$test_root/bin/herdr"
printf 'source %q\n' "$auto_mux" >"$test_root/zdotdir/.zshrc"

# util-linux `script` (CI) takes the command as one -c string; BSD `script` (macOS) takes argv.
cat >"$test_root/in-tty" <<'SCRIPT'
#!/usr/bin/env bash
if script --version >/dev/null 2>&1; then
  exec script -qec "$(printf '%q ' "$@")" /dev/null
fi
exec script -q /dev/null "$@"
SCRIPT
chmod +x "$test_root/in-tty"
in_tty=("$test_root/in-tty")

run_zsh() {
  env -i HOME="$test_root" PATH="$test_root/bin:/usr/bin:/bin" \
    AUTO_MUX=herdr ZDOTDIR="$test_root/zdotdir" "$@"
}

# A GUI app probing the login PATH runs `zsh -ilc <cmd>` without a terminal.
rm -f "$test_root/herdr.marker"
output="$(run_zsh zsh -ilc 'echo probe-ran' </dev/null 2>&1)" ||
  fail "zsh -ilc exited non-zero: $output"
[[ "$output" == *probe-ran* ]] || fail "zsh -ilc did not run its command: $output"
[[ ! -e "$test_root/herdr.marker" ]] || fail "zsh -ilc started herdr"

# The same command from a terminal must still run instead of attaching.
rm -f "$test_root/herdr.marker"
output="$(run_zsh "${in_tty[@]}" zsh -ic 'echo tty-command-ran' </dev/null 2>&1)" || true
[[ "$output" == *tty-command-ran* ]] || fail "zsh -ic in a terminal did not run its command: $output"
[[ ! -e "$test_root/herdr.marker" ]] || fail "zsh -ic in a terminal started herdr"

# Positive control: a plain interactive shell in a terminal still starts herdr.
rm -f "$test_root/herdr.marker"
run_zsh "${in_tty[@]}" zsh -i </dev/null >/dev/null 2>&1 || true
[[ -e "$test_root/herdr.marker" ]] || fail "interactive terminal shell did not start herdr"

echo "PASS: auto-mux skips command shells and still starts in a terminal"
