#!/usr/bin/env bash
# shellcheck disable=SC2016
# Verify the business-only gh wrapper without consulting real credentials.
set -euo pipefail

# Never inherit or inspect credentials from the shell running this test.
unset GH_TOKEN GITHUB_TOKEN

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd "$script_dir/../.." && pwd -P)"
feature_source="$repo_root/home/dot_config/zsh/features/ghtkn-gh.zsh"
zshrc_source="$repo_root/home/private_dot_zshrc.tmpl"

for required_command in chezmoi chmod cp grep mkdir zsh; do
  command -v "$required_command" >/dev/null 2>&1 || {
    echo "required command not found: $required_command" >&2
    exit 1
  }
done

test_root="$(mktemp -d "${TMPDIR:-/tmp}/dots-ghtkn-gh.XXXXXX")"
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
ghtkn_log="$test_root/ghtkn.log"
gh_log="$test_root/gh.log"
trace_log="$test_root/zsh.trace"
mkdir -p "$fake_bin" "$gh_only_bin"

cat >"$fake_bin/ghtkn" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${GHTKN_LOG:?}"

case "${GHTKN_MODE:-success}" in
  success)
    printf '%s\n' "fake-ghtkn-token"
    ;;
  empty)
    ;;
  fail)
    exit 42
    ;;
  *)
    exit 64
    ;;
esac
EOF

cat >"$fake_bin/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
{
  printf 'args=%s\n' "$*"
  printf 'GH_TOKEN=%s\n' "${GH_TOKEN-<unset>}"
  printf 'GITHUB_TOKEN=%s\n' "${GITHUB_TOKEN-<unset>}"
} >>"${GH_LOG:?}"
EOF

chmod +x "$fake_bin/ghtkn" "$fake_bin/gh"
cp "$fake_bin/gh" "$gh_only_bin/gh"

env -u GH_TOKEN -u GITHUB_TOKEN \
  "PATH=$fake_bin:/usr/bin:/bin" \
  "FEATURE_SOURCE=$feature_source" \
  "GHTKN_LOG=$ghtkn_log" \
  "GH_LOG=$gh_log" \
  zsh -f -c '
    source "$FEATURE_SOURCE"
    gh api /user
    [[ ! -v GH_TOKEN ]]
    [[ ! -v GITHUB_TOKEN ]]
  '

grep -Fxq "get" "$ghtkn_log" ||
  fail "wrapper did not request a token from ghtkn"
grep -Fxq "args=api /user" "$gh_log" ||
  fail "wrapper did not preserve gh arguments"
grep -Fxq "GH_TOKEN=fake-ghtkn-token" "$gh_log" ||
  fail "wrapper did not pass the short-lived token to gh"
pass "short-lived token is scoped to the gh child process"

: >"$ghtkn_log"
: >"$gh_log"
env -u GH_TOKEN -u GITHUB_TOKEN \
  "PATH=$fake_bin:/usr/bin:/bin" \
  "FEATURE_SOURCE=$feature_source" \
  "GHTKN_LOG=$ghtkn_log" \
  "GH_LOG=$gh_log" \
  zsh -f -c '
    set -x
    source "$FEATURE_SOURCE"
    gh api /user
  ' >/dev/null 2>"$trace_log"

if grep -Fq "fake-ghtkn-token" "$trace_log"; then
  fail "short-lived token appeared in zsh xtrace output"
fi
pass "wrapper suppresses token-bearing xtrace output"

: >"$ghtkn_log"
: >"$gh_log"
env -u GH_TOKEN -u GITHUB_TOKEN \
  "PATH=$fake_bin:/usr/bin:/bin" \
  "FEATURE_SOURCE=$feature_source" \
  "GHTKN_LOG=$ghtkn_log" \
  "GH_LOG=$gh_log" \
  zsh -f -c '
    alias gh="print aliased"
    source "$FEATURE_SOURCE"
    (( ! $+aliases[gh] ))
    eval "gh api /user"
  '

grep -Fxq "get" "$ghtkn_log" ||
  fail "wrapper did not run when a gh alias existed before sourcing"
grep -Fxq "args=api /user" "$gh_log" ||
  fail "pre-existing gh alias shadowed the wrapper"
pass "pre-existing gh alias does not break or shadow the wrapper"

