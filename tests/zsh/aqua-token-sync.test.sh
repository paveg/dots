#!/usr/bin/env bash
# shellcheck disable=SC2016
# Verify the business-only aqua-token-sync helper without consulting real credentials.
set -euo pipefail

unset GH_TOKEN GITHUB_TOKEN

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd "$script_dir/../.." && pwd -P)"
feature_source="$repo_root/home/dot_config/zsh/features/aqua-token-sync.zsh"
zshrc_source="$repo_root/home/private_dot_zshrc.tmpl"

for required_command in chezmoi chmod grep mkdir zsh; do
  command -v "$required_command" >/dev/null 2>&1 || {
    echo "required command not found: $required_command" >&2
    exit 1
  }
done

test_root="$(mktemp -d "${TMPDIR:-/tmp}/dots-aqua-token-sync.XXXXXX")"
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

fake_bin="$test_root/bin"
gh_only_bin="$test_root/gh-only-bin"
aqua_log="$test_root/aqua.log"
stdout_log="$test_root/stdout.log"
trace_log="$test_root/zsh.trace"
mkdir -p "$fake_bin" "$gh_only_bin"

cat >"$fake_bin/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
case "${GH_MODE:-success}" in
  success)
    printf '%s\n' "fake-gh-token"
    ;;
  empty)
    ;;
  fail)
    exit 4
    ;;
  *)
    exit 64
    ;;
esac
EOF

cat >"$fake_bin/aqua" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
{
  printf 'args=%s\n' "$*"
  printf 'stdin=%s\n' "$(cat)"
} >>"${AQUA_LOG:?}"
EOF

chmod +x "$fake_bin/gh" "$fake_bin/aqua"
cp "$fake_bin/gh" "$gh_only_bin/gh"

run_sync() {
  env -u GH_TOKEN -u GITHUB_TOKEN \
    "PATH=$1:/usr/bin:/bin" \
    "FEATURE_SOURCE=$feature_source" \
    "AQUA_LOG=$aqua_log" \
    "GH_MODE=${2:-success}" \
    zsh -f -c '
      source "$FEATURE_SOURCE"
      aqua-token-sync
    '
}

run_sync "$fake_bin" success >"$stdout_log"
grep -Fxq "args=token set --stdin" "$aqua_log" ||
  fail "helper did not invoke aqua token set --stdin"
grep -Fxq "stdin=fake-gh-token" "$aqua_log" ||
  fail "helper did not pipe the gh token into aqua"
grep -Fq "fake-gh-token" "$stdout_log" &&
  fail "token appeared on the helper's stdout"
grep -Fq "keyring token updated" "$stdout_log" ||
  fail "helper did not report success"
pass "gh token reaches aqua via stdin and never stdout"

: >"$aqua_log"
env -u GH_TOKEN -u GITHUB_TOKEN \
  "PATH=$fake_bin:/usr/bin:/bin" \
  "FEATURE_SOURCE=$feature_source" \
  "AQUA_LOG=$aqua_log" \
  zsh -f -c '
    set -x
    source "$FEATURE_SOURCE"
    aqua-token-sync
  ' >/dev/null 2>"$trace_log"

if grep -Fq "fake-gh-token" "$trace_log"; then
  fail "token appeared in zsh xtrace output"
fi
pass "helper suppresses token-bearing xtrace output"

: >"$aqua_log"
run_sync "$fake_bin" fail >/dev/null 2>&1 && fail "gh failure unexpectedly succeeded"
[[ ! -s "$aqua_log" ]] ||
  fail "helper called aqua after gh failed"
pass "gh failure prevents storing a token"

: >"$aqua_log"
run_sync "$fake_bin" empty >/dev/null 2>&1 && fail "empty gh token unexpectedly succeeded"
[[ ! -s "$aqua_log" ]] ||
  fail "helper called aqua with an empty token"
pass "empty gh token prevents storing a token"

: >"$aqua_log"
rc=0
run_sync "$gh_only_bin" success >/dev/null 2>&1 || rc=$?
[[ "$rc" -eq 127 ]] ||
  fail "missing aqua did not return 127 (got $rc)"
pass "missing aqua returns 127"

render_root="$test_root/rendered"
chezmoi_config="$test_root/chezmoi.json"
mkdir -p "$render_root"
printf '{}\n' >"$chezmoi_config"

render_profile() {
  local profile="$1"
  local business_use="$2"
  local rendered="$render_root/$profile.zshrc"
  local data

  data="{\"business_use\":$business_use,\"auto_tmux\":false,\"homebrew_prefix\":\"/opt/homebrew\",\"grafana_instance_id\":\"\",\"grafana_api_token\":\"\",\"grafana_sa_token\":\"\"}"
  env -u GH_TOKEN -u GITHUB_TOKEN \
    chezmoi \
    --config "$chezmoi_config" \
    --config-format json \
    --source "$repo_root" \
    --override-data "$data" \
    execute-template --file "$zshrc_source" >"$rendered"
  zsh -n "$rendered"
}

render_profile personal false
render_profile business true

if grep -Fq "aqua-token-sync" "$render_root/personal.zshrc"; then
  fail "personal zshrc unexpectedly contains aqua-token-sync"
fi
grep -Fq "aqua-token-sync" "$render_root/business.zshrc" ||
  fail "business zshrc is missing aqua-token-sync"
pass "helper is rendered only for the business profile"

echo "All aqua-token-sync tests passed."
