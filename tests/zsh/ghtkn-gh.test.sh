#!/usr/bin/env bash
# shellcheck disable=SC2016
# Verify the business-only gh wrapper and ghtkn config rendering without consulting real credentials.
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
stderr_log="$test_root/stderr.log"
mkdir -p "$fake_bin" "$gh_only_bin"

cat >"$fake_bin/ghtkn" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${GHTKN_LOG:?}"
[[ "${GHTKN_MODE:-success}" == "no-token" ]] && exit 111
# Mirror `ghtkn exec -e GH_TOKEN:<app> -- cmd args...`: the token reaches the child env only.
shift 4
GH_TOKEN="fake-ghtkn-token" exec "$@"
EOS

cat >"$fake_bin/gh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
{
  printf 'argc=%s\n' "$#"
  for arg in "$@"; do
    printf 'arg=%s\n' "$arg"
  done
  printf 'GH_TOKEN=%s\n' "${GH_TOKEN-<unset>}"
  printf 'GITHUB_TOKEN=%s\n' "${GITHUB_TOKEN-<unset>}"
} >>"${GH_LOG:?}"
EOS

chmod +x "$fake_bin/ghtkn" "$fake_bin/gh"
cp "$fake_bin/gh" "$gh_only_bin/gh"

reset_logs() {
  : >"$ghtkn_log"
  : >"$gh_log"
  : >"$stderr_log"
}

run_wrapper() {
  local path_dir="$1"
  shift
  env -u GH_TOKEN -u GITHUB_TOKEN \
    "PATH=$path_dir:/usr/bin:/bin" \
    "FEATURE_SOURCE=$feature_source" \
    "GHTKN_LOG=$ghtkn_log" \
    "GH_LOG=$gh_log" \
    "$@"
}

reset_logs
run_wrapper "$fake_bin" zsh -f -c '
  source "$FEATURE_SOURCE"
  gh api "/repos/o/r" --jq ".name | length"
  [[ ! -v GH_TOKEN ]]
' 2>"$stderr_log"
grep -Fxq "exec -e GH_TOKEN:C-FO/write -- gh api /repos/o/r --jq .name | length" "$ghtkn_log" ||
  fail "wrapper did not call ghtkn exec -e GH_TOKEN:C-FO/write -- gh <args>"
grep -Fxq "argc=4" "$gh_log" || fail "gh received the wrong argument count"
grep -Fxq "arg=.name | length" "$gh_log" ||
  fail "wrapper did not preserve an argument containing spaces"
grep -Fxq "GH_TOKEN=fake-ghtkn-token" "$gh_log" ||
  fail "gh did not receive the token from ghtkn exec"
pass "normal path runs gh through ghtkn exec and keeps the token out of the shell"

reset_logs
env -u GITHUB_TOKEN "GH_TOKEN=caller-token" \
  "PATH=$fake_bin:/usr/bin:/bin" "FEATURE_SOURCE=$feature_source" \
  "GHTKN_LOG=$ghtkn_log" "GH_LOG=$gh_log" \
  zsh -f -c 'source "$FEATURE_SOURCE"; gh repo view'
[[ ! -s "$ghtkn_log" ]] || fail "wrapper called ghtkn despite an explicit GH_TOKEN"
grep -Fxq "GH_TOKEN=caller-token" "$gh_log" ||
  fail "wrapper did not preserve the explicit GH_TOKEN"
pass "explicit GH_TOKEN bypasses ghtkn"

reset_logs
env -u GH_TOKEN "GITHUB_TOKEN=caller-token" \
  "PATH=$fake_bin:/usr/bin:/bin" "FEATURE_SOURCE=$feature_source" \
  "GHTKN_LOG=$ghtkn_log" "GH_LOG=$gh_log" \
  zsh -f -c 'source "$FEATURE_SOURCE"; gh repo view'
[[ ! -s "$ghtkn_log" ]] || fail "wrapper called ghtkn despite an explicit GITHUB_TOKEN"
grep -Fxq "GITHUB_TOKEN=caller-token" "$gh_log" ||
  fail "wrapper did not preserve the explicit GITHUB_TOKEN"
