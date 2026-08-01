#!/usr/bin/env bash
# shellcheck disable=SC2016
# Verify every repo-owned generated zsh cache consumer uses the shared contract.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd "$script_dir/../.." && pwd -P)"
helper="$repo_root/home/dot_config/zsh/init/generated-cache.zsh"
homebrew_source="$repo_root/home/dot_config/zsh/init/homebrew.zsh.tmpl"
mise_source="$repo_root/home/dot_config/zsh/init/mise.zsh"
plugins_source="$repo_root/home/dot_config/zsh/init/plugins.zsh"

for required_command in chezmoi cmp grep ln stat touch zsh; do
  command -v "$required_command" >/dev/null 2>&1 || {
    echo "required command not found: $required_command" >&2
    exit 1
  }
done

test_root="$(mktemp -d "${TMPDIR:-/tmp}/dots-cache-consumers.XXXXXX")"
cleanup() {
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

make_fake_command() {
  local destination="$1"
  local tool="$2"
  local upper

  upper="$(printf '%s' "$tool" | tr '[:lower:]' '[:upper:]')"

  {
    printf '%s\n' '#!/usr/bin/env bash'
    printf '%s\n' 'set -euo pipefail'
    printf 'tool=%q\n' "$tool"
    printf 'upper=%q\n' "$upper"
    cat <<'EOF'

printf '%s|%s\n' "$tool" "$*" >>"${FAKE_LOG:?}"
mode="${FAKE_MODE:-normal}"
version="${FAKE_OUTPUT_VERSION:-v1}"

if [[ "$mode" == "fail" ]]; then
  printf 'typeset -g PR7_%s_LOADED="partial"\n' "$upper"
  exit 82
fi
[[ "$mode" != "empty" ]] || exit 0

if [[ "$tool" == "mise" && "$*" == "activate zsh" ]]; then
  printf 'typeset -g PR7_MISE_ACTIVATED="%s"\n' "$version"
  [[ "$mode" != "mise-activate-fail" ]] || exit 83
  exit 0
fi

case "$*" in
  "completion -s zsh" | "completion zsh" | "--completions zsh" | "shell-completion --shell zsh")
    printf '#compdef %s\n' "$tool"
    ;;
esac
printf 'typeset -g PR7_%s_LOADED="%s"\n' "$upper" "$version"
EOF
  } >"$destination"
  chmod +x "$destination"
}

command_root="$test_root/command-helper"
command_bin_v1="$command_root/bin-v1"
command_bin_v2="$command_root/bin-v2"
command_cache="$command_root/cache/command.zsh"
command_log="$command_root/command.log"
mkdir -p "$command_bin_v1" "$command_bin_v2"
make_fake_command "$command_bin_v1/cachecmd" cachecmd
make_fake_command "$command_bin_v2/cachecmd" cachecmd

env \
  "PATH=$command_bin_v1:/usr/bin:/bin" \
  "COMMAND=$command_bin_v1/cachecmd" \
  "HELPER=$helper" \
  "TARGET=$command_cache" \
  "FAKE_LOG=$command_log" \
  zsh -f -c '
    set -e
    source "$HELPER"
    _zsh_command_cache_prepare "$TARGET" "command-helper-v1" "$COMMAND" emit
    source "$TARGET"
    [[ "$PR7_CACHECMD_LOADED" == v1 ]]

    export FAKE_MODE=fail
    _zsh_command_cache_prepare "$TARGET" "command-helper-v1" "$COMMAND" emit
    source "$TARGET"
    [[ "$PR7_CACHECMD_LOADED" == v1 ]]
  '
[[ "$(wc -l <"$command_log" | tr -d ' ')" == "1" ]] ||
  fail "warm command cache invoked its generator"
grep -Fxq 'cachecmd|emit' "$command_log" ||
  fail "command helper did not preserve generator argv"
resolved_v1="$(cd "$command_bin_v1" && pwd -P)/cachecmd"
grep -Fxq "# fingerprint: command-helper-v1|$resolved_v1" "$command_cache" ||
  fail "explicit command path was not preserved in the fingerprint"
pass "explicit-path helper cold-generates and warm-loads without execution"

