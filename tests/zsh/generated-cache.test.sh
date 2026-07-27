#!/usr/bin/env bash
# shellcheck disable=SC2016
# Verify generated zsh caches are validated and atomically published.
# Single-quoted programs below are evaluated by child zsh.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd "$script_dir/../.." && pwd -P)"
helper="$repo_root/home/dot_config/zsh/init/generated-cache.zsh"

for required_command in chezmoi cmp grep just mkfifo stat zsh; do
  command -v "$required_command" >/dev/null 2>&1 || {
    echo "required command not found: $required_command" >&2
    exit 1
  }
done

test_root="$(mktemp -d "${TMPDIR:-/tmp}/dots-generated-cache.XXXXXX")"
atomic_writer_pid=""
cleanup() {
  if [[ -n "$atomic_writer_pid" ]] && kill -0 "$atomic_writer_pid" 2>/dev/null; then
    kill "$atomic_writer_pid" 2>/dev/null || true
    wait "$atomic_writer_pid" 2>/dev/null || true
  fi
  rm -rf -- "$test_root"
}
trap cleanup EXIT

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

pass() {
  echo "PASS: $1"
}

assert_no_temps() {
  local target="$1"

  if compgen -G "${target}.payload.*" >/dev/null ||
    compgen -G "${target}.publish.*" >/dev/null; then
    fail "temporary cache files remain for $target"
  fi
}

file_mode() {
  local file="$1"

  if stat -f '%Lp' "$file" >/dev/null 2>&1; then
    stat -f '%Lp' "$file"
  else
    stat -c '%a' "$file"
  fi
}

cache_dir="$test_root/helper"
mkdir -p "$cache_dir"

initial_cache="$cache_dir/initial.zsh"
env HELPER="$helper" TARGET="$initial_cache" zsh -f -c '
  set -e
  source "$HELPER"
  generate_success() {
    print -r -- "export GENERATED_CACHE_VALUE=initial"
  }
  _zsh_cache_prepare "$TARGET" 0 "test-v1" generate_success
  source "$TARGET"
  [[ "$GENERATED_CACHE_VALUE" == initial ]]
'
[[ -s "$initial_cache" ]] || fail "initial success did not publish a cache"
[[ "$(sed -n '1p' "$initial_cache")" == "# dots-generated-zsh-cache-v1" ]] ||
  fail "published cache is missing its helper marker"
[[ "$(sed -n '2p' "$initial_cache")" == "# fingerprint: test-v1" ]] ||
  fail "published cache is missing its fingerprint"
[[ "$(file_mode "$initial_cache")" == "600" ]] ||
  fail "published cache mode is not 0600"
assert_no_temps "$initial_cache"
pass "initial success publishes validated mode-0600 cache"

partial_cache="$cache_dir/partial.zsh"
partial_output="$test_root/partial.out"
if env HELPER="$helper" TARGET="$partial_cache" zsh -f -c '
  set -e
  source "$HELPER"
  generate_partial_failure() {
    print -r -- "export PARTIAL_CACHE_VALUE=must-not-run"
    return 23
  }
  _zsh_cache_prepare "$TARGET" 0 "partial-v1" generate_partial_failure
' >"$partial_output" 2>&1; then
  fail "partial nonzero generator unexpectedly succeeded"
fi
[[ ! -e "$partial_cache" ]] ||
  fail "partial nonzero generator published its output"
grep -Fq "$partial_cache" "$partial_output" ||
  fail "partial failure warning did not name the cache"
assert_no_temps "$partial_cache"
pass "partial nonzero output is rejected"

empty_cache="$cache_dir/empty.zsh"
if env HELPER="$helper" TARGET="$empty_cache" zsh -f -c '
  set -e
  source "$HELPER"
  generate_empty() {
    return 0
  }
  _zsh_cache_prepare "$TARGET" 0 "empty-v1" generate_empty
' >/dev/null 2>&1; then
  fail "empty generator unexpectedly succeeded"
fi
[[ ! -e "$empty_cache" ]] || fail "empty generator published a cache"
assert_no_temps "$empty_cache"
pass "empty successful output is rejected"

syntax_cache="$cache_dir/syntax.zsh"
if env HELPER="$helper" TARGET="$syntax_cache" zsh -f -c '
  set -e
  source "$HELPER"
  generate_invalid() {
    print -r -- "export VALID_PREFIX=must-not-run"
    print -r -- "broken=("
  }
  _zsh_cache_prepare "$TARGET" 0 "syntax-v1" generate_invalid