pass "explicit GITHUB_TOKEN bypasses ghtkn"

reset_logs
run_wrapper "$fake_bin" zsh -f -c '
  alias gh="print aliased"
  source "$FEATURE_SOURCE"
  (( ! $+aliases[gh] ))
  eval "gh api /user"
'
grep -Fxq "arg=/user" "$gh_log" || fail "pre-existing gh alias shadowed the wrapper"
pass "pre-existing gh alias does not shadow the wrapper"

reset_logs
rc=0
run_wrapper "$gh_only_bin" zsh -f -c '
  source "$FEATURE_SOURCE"
  gh api /user
' 2>"$stderr_log" || rc=$?
[[ "$rc" -eq 127 ]] || fail "missing ghtkn did not return 127 (got $rc)"
[[ ! -s "$gh_log" ]] || fail "wrapper ran gh without ghtkn"
pass "missing ghtkn returns 127 and does not run gh"

reset_logs
rc=0
run_wrapper "$fake_bin" GHTKN_MODE=no-token zsh -f -c '
  source "$FEATURE_SOURCE"
  gh api /user
' 2>"$stderr_log" || rc=$?
[[ "$rc" -eq 111 ]] || fail "ghtkn exit 111 was not propagated (got $rc)"
grep -Fq "ghtkn agent unlock --enable-refresh" "$stderr_log" ||
  fail "no unlock hint on stderr after ghtkn exit 111"
[[ ! -s "$gh_log" ]] || fail "wrapper ran gh after ghtkn exited 111"
pass "ghtkn exit 111 is propagated with an unlock hint"

render_root="$test_root/rendered"
chezmoi_config="$test_root/chezmoi.json"
mkdir -p "$render_root"
printf '{}\n' >"$chezmoi_config"

client_ids_json='{"none":"Iv1.none","read":"Iv1.read","git":"Iv1.git","write":"Iv1.write"}'

chezmoi_isolated() {
  local business_use="$1"
  shift
  env -u GH_TOKEN -u GITHUB_TOKEN \
    chezmoi \
    --config "$chezmoi_config" \
    --config-format json \
    --source "$repo_root" \
    --destination "$test_root/destination" \
    --override-data "{\"business_use\":$business_use,\"auto_tmux\":false,\"homebrew_prefix\":\"/opt/homebrew\",\"ghtkn_client_ids\":$client_ids_json}" \
    "$@"
}

chezmoi_isolated false execute-template --file "$zshrc_source" >"$render_root/personal.zshrc"
chezmoi_isolated true execute-template --file "$zshrc_source" >"$render_root/business.zshrc"
zsh -n "$render_root/personal.zshrc"
zsh -n "$render_root/business.zshrc"

if grep -Fq "gh: ghtkn is required" "$render_root/personal.zshrc"; then
  fail "personal zshrc unexpectedly contains the ghtkn gh wrapper"
fi
grep -Fq "gh: ghtkn is required" "$render_root/business.zshrc" ||
  fail "business zshrc is missing the ghtkn gh wrapper"
pass "wrapper is rendered only for the business profile"

chezmoi_isolated true execute-template --file "$repo_root/home/dot_zshenv.tmpl" >"$render_root/business.zshenv"
mkdir -p "$test_root/home"
aqua_auth_env="$(
  env -i HOME="$test_root/home" PATH="/usr/bin:/bin" AQUA_KEYRING_ENABLED=true \
    zsh -f -c 'source "$1" >/dev/null 2>&1; print -r -- "keyring=${AQUA_KEYRING_ENABLED-unset} ghtkn=${AQUA_GHTKN_ENABLED-unset}"' \
    zsh "$render_root/business.zshenv"
)"
[[ "$aqua_auth_env" == "keyring=unset ghtkn=true" ]] ||
  fail "business zshenv must drop an inherited AQUA_KEYRING_ENABLED and enable ghtkn (got: $aqua_auth_env)"