touch -t 202101010000 "$command_cache"
touch -t 202201010000 "$command_bin_v1/cachecmd"
env \
  "PATH=$command_bin_v1:/usr/bin:/bin" \
  "COMMAND=$command_bin_v1/cachecmd" \
  "HELPER=$helper" \
  "TARGET=$command_cache" \
  "FAKE_LOG=$command_log" \
  "FAKE_OUTPUT_VERSION=v2" \
  zsh -f -c '
    set -e
    source "$HELPER"
    _zsh_command_cache_prepare "$TARGET" "command-helper-v1" "$COMMAND" emit
    source "$TARGET"
    [[ "$PR7_CACHECMD_LOADED" == v2 ]]
  '
grep -Fq 'PR7_CACHECMD_LOADED="v2"' "$command_cache" ||
  fail "newer command binary did not refresh its cache"

command_lkg="$test_root/command-lkg.expected"
cp "$command_cache" "$command_lkg"
touch -t 202101010000 "$command_cache"
touch -t 202201010000 "$command_bin_v1/cachecmd"
env \
  "PATH=$command_bin_v1:/usr/bin:/bin" \
  "COMMAND=$command_bin_v1/cachecmd" \
  "HELPER=$helper" \
  "TARGET=$command_cache" \
  "FAKE_LOG=$command_log" \
  "FAKE_MODE=fail" \
  zsh -f -c '
    set -e
    source "$HELPER"
    _zsh_command_cache_prepare "$TARGET" "command-helper-v1" "$COMMAND" emit
    source "$TARGET"
    [[ "$PR7_CACHECMD_LOADED" == v2 ]]
  ' >/dev/null 2>&1
cmp -s "$command_lkg" "$command_cache" ||
  fail "failed same-fingerprint refresh changed its last-known-good cache"
pass "binary mtime refresh preserves matching LKG on failure"

env \
  "PATH=$command_bin_v2:/usr/bin:/bin" \
  "COMMAND=$command_bin_v2/cachecmd" \
  "HELPER=$helper" \
  "TARGET=$command_cache" \
  "FAKE_LOG=$command_log" \
  "FAKE_OUTPUT_VERSION=path-v2" \
  zsh -f -c '
    set -e
    source "$HELPER"
    _zsh_command_cache_prepare "$TARGET" "command-helper-v1" "$COMMAND" emit
    source "$TARGET"
    [[ "$PR7_CACHECMD_LOADED" == path-v2 ]]
  '
resolved_v2="$(cd "$command_bin_v2" && pwd -P)/cachecmd"
grep -Fxq "# fingerprint: command-helper-v1|$resolved_v2" "$command_cache" ||
  fail "resolved command path change did not replace the fingerprint"
pass "resolved command path change regenerates the cache"

multicall_root="$test_root/multicall"
multicall_bin="$multicall_root/bin"
multicall_cache="$multicall_root/cache/pnpm.zsh"
mkdir -p "$multicall_bin"
cat >"$multicall_bin/mise" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
tool="${0##*/}"
printf '#compdef %s\n' "$tool"
printf 'typeset -g PR7_MULTICALL_LOADED="%s"\n' "$tool"
EOF
chmod +x "$multicall_bin/mise"
ln -s mise "$multicall_bin/pnpm"

env \
  "PATH=$multicall_bin:/usr/bin:/bin" \
  "HELPER=$helper" \
  "TARGET=$multicall_cache" \
  zsh -f -c '
    set -e
    source "$HELPER"
    _zsh_command_cache_prepare "$TARGET" "multicall-pnpm-v1" pnpm completion zsh
    source "$TARGET"
    [[ "$PR7_MULTICALL_LOADED" == pnpm ]]
  '
canonical_multicall="$(cd "$multicall_bin" && pwd -P)/mise"
grep -Fxq "# fingerprint: multicall-pnpm-v1|$canonical_multicall" "$multicall_cache" ||
  fail "multicall cache fingerprint is not bound to the canonical executable"
grep -Fxq '#compdef pnpm' "$multicall_cache" ||
  fail "multicall symlink lost its argv[0] dispatch"
pass "multicall symlink preserves argv[0] with canonical cache identity"

