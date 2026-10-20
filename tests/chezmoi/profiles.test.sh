#!/usr/bin/env bash
# Renders the whole source tree for each profile and asserts which scripts
# survive .chezmoiignore. CI's other chezmoi steps render one file, so a
# dangling include or a script ignore that matches nothing reaches main.
set -euo pipefail

repo_root=${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}
scratch_dir=$(mktemp -d)
trap 'rm -rf "$scratch_dir"' EXIT

command -v chezmoi >/dev/null 2>&1 || {
  echo "Required command not found: chezmoi" >&2
  exit 1
}

mkdir -p "$scratch_dir"/{home,cache,config,data,state}

write_config() {
  local business_use="$1"
  cat >"$scratch_dir/chezmoi.json" <<EOF
{"data":{"osid":"test","business_use":$business_use,"has_op":false,"name":"Test","email":"t@example.com","work_email":"t@work.example.com","signing_key":"","ghtkn_client_ids":{"none":"Iv1.test","read":"Iv1.test","git":"Iv1.test","write":"Iv1.test"},"auto_tmux":true,"xdg_config_home":"$scratch_dir/home/.config","xdg_data_home":"$scratch_dir/home/.local/share","xdg_cache_home":"$scratch_dir/home/.cache","xdg_state_home":"$scratch_dir/home/.local/state","homebrew_prefix":"/opt/homebrew","font_dir":"$scratch_dir/home/fonts"}}
EOF
}

run_chezmoi() {
  local os_override="$1"
  shift
  env -u BUSINESS_USE -u SSH_CLIENT \
    HOME="$scratch_dir/home" \
    XDG_CACHE_HOME="$scratch_dir/cache" \
    XDG_CONFIG_HOME="$scratch_dir/config" \
    XDG_DATA_HOME="$scratch_dir/data" \
    XDG_STATE_HOME="$scratch_dir/state" \
    chezmoi \
    --config "$scratch_dir/chezmoi.json" \
    --config-format json \
    --source "$repo_root" \
    --destination "$scratch_dir/home" \
    --override-data "{\"chezmoi\":{\"os\":\"$os_override\"}}" \
    "$@"
}

failures=0

assert_script() {
  local label="$1" expectation="$2" script="$3" managed="$4"
  local present=absent
  grep -Fxq "$script" <<<"$managed" && present=present
  if [[ "$present" != "$expectation" ]]; then
    echo "✗ $label: $script should be $expectation, is $present" >&2
    failures=$((failures + 1))
  fi
}

check_profile() {
  local label="$1" business_use="$2" os="$3"
  write_config "$business_use"

  if ! run_chezmoi "$os" apply --dry-run >"$scratch_dir/apply.log" 2>&1; then
    echo "✗ $label: chezmoi cannot render the source tree" >&2
    cat "$scratch_dir/apply.log" >&2
    failures=$((failures + 1))
    return
  fi

  local failures_before=$failures
  local managed
  managed=$(run_chezmoi "$os" managed --include=scripts)

  local darwin_only=present
  [[ "$os" == darwin ]] || darwin_only=absent
  local business_only=present
  [[ "$business_use" == true ]] || business_only=absent
  local personal_only=present
  [[ "$business_use" == false ]] || personal_only=absent

  assert_script "$label" "$darwin_only" .chezmoiscripts/configure-macos-keyboard.sh "$managed"
  assert_script "$label" "$business_only" .chezmoiscripts/load-ghtkn-agent.sh "$managed"
  assert_script "$label" "$personal_only" .chezmoiscripts/install-atcoder-tools.sh "$managed"
  ((failures == failures_before)) && echo "✓ $label"
  return 0
}

check_profile personal-linux false linux
check_profile business-linux true linux
check_profile personal-darwin false darwin
check_profile business-darwin true darwin

if ((failures > 0)); then
  exit 1
fi