' >/dev/null 2>&1; then
  fail "syntax-invalid generator unexpectedly succeeded"
fi
[[ ! -e "$syntax_cache" ]] ||
  fail "syntax-invalid generator published a cache"
assert_no_temps "$syntax_cache"
pass "syntax-invalid output is rejected before source"

lkg_cache="$cache_dir/lkg.zsh"
lkg_copy="$test_root/lkg.expected"
env HELPER="$helper" TARGET="$lkg_cache" zsh -f -c '
  set -e
  source "$HELPER"
  generate_lkg() {
    print -r -- "export LKG_CACHE_VALUE=preserved"
  }
  _zsh_cache_prepare "$TARGET" 0 "lkg-v1" generate_lkg
'
cp "$lkg_cache" "$lkg_copy"
env HELPER="$helper" TARGET="$lkg_cache" zsh -f -c '
  set -e
  source "$HELPER"
  generate_failed_refresh() {
    print -r -- "export LKG_CACHE_VALUE=corrupt"
    return 24
  }
  _zsh_cache_prepare "$TARGET" 1 "lkg-v1" generate_failed_refresh
  source "$TARGET"
  [[ "$LKG_CACHE_VALUE" == preserved ]]
' >/dev/null 2>&1
cmp -s "$lkg_copy" "$lkg_cache" ||
  fail "failed refresh changed last-known-good cache bytes"
assert_no_temps "$lkg_cache"
pass "failed refresh preserves and permits matching last-known-good cache"

fingerprint_cache="$cache_dir/fingerprint.zsh"
env HELPER="$helper" TARGET="$fingerprint_cache" zsh -f -c '
  set -e
  source "$HELPER"
  generate_v1() {
    print -r -- "export FINGERPRINT_CACHE_VALUE=v1"
  }
  _zsh_cache_prepare "$TARGET" 0 "fingerprint-v1" generate_v1
'
env HELPER="$helper" TARGET="$fingerprint_cache" zsh -f -c '
  set -e
  source "$HELPER"
  generate_v2() {
    print -r -- "export FINGERPRINT_CACHE_VALUE=v2"
  }
  _zsh_cache_prepare "$TARGET" 0 "fingerprint-v2" generate_v2
  source "$TARGET"
  [[ "$FINGERPRINT_CACHE_VALUE" == v2 ]]
'
grep -Fxq '# fingerprint: fingerprint-v2' "$fingerprint_cache" ||
  fail "fingerprint mismatch did not publish the new identity"
pass "fingerprint mismatch refreshes the cache"

retry_cache="$cache_dir/retry.zsh"
if env HELPER="$helper" TARGET="$retry_cache" zsh -f -c '
  set -e
  source "$HELPER"
  fail_first_attempt() {
    return 25
  }
  _zsh_cache_prepare "$TARGET" 0 "retry-v1" fail_first_attempt
' >/dev/null 2>&1; then
  fail "initial failed generation unexpectedly succeeded"
fi
[[ ! -e "$retry_cache" ]] ||
  fail "initial failure left a final cache that suppresses retry"
env HELPER="$helper" TARGET="$retry_cache" zsh -f -c '
  set -e
  source "$HELPER"
  retry_success() {
    print -r -- "export RETRY_CACHE_VALUE=ready"
  }
  _zsh_cache_prepare "$TARGET" 0 "retry-v1" retry_success
  source "$TARGET"
  [[ "$RETRY_CACHE_VALUE" == ready ]]
'
assert_no_temps "$retry_cache"
pass "initial failure leaves no final and the next attempt succeeds"

markerless_cache="$cache_dir/markerless.zsh"
printf '%s\n' 'export MARKERLESS_CACHE_VALUE=must-not-run' >"$markerless_cache"
markerless_copy="$test_root/markerless.expected"
cp "$markerless_cache" "$markerless_copy"
if env HELPER="$helper" TARGET="$markerless_cache" zsh -f -c '
  set -e
  source "$HELPER"
  fail_markerless_refresh() {
    return 26
  }
  _zsh_cache_prepare "$TARGET" 0 "markerless-v1" fail_markerless_refresh
' >/dev/null 2>&1; then
  fail "markerless cache was accepted as a fallback"