missing_cache="$command_root/cache/missing.zsh"
if env HELPER="$helper" TARGET="$missing_cache" PATH="/usr/bin:/bin" zsh -f -c '
  set -e
  source "$HELPER"
  _zsh_command_cache_prepare "$TARGET" "missing-v1" command-that-does-not-exist emit
' >/dev/null 2>&1; then
  fail "missing command was accepted"
fi
[[ ! -e "$missing_cache" ]] || fail "missing command published a cache"
pass "missing command fails closed"

mise_root="$test_root/mise"
mise_bin="$mise_root/bin"
mise_cache="$mise_root/cache/mise.zsh"
mise_log="$mise_root/mise.log"
mkdir -p "$mise_bin" "$mise_root/cache"
make_fake_command "$mise_bin/mise" mise

env \
  "PATH=$mise_bin:/usr/bin:/bin" \
  "HELPER=$helper" \
  "MISE_SOURCE=$mise_source" \
  "ZSH_INIT_CACHE=$mise_root/cache" \
  "FAKE_LOG=$mise_log" \
  zsh -f -c '
    set -e
    source "$HELPER"
    source "$MISE_SOURCE"
    [[ "$PR7_MISE_ACTIVATED" == v1 ]]
  '
[[ "$(wc -l <"$mise_log" | tr -d ' ')" == "1" ]] ||
  fail "cold mise activation did not run exactly once"
grep -Fxq 'mise|activate zsh' "$mise_log" ||
  fail "cold mise activation did not use activate zsh"

env \
  "PATH=$mise_bin:/usr/bin:/bin" \
  "HELPER=$helper" \
  "MISE_SOURCE=$mise_source" \
  "ZSH_INIT_CACHE=$mise_root/cache" \
  "FAKE_LOG=$mise_log" \
  "FAKE_MODE=fail" \
  zsh -f -c '
    set -e
    source "$HELPER"
    source "$MISE_SOURCE"
    [[ "$PR7_MISE_ACTIVATED" == v1 ]]
  '
[[ "$(wc -l <"$mise_log" | tr -d ' ')" == "1" ]] ||
  fail "warm mise cache invoked activate"
pass "warm mise cache avoids the activate command"

touch -t 202101010000 "$mise_cache"
touch -t 202201010000 "$mise_bin/mise"
mise_lkg="$test_root/mise-lkg.expected"
cp "$mise_cache" "$mise_lkg"
env \
  "PATH=$mise_bin:/usr/bin:/bin" \
  "HELPER=$helper" \
  "MISE_SOURCE=$mise_source" \
  "ZSH_INIT_CACHE=$mise_root/cache" \
  "FAKE_LOG=$mise_log" \
  "FAKE_MODE=mise-activate-fail" \
  zsh -f -c '
    set -e
    source "$HELPER"
    source "$MISE_SOURCE"
    [[ "$PR7_MISE_ACTIVATED" == v1 ]]
  ' >/dev/null 2>&1 ||
  fail "mise activation failure did not fall back to LKG"
cmp -s "$mise_lkg" "$mise_cache" ||
  fail "mise activation failure changed LKG bytes"
pass "mise rejects partial activation and preserves LKG"

mise_extra_path="$mise_root/extra-bin"
mkdir -p "$mise_extra_path"
env \
  "PATH=$mise_bin:$mise_extra_path:/usr/bin:/bin" \
  "HELPER=$helper" \
  "MISE_SOURCE=$mise_source" \
  "ZSH_INIT_CACHE=$mise_root/cache" \
  "FAKE_LOG=$mise_log" \
  zsh -f -c '
    set -e
    source "$HELPER"
    source "$MISE_SOURCE"
    [[ "$PR7_MISE_ACTIVATED" == v1 ]]
  '
grep -Fq "mise-activate-v2|path=$mise_bin:$mise_extra_path:/usr/bin:/bin" "$mise_cache" ||
  fail "mise cache fingerprint does not track its input PATH"
pass "mise PATH changes invalidate the activation cache"

plugin_root="$test_root/plugins"
plugin_bin="$plugin_root/bin"
plugin_cache="$plugin_root/cache/init"
completion_cache="$plugin_root/cache/zsh/completions"
plugin_data="$plugin_root/data"
plugin_log="$plugin_root/generators.log"
compdef_log="$plugin_root/compdef.log"
mkdir -p "$plugin_bin" "$plugin_cache" "$completion_cache" "$plugin_data/zinit/zinit.git"

