#!/usr/bin/env bash
# Verify project environment files cross an explicit direnv trust boundary.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd "$script_dir/../.." && pwd -P)"
source_root="$repo_root/home"

for required_command in chezmoi cp direnv grep touch zsh; do
  command -v "$required_command" >/dev/null 2>&1 || {
    echo "required command not found: $required_command" >&2
    exit 1
  }
done

if ! direnv version 2.31.0 >/dev/null; then
  echo "direnv 2.31.0 or newer is required for load_dotenv" >&2
  exit 1
fi

[[ -f "$repo_root/.chezmoiroot" ]] || {
  echo ".chezmoiroot not found" >&2
  exit 1
}
[[ "$(<"$repo_root/.chezmoiroot")" == "home" ]] || {
  echo ".chezmoiroot must select home" >&2
  exit 1
}
[[ -d "$source_root" ]] || {
  echo "chezmoi source root not found: $source_root" >&2
  exit 1
}

tmp_parent="${TMPDIR:-/tmp}"
tmp_parent="${tmp_parent%/}"
tmp_parent="$(cd "$tmp_parent" && pwd -P)"
test_root="$(mktemp -d "$tmp_parent/dots-project-env-trust.XXXXXX")"
case "$test_root" in
  "$tmp_parent"/dots-project-env-trust.*) ;;
  *)
    echo "unexpected temporary directory: $test_root" >&2
    exit 1
    ;;
esac

cleanup() {
  case "$test_root" in
    "$tmp_parent"/dots-project-env-trust.*)
      [[ ! -d "$test_root" ]] || rm -rf -- "$test_root"
      ;;
  esac
}
trap cleanup EXIT

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

chezmoi_config="$test_root/chezmoi.json"
printf '{}\n' >"$chezmoi_config"
literal_dollar='$'

render_profile() {
  local profile="$1"
  local business_use="$2"
  local profile_root="$test_root/rendered/$profile"
  local profile_home="$profile_root/home"
  local rendered_zsh="$profile_root/zshrc"
  local rendered_direnv="$profile_root/direnv.toml"
  local data

  mkdir -p "$profile_home"
  data="{\"business_use\":$business_use,\"auto_tmux\":false,\"homebrew_prefix\":\"/opt/homebrew\"}"

  chezmoi \
    --config "$chezmoi_config" \
    --config-format json \
    --source "$repo_root" \
    --destination "$profile_home" \
    --override-data "$data" \
    execute-template --file "$source_root/private_dot_zshrc.tmpl" >"$rendered_zsh"
  zsh -n "$rendered_zsh"

  if grep -Fq '_auto_dotenv' "$rendered_zsh"; then
    fail "$profile zsh still registers _auto_dotenv"
  fi
  assert_rendered_once \
    "$profile" \
    "$rendered_zsh" \
    '_zinit_setup_direnv() {' \
    "direnv setup function"
  assert_rendered_once \
    "$profile" \
    "$rendered_zsh" \
    '"direnv-hook-v1"' \
    "validated direnv cache schema"
  assert_rendered_once \
    "$profile" \
    "$rendered_zsh" \
    "source \"${literal_dollar}_direnv_cache\"" \
    "direnv cache source"
  assert_rendered_once \
    "$profile" \
    "$rendered_zsh" \
    'atload"_zinit_setup_direnv"' \
    "direnv atload registration"

  chezmoi \
    --config "$chezmoi_config" \
    --config-format json \
    --source "$repo_root" \
    --destination "$profile_home" \
    --override-data "$data" \
    cat "$profile_home/.config/direnv/direnv.toml" >"$rendered_direnv"

  grep -Fxq 'load_dotenv = true' "$rendered_direnv" ||
    fail "$profile direnv config does not enable load_dotenv"
  if grep -Eq '^[[:space:]]*\[whitelist\]' "$rendered_direnv"; then
    fail "$profile direnv config still has an implicit whitelist"
  fi
  if grep -Eq '^[[:space:]]*(prefix|exact)[[:space:]]*=' "$rendered_direnv"; then
    fail "$profile direnv config still has an implicit trust rule"
  fi
  if grep -Fq "$profile_home/repos" "$rendered_direnv"; then
    fail "$profile direnv config still trusts the broad repos directory"
  fi
}

assert_rendered_once() {
  local profile="$1"
  local rendered="$2"
  local needle="$3"
  local label="$4"
  local count

  count="$(grep -Fc -- "$needle" "$rendered" || true)"
  [[ "$count" == "1" ]] ||
    fail "$profile zsh contains $label $count times, expected 1"
}

render_profile personal false
render_profile business true

[[ ! -e "$source_root/dot_config/zsh/features/dotenv-auto.zsh" ]] ||
  fail "direct .env auto-source feature still exists"