: >"$ghtkn_log"
: >"$gh_log"
env -u GITHUB_TOKEN \
  "GH_TOKEN=caller-token" \
  "PATH=$fake_bin:/usr/bin:/bin" \
  "FEATURE_SOURCE=$feature_source" \
  "GHTKN_LOG=$ghtkn_log" \
  "GH_LOG=$gh_log" \
  zsh -f -c '
    source "$FEATURE_SOURCE"
    gh repo view
    [[ "$GH_TOKEN" == "caller-token" ]]
  '

[[ ! -s "$ghtkn_log" ]] ||
  fail "wrapper called ghtkn despite an explicit GH_TOKEN"
grep -Fxq "GH_TOKEN=caller-token" "$gh_log" ||
  fail "wrapper did not preserve the explicit GH_TOKEN"
pass "explicit GH_TOKEN bypasses ghtkn"

: >"$ghtkn_log"
: >"$gh_log"
env -u GH_TOKEN \
  "GITHUB_TOKEN=caller-token" \
  "PATH=$fake_bin:/usr/bin:/bin" \
  "FEATURE_SOURCE=$feature_source" \
  "GHTKN_LOG=$ghtkn_log" \
  "GH_LOG=$gh_log" \
  zsh -f -c '
    source "$FEATURE_SOURCE"
    gh repo view
    [[ "$GITHUB_TOKEN" == "caller-token" ]]
  '

[[ ! -s "$ghtkn_log" ]] ||
  fail "wrapper called ghtkn despite an explicit GITHUB_TOKEN"
grep -Fxq "GITHUB_TOKEN=caller-token" "$gh_log" ||
  fail "wrapper did not preserve the explicit GITHUB_TOKEN"
pass "explicit GITHUB_TOKEN bypasses ghtkn"

: >"$ghtkn_log"
: >"$gh_log"
env -u GH_TOKEN -u GITHUB_TOKEN \
  "PATH=$fake_bin:/usr/bin:/bin" \
  "FEATURE_SOURCE=$feature_source" \
  "GHTKN_LOG=$ghtkn_log" \
  "GH_LOG=$gh_log" \
  "GHTKN_MODE=fail" \
  zsh -f -c '
    source "$FEATURE_SOURCE"
    gh api /user
  ' >/dev/null 2>&1 && fail "ghtkn failure unexpectedly succeeded"

[[ ! -s "$gh_log" ]] ||
  fail "wrapper ran gh after ghtkn failed"
pass "ghtkn failure prevents gh execution"

: >"$ghtkn_log"
: >"$gh_log"
env -u GH_TOKEN -u GITHUB_TOKEN \
  "PATH=$fake_bin:/usr/bin:/bin" \
  "FEATURE_SOURCE=$feature_source" \
  "GHTKN_LOG=$ghtkn_log" \
  "GH_LOG=$gh_log" \
  "GHTKN_MODE=empty" \
  zsh -f -c '
    source "$FEATURE_SOURCE"
    gh api /user
  ' >/dev/null 2>&1 && fail "empty ghtkn response unexpectedly succeeded"

[[ ! -s "$gh_log" ]] ||
  fail "wrapper ran gh after ghtkn returned an empty token"
pass "empty ghtkn response prevents gh execution"

: >"$gh_log"
env -u GH_TOKEN -u GITHUB_TOKEN \
  "PATH=$gh_only_bin:/usr/bin:/bin" \
  "FEATURE_SOURCE=$feature_source" \
  "GH_LOG=$gh_log" \
  zsh -f -c '
    source "$FEATURE_SOURCE"
    gh api /user
  ' >/dev/null 2>&1 && fail "missing ghtkn unexpectedly succeeded"

[[ ! -s "$gh_log" ]] ||
  fail "wrapper ran gh without ghtkn"
pass "missing ghtkn prevents gh execution"

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

if grep -Fq "gh: ghtkn is required" "$render_root/personal.zshrc"; then
  fail "personal zshrc unexpectedly contains the ghtkn gh wrapper"
fi
grep -Fq "gh: ghtkn is required" "$render_root/business.zshrc" ||
  fail "business zshrc is missing the ghtkn gh wrapper"
pass "wrapper is rendered only for the business profile"

echo "All ghtkn gh wrapper tests passed."