plugin_tools=(zoxide atuin fzf direnv gh chezmoi just herdr mise pnpm moon kubectl)
for tool in "${plugin_tools[@]}"; do
  make_fake_command "$plugin_bin/$tool" "$tool"
done

cat >"$plugin_data/zinit/zinit.git/zinit.zsh" <<'EOF'
zinit() {
  local argument
  for argument in "$@"; do
    case "$argument" in
      atload_zinit_setup_zoxide) _zinit_setup_zoxide ;;
      atload_zinit_setup_atuin) _zinit_setup_atuin ;;
      atload_zinit_setup_fzf) _zinit_setup_fzf ;;
      atload_zinit_setup_direnv) _zinit_setup_direnv ;;
      atload_zinit_setup_completions) _zinit_setup_completions ;;
    esac
  done
}
EOF

run_plugins() {
  local output_version="$1"
  local mode="$2"
  local expected_all="$3"

  env \
    "PATH=$plugin_bin:/usr/bin:/bin" \
    "HELPER=$helper" \
    "PLUGINS_SOURCE=$plugins_source" \
    "ZSH_INIT_CACHE=$plugin_cache" \
    "XDG_CACHE_HOME=$plugin_root/cache" \
    "XDG_DATA_HOME=$plugin_data" \
    "FAKE_LOG=$plugin_log" \
    "COMPDEF_LOG=$compdef_log" \
    "FAKE_OUTPUT_VERSION=$output_version" \
    "FAKE_MODE=$mode" \
    "EXPECTED_ALL=$expected_all" \
    zsh -f -c '
      set -e
      source "$HELPER"
      compdef() {
        print -r -- "$*" >> "$COMPDEF_LOG"
      }
      source "$PLUGINS_SOURCE"

      if [[ -n "$EXPECTED_ALL" ]]; then
        variable=""
        for variable in \
          PR7_ZOXIDE_LOADED \
          PR7_ATUIN_LOADED \
          PR7_FZF_LOADED \
          PR7_DIRENV_LOADED \
          PR7_GH_LOADED \
          PR7_CHEZMOI_LOADED \
          PR7_JUST_LOADED \
          PR7_HERDR_LOADED \
          PR7_MISE_LOADED \
          PR7_PNPM_LOADED \
          PR7_MOON_LOADED \
          PR7_KUBECTL_LOADED; do
          if [[ "${(P)variable}" != "$EXPECTED_ALL" ]]; then
            print -u2 -r -- "$variable expected=$EXPECTED_ALL actual=${(P)variable}"
            exit 91
          fi
        done
      fi
      [[ -n "$FZF_DEFAULT_OPTS" ]]
    '
}

run_plugins v1 normal v1 || fail "plugin consumers did not publish and source all caches"

expected_plugin_log="$test_root/plugin-log.expected"
cat >"$expected_plugin_log" <<'EOF'
zoxide|init zsh
atuin|init zsh --disable-up-arrow
fzf|--zsh
direnv|hook zsh
gh|completion -s zsh
chezmoi|completion zsh
just|--completions zsh
herdr|completion zsh
mise|completion zsh
pnpm|completion zsh
moon|shell-completion --shell zsh
kubectl|completion zsh
EOF
cmp -s "$expected_plugin_log" "$plugin_log" ||
  fail "plugin generator argv or load order changed"
grep -Fxq 'k=kubectl' "$compdef_log" ||
  fail "kubectl alias completion was not preserved"

for cache_file in \
  "$plugin_cache/zoxide.zsh" \
  "$plugin_cache/atuin.zsh" \
  "$plugin_cache/fzf.zsh" \
  "$plugin_cache/direnv.zsh" \
  "$completion_cache/_gh" \
  "$completion_cache/_chezmoi" \
  "$completion_cache/_just" \
  "$completion_cache/_herdr" \
  "$completion_cache/_mise" \
  "$completion_cache/_pnpm" \
  "$completion_cache/_moon" \
  "$completion_cache/_kubectl"; do
  [[ -s "$cache_file" ]] || fail "consumer cache was not created: $cache_file"
  [[ "$(sed -n '1p' "$cache_file")" == "# dots-generated-zsh-cache-v1" ]] ||
    fail "consumer cache lacks validation marker: $cache_file"