pass "business zshenv clears an inherited AQUA_KEYRING_ENABLED"

chezmoi_isolated true execute-template --file "$repo_root/home/dot_config/ghtkn/ghtkn.yaml.tmpl" >"$render_root/ghtkn.yaml"
grep -Fxq "  type: agent # access token の更新を自動化したい場合" "$render_root/ghtkn.yaml" ||
  fail "ghtkn.yaml does not select the agent backend"
for app in none read git write; do
  grep -Fxq "    client_id: \"Iv1.$app\"" "$render_root/ghtkn.yaml" ||
    fail "ghtkn.yaml did not render the $app client id"
  grep -Fq "  - name: C-FO/$app " "$render_root/ghtkn.yaml" ||
    fail "ghtkn.yaml did not render the C-FO/$app app"
done
[[ "$(grep -c '^  - name:' "$render_root/ghtkn.yaml")" -eq 4 ]] ||
  fail "ghtkn.yaml did not render exactly four apps"
grep -Fxq "    git_owner: C-FO # Git Credential Helper により、 C-FO 配下のリポジトリに push/pull する際はこれが使用される" "$render_root/ghtkn.yaml" ||
  fail "ghtkn.yaml did not render git_owner for the git app"
pass "ghtkn.yaml renders every app with the agent backend"

client_ids_json='{"read":"Iv1.read"}'
chezmoi_isolated true execute-template --file "$repo_root/home/dot_config/ghtkn/ghtkn.yaml.tmpl" >"$render_root/ghtkn-partial.yaml"
[[ "$(grep -c '^  - name:' "$render_root/ghtkn-partial.yaml")" -eq 1 ]] ||
  fail "ghtkn.yaml rendered an app without a client id"
grep -Fq "  - name: C-FO/read " "$render_root/ghtkn-partial.yaml" ||
  fail "ghtkn.yaml dropped the app that has a client id"
client_ids_json='{}'
chezmoi_isolated true execute-template --file "$repo_root/home/dot_config/ghtkn/ghtkn.yaml.tmpl" >"$render_root/ghtkn-empty.yaml"
grep -Fxq "apps: []" "$render_root/ghtkn-empty.yaml" ||
  fail "ghtkn.yaml without client ids did not render apps: []"
pass "ghtkn.yaml renders only apps that have a client id"
client_ids_json='{"none":"Iv1.none","read":"Iv1.read","git":"Iv1.git","write":"Iv1.write"}'

chezmoi_isolated false managed >"$render_root/managed-personal.txt"
chezmoi_isolated true managed >"$render_root/managed-business.txt"
if grep -Eq '^\.config/ghtkn(/|$)' "$render_root/managed-personal.txt"; then
  fail "personal profile manages a ghtkn config target"
fi
grep -Fxq ".config/ghtkn/ghtkn.yaml" "$render_root/managed-business.txt" ||
  fail "business profile does not manage .config/ghtkn/ghtkn.yaml"
pass "ghtkn config is managed only for the business profile"

chezmoi_isolated false ignored >"$render_root/ignored-personal.txt"
ghtkn_ignored_targets=(".config/ghtkn" ".chezmoiscripts/load-ghtkn-agent.sh")
# Non-darwin hosts ignore the whole Library/ tree, so the plist is not listed on its own there.
grep -Fxq "Library" "$render_root/ignored-personal.txt" ||
  ghtkn_ignored_targets+=("Library/LaunchAgents/local.ghtkn-agent.plist")
for ghtkn_target in "${ghtkn_ignored_targets[@]}"; do
  grep -Fxq "$ghtkn_target" "$render_root/ignored-personal.txt" ||
    fail "personal profile does not ignore $ghtkn_target"
done
chezmoi_isolated true ignored >"$render_root/ignored-business.txt"
if grep -Fq "ghtkn" "$render_root/ignored-business.txt"; then
  fail "business profile ignores a ghtkn target"
fi
pass "ghtkn agent targets are ignored only for the personal profile"

echo "All ghtkn gh wrapper tests passed."