fi
cmp -s "$markerless_copy" "$markerless_cache" ||
  fail "failed markerless migration changed the old file"
pass "markerless cache is never accepted as fallback source"

symlink_target="$cache_dir/symlink.zsh"
symlink_victim="$test_root/symlink-victim"
printf '%s\n' 'victim-must-stay' >"$symlink_victim"
ln -s "$symlink_victim" "$symlink_target"
if env HELPER="$helper" TARGET="$symlink_target" zsh -f -c '
  set -e
  source "$HELPER"
  generate_for_symlink() {
    print -r -- "export SYMLINK_CACHE_VALUE=unsafe"
  }
  _zsh_cache_prepare "$TARGET" 0 "symlink-v1" generate_for_symlink
' >/dev/null 2>&1; then
  fail "symlink cache target was accepted"
fi
[[ -L "$symlink_target" ]] || fail "symlink cache target was replaced"
[[ "$(<"$symlink_victim")" == "victim-must-stay" ]] ||
  fail "symlink victim was modified"
pass "symlink target is rejected without following it"

directory_target="$cache_dir/directory.zsh"
mkdir "$directory_target"
if env HELPER="$helper" TARGET="$directory_target" zsh -f -c '
  set -e
  source "$HELPER"
  generate_for_directory() {
    print -r -- "export DIRECTORY_CACHE_VALUE=unsafe"
  }
  _zsh_cache_prepare "$TARGET" 0 "directory-v1" generate_for_directory
' >/dev/null 2>&1; then
  fail "directory cache target was accepted"
fi
[[ -d "$directory_target" ]] || fail "directory cache target was replaced"
pass "directory target is rejected"

atomic_cache="$cache_dir/atomic.zsh"
env HELPER="$helper" TARGET="$atomic_cache" zsh -f -c '
  set -e
  source "$HELPER"
  generate_old() {
    print -r -- "export ATOMIC_CACHE_VALUE=old"
    print -r -- "export ATOMIC_CACHE_COMPLETE=1"
  }
  _zsh_cache_prepare "$TARGET" 0 "atomic-v1" generate_old
'
ready_fifo="$test_root/atomic-ready.fifo"
continue_fifo="$test_root/atomic-continue.fifo"
done_fifo="$test_root/atomic-done.fifo"
mkfifo "$ready_fifo" "$continue_fifo" "$done_fifo"
exec 8<>"$ready_fifo"
exec 9<>"$continue_fifo"
exec 10<>"$done_fifo"
atomic_writer_output="$test_root/atomic-writer.out"
(
  set +e
  env \
    HELPER="$helper" \
    TARGET="$atomic_cache" \
    READY_FIFO="$ready_fifo" \
    CONTINUE_FIFO="$continue_fifo" \
    zsh -f -c '
      set -e
      source "$HELPER"
      generate_slow() {
        print -r -- "export ATOMIC_CACHE_VALUE=new"
        print -r -- ready > "$READY_FIFO"
        IFS= read -r continue_signal < "$CONTINUE_FIFO"
        [[ "$continue_signal" == continue ]]
        print -r -- "export ATOMIC_CACHE_COMPLETE=1"
      }
      _zsh_cache_prepare "$TARGET" 1 "atomic-v1" generate_slow
    '
  writer_status=$?
  printf '%s\n' "$writer_status" >"$done_fifo"
  exit "$writer_status"
) >"$atomic_writer_output" 2>&1 &
atomic_writer_pid=$!
if ! IFS= read -r -t 10 ready_signal <&8; then
  kill "$atomic_writer_pid" 2>/dev/null || true
  wait "$atomic_writer_pid" 2>/dev/null || true
  atomic_writer_pid=""
  sed 's/^/  /' "$atomic_writer_output" >&2
  fail "atomic writer did not become ready before timeout"
fi
[[ "$ready_signal" == "ready" ]] || fail "atomic writer did not become ready"
env TARGET="$atomic_cache" zsh -f -c '
  set -e
  command zsh -f -n "$TARGET"
  source "$TARGET"
  [[ "$ATOMIC_CACHE_VALUE" == old ]]
  [[ "$ATOMIC_CACHE_COMPLETE" == 1 ]]