done
pass "all 4 init and 8 completion generators use exact argv and source marked caches"

plugin_log_lines="$(wc -l <"$plugin_log" | tr -d ' ')"
run_plugins v1 fail v1 || fail "warm plugin consumers did not source their caches"
[[ "$(wc -l <"$plugin_log" | tr -d ' ')" == "$plugin_log_lines" ]] ||
  fail "warm plugin consumer invoked a generator"
pass "all plugin consumers use warm caches without generator execution"

touch -t 202101010000 "$plugin_cache/zoxide.zsh"
touch -t 202201010000 "$plugin_bin/zoxide"
run_plugins init-v2 normal "" || fail "newer init binary did not refresh"
[[ "$(tail -n 1 "$plugin_log")" == "zoxide|init zsh" ]] ||
  fail "init upgrade refreshed the wrong generator"
grep -Fq 'PR7_ZOXIDE_LOADED="init-v2"' "$plugin_cache/zoxide.zsh" ||
  fail "init upgrade did not replace its cache"
touch -t 201901010000 "$plugin_bin/zoxide"

touch -t 202101010000 "$completion_cache/_gh"
touch -t 202201010000 "$plugin_bin/gh"
run_plugins completion-v2 normal "" || fail "newer completion binary did not refresh"
[[ "$(tail -n 1 "$plugin_log")" == "gh|completion -s zsh" ]] ||
  fail "completion upgrade refreshed the wrong generator"
grep -Fq 'PR7_GH_LOADED="completion-v2"' "$completion_cache/_gh" ||
  fail "completion upgrade did not replace its cache"
pass "init and completion binary upgrades regenerate independently"

command_prepare_calls="$(
  grep -Fhc "_zsh_command_cache_prepare \\" \
    "$homebrew_source" "$mise_source" "$plugins_source" |
    awk '{ total += $1 } END { print total + 0 }'
)"
[[ "$command_prepare_calls" == "14" ]] ||
  fail "expected 14 command-cache consumers, found $command_prepare_calls"
grep -Fq '"homebrew-shellenv-v1"' "$homebrew_source" ||
  fail "Homebrew cache schema is missing"
grep -Fq '"$_brew_bin"' "$homebrew_source" ||
  fail "Homebrew cache does not pass its explicit command path"
grep -Fq '    shellenv; then' "$homebrew_source" ||
  fail "Homebrew cache does not preserve the shellenv argv"

if grep -En '>[[:space:]]*"\$[^"]*(cache|comp)"' \
  "$homebrew_source" "$mise_source" "$plugins_source"; then
  fail "direct generator-to-final redirection remains"
fi
pass "structural audit finds all 14 consumers and zero direct-final redirects"

render_root="$test_root/rendered"
mkdir -p "$render_root"
chezmoi_config="$test_root/chezmoi.json"
printf '{}\n' >"$chezmoi_config"
for profile in personal business; do
  if [[ "$profile" == "personal" ]]; then
    business_use=false
  else
    business_use=true
  fi
  data="{\"business_use\":$business_use,\"auto_tmux\":false,\"homebrew_prefix\":\"/opt/homebrew\"}"
  rendered="$render_root/$profile.zshrc"
  chezmoi \
    --config "$chezmoi_config" \
    --config-format json \
    --source "$repo_root" \
    --override-data "$data" \
    execute-template --file "$repo_root/home/private_dot_zshrc.tmpl" >"$rendered"
  zsh -n "$rendered"
  grep -Fq '"mise-activate-v2|path=${PATH}"' "$rendered" ||
    fail "$profile render is missing validated mise activation"
  grep -Fq '"direnv-hook-v1"' "$rendered" ||
    fail "$profile render is missing validated direnv hook"
  grep -Fq '"kubectl-completion-v1"' "$rendered" ||
    fail "$profile render is missing validated completions"
done
pass "personal and business zshrc renders retain validated consumer wiring"

echo "All generated cache consumer tests passed."