test_home="$test_root/runtime/home"
config_home="$test_root/runtime/config"
cache_home="$test_root/runtime/cache"
data_home="$test_root/runtime/data"
state_home="$test_root/runtime/state"
project_dir="$test_home/repos/github.com/example/project"
helper_dir="$test_home/repos/github.com/example/helper"
upward_parent_dir="$test_home/repos/github.com/example/upward"
upward_child_dir="$upward_parent_dir/nested/child"
outside_dir="$test_home/outside"
marker="$project_dir/dotenv-was-executed"
helper_marker="$helper_dir/dotenv-was-executed"
upward_marker="$upward_child_dir/dotenv-was-executed"

mkdir -p \
  "$config_home/direnv" \
  "$cache_home" \
  "$data_home" \
  "$state_home" \
  "$project_dir" \
  "$helper_dir" \
  "$upward_child_dir" \
  "$outside_dir"

chezmoi \
  --config "$chezmoi_config" \
  --config-format json \
  --source "$repo_root" \
  --destination "$test_home" \
  --override-data '{"business_use":false}' \
  cat "$test_home/.config/direnv/direnv.toml" \
  >"$config_home/direnv/direnv.toml"
cp "$source_root/dot_config/direnv/direnvrc" "$config_home/direnv/direnvrc"

direnv_environment=(
  env
  -u DIRENV_CONFIG
  -u DIRENV_DIFF
  -u DIRENV_DIR
  -u DIRENV_FILE
  -u DIRENV_WATCHES
  -u PROJECT_ENV_TRUST_VALUE
  -u PROJECT_ENV_TRUST_SENTINEL
  -u PROJECT_ENV_HELPER_VALUE
  -u PROJECT_ENV_HELPER_SENTINEL
  "HOME=$test_home"
  "XDG_CONFIG_HOME=$config_home"
  "XDG_CACHE_HOME=$cache_home"
  "XDG_DATA_HOME=$data_home"
  "XDG_STATE_HOME=$state_home"
)

sentinel_literal="${literal_dollar}(touch ./dotenv-was-executed)"

write_project_env() {
  local value="$1"
  printf '%s\n' \
    "PROJECT_ENV_TRUST_VALUE=$value" \
    "PROJECT_ENV_TRUST_SENTINEL='$sentinel_literal'" \
    >"$project_dir/.env"
}

run_project_shell() {
  local expected_state="$1"
  local expected_value="${2:-}"
  local output="$test_root/project-shell.out"

  # shellcheck disable=SC2016
  if ! "${direnv_environment[@]}" \
    "PROJECT_DIR=$project_dir" \
    "OUTSIDE_DIR=$outside_dir" \
    "EXPECTED_STATE=$expected_state" \
    "EXPECTED_VALUE=$expected_value" \
    "EXPECTED_SENTINEL=$sentinel_literal" \
    zsh -f -c '
      hook_output="$(direnv hook zsh)" || exit 10
      eval "$hook_output" || exit 11
      cd "$PROJECT_DIR" || exit 12

      case "$EXPECTED_STATE" in
        blocked)
          [[ -z ${PROJECT_ENV_TRUST_VALUE+x} ]] || exit 20
          [[ -z ${PROJECT_ENV_TRUST_SENTINEL+x} ]] || exit 21
          ;;
        approved)
          [[ ${PROJECT_ENV_TRUST_VALUE+x} == x ]] || exit 30
          [[ "$PROJECT_ENV_TRUST_VALUE" == "$EXPECTED_VALUE" ]] || exit 31
          [[ ${PROJECT_ENV_TRUST_SENTINEL+x} == x ]] || exit 32
          [[ "$PROJECT_ENV_TRUST_SENTINEL" == "$EXPECTED_SENTINEL" ]] || exit 33
          cd "$OUTSIDE_DIR" || exit 34
          [[ -z ${PROJECT_ENV_TRUST_VALUE+x} ]] || exit 35
          [[ -z ${PROJECT_ENV_TRUST_SENTINEL+x} ]] || exit 36
          ;;
        *)
          exit 2
          ;;
      esac
    ' >"$output" 2>&1; then
    sed 's/^/  /' "$output" >&2
    fail "project environment state was not $expected_state"
  fi
}

allow_environment_file() {
  local environment_file="$1"
  local directory
  local output="$test_root/direnv-allow.out"

  directory="$(dirname "$environment_file")"
  if ! (
    cd "$directory"
    "${direnv_environment[@]}" direnv allow "$environment_file"
  ) >"$output" 2>&1; then
    sed 's/^/  /' "$output" >&2
    fail "direnv allow failed for $environment_file"
  fi
}

write_project_env approved
run_project_shell blocked
[[ ! -e "$marker" ]] || fail "unapproved .env executed shell code"