' || fail "reader observed an incomplete cache while writer was paused"
printf '%s\n' continue >&9
exec 8>&-
exec 9>&-
if ! IFS= read -r -t 10 atomic_writer_status <&10; then
  kill "$atomic_writer_pid" 2>/dev/null || true
  wait "$atomic_writer_pid" 2>/dev/null || true
  atomic_writer_pid=""
  sed 's/^/  /' "$atomic_writer_output" >&2
  fail "atomic writer did not finish before timeout"
fi
exec 10>&-
if ! wait "$atomic_writer_pid" || [[ "$atomic_writer_status" != "0" ]]; then
  sed 's/^/  /' "$atomic_writer_output" >&2
  fail "atomic writer failed"
fi
atomic_writer_pid=""
env TARGET="$atomic_cache" zsh -f -c '
  set -e
  command zsh -f -n "$TARGET"
  source "$TARGET"
  [[ "$ATOMIC_CACHE_VALUE" == new ]]
  [[ "$ATOMIC_CACHE_COMPLETE" == 1 ]]
' || fail "reader did not observe the complete new cache"
assert_no_temps "$atomic_cache"
pass "FIFO-coordinated reader sees only complete old or new cache"

render_root="$test_root/rendered"
runtime_home="$test_root/runtime/home"
runtime_config="$test_root/runtime/config"
runtime_cache="$test_root/runtime/cache"
runtime_data="$test_root/runtime/data"
runtime_state="$test_root/runtime/state"
fake_bin="$test_root/runtime/bin"
mkdir -p \
  "$render_root" \
  "$runtime_home" \
  "$runtime_config" \
  "$runtime_cache/devbox" \
  "$runtime_data/devbox/global/default" \
  "$runtime_state" \
  "$fake_bin"

chezmoi_config="$test_root/chezmoi.json"
printf '{}\n' >"$chezmoi_config"

render_profile() {
  local profile="$1"
  local business_use="$2"
  local rendered="$render_root/$profile.zshenv"
  local data

  data="{\"business_use\":$business_use,\"homebrew_prefix\":\"/opt/homebrew\"}"
  chezmoi \
    --config "$chezmoi_config" \
    --config-format json \
    --source "$repo_root" \
    --destination "$runtime_home" \
    --override-data "$data" \
    execute-template --file "$repo_root/home/dot_zshenv.tmpl" >"$rendered"
  zsh -n "$rendered"
  [[ "$(grep -Fc 'devbox global shellenv --pure' "$rendered")" == "1" ]] ||
    fail "$profile render does not call pure Devbox shellenv exactly once"
  [[ "$(grep -Fc "if _zsh_cache_prepare \\" "$rendered")" == "1" ]] ||
    fail "$profile render does not wire generated-cache helper exactly once"
  grep -Fq 'shellenv-pure.zsh' "$rendered" ||
    fail "$profile render does not use the new pure cache"
}

render_profile personal false
render_profile business true
pass "personal and business zshenv renders wire pure generated cache"

env \
  "HOME=$runtime_home" \
  "XDG_CONFIG_HOME=$runtime_config" \
  "XDG_CACHE_HOME=$runtime_cache" \
  "XDG_DATA_HOME=$runtime_data" \
  "XDG_STATE_HOME=$runtime_state" \
  "PATH=/usr/bin:/bin" \
  "RENDERED_ZSHENV=$render_root/personal.zshenv" \
  zsh -f -c '
    set -e
    source "$RENDERED_ZSHENV"
    [[ -z ${STATIC_DEVBOX_VALUE+x} ]]
    (( ${path[(Ie)/usr/bin]} > 0 ))
    (( ${path[(Ie)/bin]} > 0 ))
  '
pass "zshenv remains fail-safe when Devbox is unavailable"

devbox_args_log="$test_root/devbox-args.log"
devbox_script="$fake_bin/devbox"
cat >"$devbox_script" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "$*" >>"$DEVBOX_ARGS_LOG"
[[ "$*" == "global shellenv --pure" ]] || exit 70
if [[ "${DEVBOX_FAIL_IF_CALLED:-0}" == "1" ]]; then
  printf '%s\n' 'export DEVBOX_PARTIAL_VALUE="must-not-run"'
  exit 71
fi

