#!/usr/bin/env bash
# Verify SSH agent forwarding defaults to deny with narrow, explicit opt-ins.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd "$script_dir/../.." && pwd -P)"
source_template="$repo_root/home/private_dot_ssh/config.tmpl"

for required_command in chezmoi grep mktemp ssh; do
  command -v "$required_command" >/dev/null 2>&1 || {
    echo "required command not found: $required_command" >&2
    exit 1
  }
done

tmp_parent="${TMPDIR:-/tmp}"
tmp_parent="${tmp_parent%/}"
tmp_parent="$(cd "$tmp_parent" && pwd -P)"
test_root="$(mktemp -d "$tmp_parent/dots-ssh-config.XXXXXX")"
case "$test_root" in
  "$tmp_parent"/dots-ssh-config.*) ;;
  *)
    echo "unexpected temporary directory: $test_root" >&2
    exit 1
    ;;
esac

cleanup() {
  case "$test_root" in
    "$tmp_parent"/dots-ssh-config.*)
      [[ ! -d "$test_root" ]] || rm -rf -- "$test_root"
      ;;
  esac
}
trap cleanup EXIT

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

config_file="$test_root/chezmoi.json"
cache_dir="$test_root/cache"
state_file="$test_root/state.boltdb"
destination="$test_root/home"
rendered_dir="$test_root/rendered"
fixture_dir="$test_root/fixtures"
config_dir="$test_root/configs"
ssh_home="$test_root/ssh-home"
mkdir -p "$destination" "$rendered_dir" "$fixture_dir" "$config_dir" "$ssh_home"
printf '{}\n' >"$config_file"

local_fixture="$fixture_dir/config.local"
colima_fixture="$fixture_dir/colima-ssh-config"
missing_local="$fixture_dir/missing-config.local"

cat >"$local_fixture" <<'EOF'
Host trusted.example
  ForwardAgent yes

Match host unrelated-tail.example
  User nobody
EOF

cat >"$colima_fixture" <<'EOF'
# Generated config must not override the repository's default deny.
Host colima.example
  HostName colima.internal
  Port 2222
  ForwardAgent yes
EOF

[[ ! -e "$missing_local" ]] || fail "missing local fixture unexpectedly exists"

render_profile() {
  local profile="$1"
  local business_use="$2"
  local output="$3"
  local data

  data="{\"business_use\":$business_use}"
  chezmoi \
    --config "$config_file" \
    --config-format json \
    --source "$repo_root" \
    --destination "$destination/$profile" \
    --cache "$cache_dir/$profile" \
    --persistent-state "$state_file" \
    --refresh-externals=never \
    --override-data "$data" \
    execute-template --file "$source_template" >"$output"
}

materialize_includes() {
  local rendered="$1"
  local output="$2"
  local local_path="$3"
  local colima_path="${4:-}"
  local line
  local local_seen=false
  local colima_seen=false

  while IFS= read -r line || [[ -n "$line" ]]; do
    case "$line" in
      "Include ~/.ssh/config.local")
        printf 'Include %s\n' "$local_path"
        local_seen=true
        ;;
      "Include ~/.config/colima/ssh_config")
        [[ -n "$colima_path" ]] ||
          fail "unexpected Colima include in personal config"
        printf 'Include %s\n' "$colima_path"
        colima_seen=true
        ;;
      *)
        printf '%s\n' "$line"
        ;;
    esac
  done <"$rendered" >"$output"

  [[ "$local_seen" == true ]] || fail "local Include was not replaced"
  if [[ -n "$colima_path" ]]; then
    [[ "$colima_seen" == true ]] || fail "Colima Include was not replaced"
  fi

  if grep -Fq 'Include ~/.ssh/config.local' "$output"; then
    fail "original local Include remains in $output"
  fi
  if grep -Fq 'Include ~/.config/colima/ssh_config' "$output"; then
    fail "original Colima Include remains in $output"
  fi
}

assert_config_value() {
  local config="$1"
  local host="$2"
  local key_name="$3"
  local expected="$4"
  shift 4

  local output
  local key
  local value
  local effective=""

  if ! output="$(
    env \
      HOME="$ssh_home" \
      ZDOTDIR="$ssh_home" \
      SSH_TTY=/dev/pts/test \
      ssh -G -T -F "$config" "$@" "$host"
  )"; then
    fail "ssh -G failed for $host using $config"
  fi

  while read -r key value _; do
    if [[ "$key" == "$key_name" ]]; then
      effective="$value"
      break
    fi
  done <<<"$output"

  [[ -n "$effective" ]] ||
    fail "ssh -G did not report $key_name for $host using $config"
  [[ "$effective" == "$expected" ]] ||
    fail "$key_name for $host using $config: expected $expected, got $effective"
}

assert_forward_agent() {
  local config="$1"
  local host="$2"
  local expected="$3"
  shift 3

  assert_config_value "$config" "$host" forwardagent "$expected" "$@"
}

personal_rendered="$rendered_dir/personal"
business_rendered="$rendered_dir/business"
render_profile personal false "$personal_rendered"
render_profile business true "$business_rendered"

personal_config="$config_dir/personal"
business_config="$config_dir/business"
personal_missing_config="$config_dir/personal-missing-local"
business_missing_config="$config_dir/business-missing-local"

materialize_includes "$personal_rendered" "$personal_config" "$local_fixture"
materialize_includes \
  "$business_rendered" \
  "$business_config" \
  "$local_fixture" \
  "$colima_fixture"
materialize_includes \
  "$personal_rendered" \
  "$personal_missing_config" \
  "$missing_local"
materialize_includes \
  "$business_rendered" \
  "$business_missing_config" \
  "$missing_local" \
  "$colima_fixture"

for config in "$personal_config" "$business_config"; do
  assert_forward_agent "$config" arbitrary.example no
  assert_forward_agent "$config" trusted.example yes
  assert_forward_agent "$config" trusted.example.evil no
  assert_forward_agent "$config" sub.trusted.example no
  assert_forward_agent "$config" arbitrary.example yes -A
done

assert_forward_agent "$business_config" colima.example no
assert_config_value "$business_config" colima.example hostname colima.internal
assert_config_value "$business_config" colima.example port 2222
assert_forward_agent "$personal_missing_config" arbitrary.example no
assert_forward_agent "$business_missing_config" arbitrary.example no

echo "PASS: SSH agent forwarding is default-deny with exact-host opt-ins"