allow_environment_file "$project_dir/.env"
run_project_shell approved approved
[[ ! -e "$marker" ]] || fail "approved data-only .env executed command substitution"

write_project_env changed
run_project_shell blocked
[[ ! -e "$marker" ]] || fail "changed, unapproved .env executed shell code"

allow_environment_file "$project_dir/.env"
run_project_shell approved changed
[[ ! -e "$marker" ]] || fail "re-allowed data-only .env executed command substitution"

write_helper_fixture() {
  local destination="$1"
  local value="$2"

  printf '%s\n' \
    "PROJECT_ENV_HELPER_VALUE=$value" \
    "PROJECT_ENV_HELPER_SENTINEL='$sentinel_literal'" \
    >"$destination"
}

run_helper_reload_shell() {
  local working_dir="$1"
  local watched_env="$2"
  local shell_marker="$3"
  local initial_value="$4"
  local updated_value="$5"
  local updated_fixture="$6"
  local helper_name="$7"
  local output="$test_root/helper-shell.out"

  # shellcheck disable=SC2016
  if ! "${direnv_environment[@]}" \
    "HELPER_WORKING_DIR=$working_dir" \
    "WATCHED_ENV=$watched_env" \
    "HELPER_MARKER=$shell_marker" \
    "INITIAL_HELPER_VALUE=$initial_value" \
    "UPDATED_HELPER_VALUE=$updated_value" \
    "UPDATED_HELPER_FIXTURE=$updated_fixture" \
    "EXPECTED_SENTINEL=$sentinel_literal" \
    zsh -f -c '
      hook_output="$(direnv hook zsh)" || exit 50
      eval "$hook_output" || exit 51
      (( $+functions[_direnv_hook] )) || exit 52
      cd "$HELPER_WORKING_DIR" || exit 53

      [[ ${PROJECT_ENV_HELPER_VALUE+x} == x ]] || exit 40
      [[ "$PROJECT_ENV_HELPER_VALUE" == "$INITIAL_HELPER_VALUE" ]] || exit 41
      [[ ${PROJECT_ENV_HELPER_SENTINEL+x} == x ]] || exit 42
      [[ "$PROJECT_ENV_HELPER_SENTINEL" == "$EXPECTED_SENTINEL" ]] || exit 43
      [[ ! -e "$HELPER_MARKER" ]] || exit 44

      cp -p "$UPDATED_HELPER_FIXTURE" "$WATCHED_ENV" || exit 60
      _direnv_hook || exit 61

      [[ ${PROJECT_ENV_HELPER_VALUE+x} == x ]] || exit 62
      [[ "$PROJECT_ENV_HELPER_VALUE" == "$UPDATED_HELPER_VALUE" ]] || exit 63
      [[ ${PROJECT_ENV_HELPER_SENTINEL+x} == x ]] || exit 64
      [[ "$PROJECT_ENV_HELPER_SENTINEL" == "$EXPECTED_SENTINEL" ]] || exit 65
      [[ ! -e "$HELPER_MARKER" ]] || exit 66
    ' >"$output" 2>&1; then
    sed 's/^/  /' "$output" >&2
    fail "approved $helper_name .envrc did not reload its watched .env"
  fi
}

helper_initial_fixture="$test_root/helper-initial.env"
helper_updated_fixture="$test_root/helper-updated.env"
write_helper_fixture "$helper_initial_fixture" from-helper
write_helper_fixture "$helper_updated_fixture" updated-without-reallow
touch -t 203001010000 "$helper_updated_fixture"
cp "$helper_initial_fixture" "$helper_dir/.env"
printf '%s\n' 'dotenv_if_exists' >"$helper_dir/.envrc"
allow_environment_file "$helper_dir/.envrc"
run_helper_reload_shell \
  "$helper_dir" \
  "$helper_dir/.env" \
  "$helper_marker" \
  from-helper \
  updated-without-reallow \
  "$helper_updated_fixture" \
  dotenv_if_exists

upward_initial_fixture="$test_root/upward-initial.env"
upward_updated_fixture="$test_root/upward-updated.env"
write_helper_fixture "$upward_initial_fixture" from-upward-helper
write_helper_fixture "$upward_updated_fixture" upward-updated-without-reallow
touch -t 203001010000 "$upward_updated_fixture"
cp "$upward_initial_fixture" "$upward_parent_dir/.env"
printf '%s\n' 'dotenv_if_exists_up' >"$upward_child_dir/.envrc"
allow_environment_file "$upward_child_dir/.envrc"
run_helper_reload_shell \
  "$upward_child_dir" \
  "$upward_parent_dir/.env" \
  "$upward_marker" \
  from-upward-helper \
  upward-updated-without-reallow \
  "$upward_updated_fixture" \
  dotenv_if_exists_up

echo "All project environment trust tests passed."