printf 'export STATIC_DEVBOX_VALUE="%s"\n' "${DEVBOX_OUTPUT_VALUE:-initial}"
printf '%s\n' 'export PATH="/fake/devbox/bin"'
printf '%s\n' 'export MANPATH="/fake/devbox/man"'
printf '%s\n' 'export INFOPATH="/fake/devbox/info"'
printf '%s\n' 'export XDG_DATA_DIRS="/fake/devbox/share"'
printf '%s\n' 'export DEVBOX_PURE_SHELL="1"'
printf '%s\n' 'export HOME="/poison/home"'
printf '%s\n' 'export USER="poison-user"'
printf '%s\n' 'export LOGNAME="poison-logname"'
printf '%s\n' 'export DISPLAY="poison-display"'
printf '%s\n' 'export PWD="/poison/pwd"'
printf '%s\n' 'export OLDPWD="/poison/oldpwd"'
printf '%s\n' 'export SHLVL="999"'
printf '%s\n' 'export _="poison-underscore"'
printf '%s\n' 'export TMUX="poison-tmux"'
printf '%s\n' 'export TERM_PROGRAM="poison-terminal"'
printf '%s\n' 'export SSH_AUTH_SOCK="/poison/agent"'
printf '%s\n' 'export TMPDIR="/poison/tmp"'
printf '%s\n' 'export TERM_SESSION_ID="poison-session"'
printf '%s\n' 'export SECURITYSESSIONID="poison-security"'
printf '%s\n' 'export HERDR_SESSION="poison-herdr"'
printf 'export ARBITRARY_SECRET_SENTINEL="%s"\n' "$ARBITRARY_SECRET_SENTINEL"
EOF
chmod +x "$devbox_script"

legacy_cache="$runtime_cache/devbox/shellenv.zsh"
pure_cache="$runtime_cache/devbox/shellenv-pure.zsh"
printf '%s\n' 'export LEGACY_CACHE_WAS_SOURCED=1' >"$legacy_cache"
printf '{}\n' >"$runtime_data/devbox/global/default/devbox.json"

run_rendered_zshenv() {
  local rendered="$1"
  local output_value="$2"
  local fail_if_called="$3"

  env \
    "HOME=$runtime_home" \
    "USER=current-user" \
    "LOGNAME=current-logname" \
    "DISPLAY=current-display" \
    "TERM=xterm-current" \
    "TMUX=current-tmux" \
    "SSH_AUTH_SOCK=/current/agent" \
    "TMPDIR=$test_root/runtime/tmp" \
    "TERM_SESSION_ID=current-term-session" \
    "SECURITYSESSIONID=current-security-session" \
    "HERDR_SESSION=current-herdr" \
    "ARBITRARY_SECRET_SENTINEL=do-not-persist" \
    "DEVBOX_ARGS_LOG=$devbox_args_log" \
    "DEVBOX_OUTPUT_VALUE=$output_value" \
    "DEVBOX_FAIL_IF_CALLED=$fail_if_called" \
    "XDG_CONFIG_HOME=$runtime_config" \
    "XDG_CACHE_HOME=$runtime_cache" \
    "XDG_DATA_HOME=$runtime_data" \
    "XDG_DATA_DIRS=/baseline/share" \
    "XDG_STATE_HOME=$runtime_state" \
    "MANPATH=/baseline/man" \
    "INFOPATH=/baseline/info" \
    "PATH=$fake_bin:/opt/homebrew/bin:/usr/bin:/bin" \
    "RENDERED_ZSHENV=$rendered" \
    zsh -f -c '
      set -e
      colon_component_once() {
        local value="$1"
        local expected="$2"
        local component
        local count=0

        for component in "${(@s/:/)value}"; do
          if [[ "$component" == "$expected" ]]; then
            count=$((count + 1))
          fi
        done
        [[ "$count" == 1 ]]
      }

      source "$RENDERED_ZSHENV"
      source "$RENDERED_ZSHENV"
      [[ "$HOME" == "$0" ]] || exit 80
      [[ "$USER" == current-user ]] || exit 81
      [[ "$LOGNAME" == current-logname ]] || exit 82
      [[ "$DISPLAY" == current-display ]] || exit 83
      [[ "$TERM" == xterm-current ]] || exit 84
      [[ "$TMUX" == current-tmux ]] || exit 85
      [[ "$SSH_AUTH_SOCK" == /current/agent ]] || exit 86
      [[ "$TMPDIR" == "$2" ]] || exit 87
      [[ "$TERM_SESSION_ID" == current-term-session ]] || exit 88
      [[ "$SECURITYSESSIONID" == current-security-session ]] || exit 89
      [[ "$HERDR_SESSION" == current-herdr ]] || exit 90
      [[ "$ARBITRARY_SECRET_SENTINEL" == do-not-persist ]] || exit 91
      [[ -z ${LEGACY_CACHE_WAS_SOURCED+x} ]] || exit 92
      [[ -z ${DEVBOX_PURE_SHELL+x} ]] || exit 93
      [[ -z ${DEVBOX_PARTIAL_VALUE+x} ]] || exit 94
      (( ${path[(Ie)/fake/devbox/bin]} > 0 )) || exit 95
      (( ${path[(Ie)/opt/homebrew/bin]} > 0 )) || exit 96
      (( ${path[(Ie)/usr/bin]} > 0 )) || exit 97
      (( ${path[(Ie)/bin]} > 0 )) || exit 98
      (( ${path[(Ie)/fake/devbox/bin]} < ${path[(Ie)/usr/bin]} )) || exit 99
      (( ${path[(Ie)/fake/devbox/bin]} < ${path[(Ie)/opt/homebrew/bin]} )) || exit 100
      [[ ":$MANPATH:" == *":/fake/devbox/man:"* ]] || exit 101
      [[ ":$MANPATH:" == *":/baseline/man:"* ]] || exit 102
      [[ ":$INFOPATH:" == *":/fake/devbox/info:"* ]] || exit 103
      [[ ":$INFOPATH:" == *":/baseline/info:"* ]] || exit 104
      [[ ":$XDG_DATA_DIRS:" == *":/fake/devbox/share:"* ]] || exit 105
      [[ ":$XDG_DATA_DIRS:" == *":/baseline/share:"* ]] || exit 106
      [[ "$STATIC_DEVBOX_VALUE" == "$1" ]] || exit 107
      colon_component_once "$MANPATH" /fake/devbox/man || exit 108
      colon_component_once "$MANPATH" /baseline/man || exit 109
      colon_component_once "$INFOPATH" /fake/devbox/info || exit 110
      colon_component_once "$INFOPATH" /baseline/info || exit 111
      colon_component_once "$XDG_DATA_DIRS" /fake/devbox/share || exit 112
      colon_component_once "$XDG_DATA_DIRS" /baseline/share || exit 113
      colon_component_once "$PATH" /fake/devbox/bin || exit 114
      colon_component_once "$PATH" /opt/homebrew/bin || exit 115
      colon_component_once "$PATH" /usr/bin || exit 116
      colon_component_once "$PATH" /bin || exit 117
    ' "$runtime_home" "$output_value" "$test_root/runtime/tmp"
}

mkdir -p "$test_root/runtime/tmp"
run_rendered_zshenv "$render_root/personal.zshenv" initial 0 ||
  fail "pure Devbox cache did not preserve the current shell"
[[ ! -e "$legacy_cache" && ! -L "$legacy_cache" ]] ||
  fail "legacy Devbox cache was not removed"
[[ -s "$pure_cache" ]] || fail "pure Devbox cache was not created"
[[ "$(file_mode "$pure_cache")" == "600" ]] ||
  fail "pure Devbox cache mode is not 0600"
grep -Fxq 'global shellenv --pure' "$devbox_args_log" ||
  fail "Devbox was not invoked with global shellenv --pure"
if grep -Eq 'poison-|do-not-persist|ARBITRARY_SECRET_SENTINEL|DEVBOX_PURE_SHELL|^(export )?(HOME|USER|LOGNAME|DISPLAY|PWD|OLDPWD|SHLVL|_|TMUX|TERM|SSH_AUTH_SOCK|TMPDIR|SECURITYSESSIONID|HERDR_)=' "$pure_cache"; then
  fail "pure Devbox cache persisted inherited, session, or secret data"
fi
pass "Devbox pure cache filters secrets and preserves runtime search paths"

rm -f "$devbox_args_log"
run_rendered_zshenv "$render_root/personal.zshenv" initial 1 ||
  fail "warm pure cache did not load without invoking Devbox"
[[ ! -e "$devbox_args_log" ]] ||
  fail "warm pure cache unexpectedly invoked Devbox"
pass "warm pure cache uses builtin metadata hit without regeneration"

touch -t 201901010000 "$devbox_script"
touch -t 202101010000 "$pure_cache"
touch -t 202201010000 "$runtime_data/devbox/global/default/devbox.json"
run_rendered_zshenv "$render_root/personal.zshenv" refreshed 0 ||
  fail "manifest refresh did not regenerate pure Devbox cache"
grep -Fxq 'global shellenv --pure' "$devbox_args_log" ||
  fail "newer active manifest did not invoke Devbox"
grep -Fq 'export STATIC_DEVBOX_VALUE="refreshed"' "$pure_cache" ||
  fail "manifest refresh did not publish the refreshed cache"
assert_no_temps "$pure_cache"
pass "newer active manifest refreshes the cache atomically"

failed_refresh_copy="$test_root/devbox-lkg.expected"
cp "$pure_cache" "$failed_refresh_copy"
touch -t 201901010000 "$devbox_script"
touch -t 202101010000 "$pure_cache"
touch -t 202201010000 "$runtime_data/devbox/global/default/devbox.json"
run_rendered_zshenv "$render_root/personal.zshenv" refreshed 1 ||
  fail "failed Devbox refresh did not preserve the last-known-good cache"
cmp -s "$failed_refresh_copy" "$pure_cache" ||
  fail "failed Devbox refresh changed the last-known-good cache"
pass "partial Devbox failure is hidden by pipefail and preserves last-known-good"

rm -f "$devbox_args_log"
touch -t 201901010000 "$runtime_data/devbox/global/default/devbox.json"
touch -t 202101010000 "$pure_cache"
touch -t 202201010000 "$devbox_script"
run_rendered_zshenv "$render_root/personal.zshenv" binary-refreshed 0 ||
  fail "newer Devbox binary did not regenerate the cache"
grep -Fq 'export STATIC_DEVBOX_VALUE="binary-refreshed"' "$pure_cache" ||
  fail "binary refresh did not publish the refreshed cache"
pass "newer resolved Devbox binary refreshes the cache"

rm -f "$devbox_args_log"
touch -t 201901010000 "$runtime_data/devbox/global/default/devbox.json"
touch -t 201901010000 "$devbox_script"
touch -t 202101010000 "$pure_cache"
printf '{}\n' >"$runtime_data/devbox/global/default/devbox.lock"
touch -t 202201010000 "$runtime_data/devbox/global/default/devbox.lock"
run_rendered_zshenv "$render_root/personal.zshenv" lock-refreshed 0 ||
  fail "newer Devbox lock did not regenerate the cache"
grep -Fq 'export STATIC_DEVBOX_VALUE="lock-refreshed"' "$pure_cache" ||
  fail "lock refresh did not publish the refreshed cache"
pass "newer active Devbox lock refreshes the cache"

cleanup_cache="$test_root/cleanup-cache"
cleanup_data="$test_root/cleanup-data"
populate_cleanup_cache() {
  mkdir -p \
    "$cleanup_cache/zsh/init" \
    "$cleanup_cache/devbox" \
    "$cleanup_cache/p10k-fixture"
  printf '%s\n' stale >"$cleanup_cache/devbox/shellenv.zsh"
  printf '%s\n' stale >"$cleanup_cache/devbox/shellenv-pure.zsh"
}

assert_cleanup_cache_removed() {
  [[ ! -e "$cleanup_cache/zsh/init" ]] ||
    fail "cleanup left the zsh init cache"
  [[ ! -e "$cleanup_cache/devbox/shellenv.zsh" ]] ||
    fail "cleanup left the legacy Devbox cache"
  [[ ! -e "$cleanup_cache/devbox/shellenv-pure.zsh" ]] ||
    fail "cleanup left the pure Devbox cache"
  [[ ! -e "$cleanup_cache/p10k-fixture" ]] ||
    fail "cleanup left the p10k cache"
}

populate_cleanup_cache
env \
  "HOME=$runtime_home" \
  "XDG_CACHE_HOME=$cleanup_cache" \
  just --justfile "$repo_root/justfile" clean >/dev/null
assert_cleanup_cache_removed

populate_cleanup_cache
env \
  "XDG_CACHE_HOME=$cleanup_cache" \
  "XDG_DATA_HOME=$cleanup_data" \
  "ZSH_INIT_CACHE=$cleanup_cache/zsh/init" \
  "CACHE_MGMT=$repo_root/home/dot_config/zsh/features/cache-mgmt.zsh" \
  zsh -f -c '
    set -e
    source "$CACHE_MGMT"
    zsh-update-cache >/dev/null
  '
assert_cleanup_cache_removed
pass "zsh and just cleanup honor XDG_CACHE_HOME"

echo "All generated cache tests passed."
