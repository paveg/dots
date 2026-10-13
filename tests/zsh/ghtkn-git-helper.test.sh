#!/usr/bin/env bash
# Verify the business-only C-FO ghtkn helper wiring in the rendered git config
# without invoking any credential helper.
set -euo pipefail

unset GH_TOKEN GITHUB_TOKEN

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd "$script_dir/../.." && pwd -P)"
git_source_dir="$repo_root/home/dot_config/git"

for required_command in chezmoi cp git grep mkdir tail; do
  command -v "$required_command" >/dev/null 2>&1 || {
    echo "required command not found: $required_command" >&2
    exit 1
  }
done

test_root="$(mktemp -d "${TMPDIR:-/tmp}/dots-ghtkn-git.XXXXXX")"
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

chezmoi_config="$test_root/chezmoi.json"
printf '{}\n' >"$chezmoi_config"

render() {
  local business_use="$1"
  local template="$2"
  local output="$3"

  chezmoi \
    --config "$chezmoi_config" \
    --config-format json \
    --source "$repo_root" \
    --override-data "{\"business_use\":$business_use,\"name\":\"Test\",\"email\":\"t@example.com\",\"work_email\":\"t@work.example.com\",\"signing_key\":\"\"}" \
    execute-template --file "$template" >"$output"
}

run_git() {
  local profile_home="$1"
  shift
  env -i \
    "PATH=$PATH" \
    "HOME=$profile_home" \
    "GIT_CONFIG_GLOBAL=$profile_home/.config/git/config" \
    GIT_CONFIG_NOSYSTEM=1 \
    git "$@"
}

in_repo() {
  local profile_home="$1"
  local repo="$2"
  shift 2
  run_git "$profile_home" -C "$profile_home/repos/github.com/$repo" "$@"
}

# Deploy the rendered config into a throwaway HOME so `~/.config/git/...` includes resolve to it.
setup_profile() {
  local profile="$1"
  local business_use="$2"
  local profile_home="$test_root/$profile"

  mkdir -p "$profile_home/.config/git" "$profile_home/repos/github.com/C-FO" "$profile_home/repos/github.com/other"
  cp "$git_source_dir/config" "$profile_home/.config/git/config"
  render "$business_use" "$git_source_dir/main.tmpl" "$profile_home/.config/git/main"
  render "$business_use" "$git_source_dir/work.tmpl" "$profile_home/.config/git/work"
  run_git "$profile_home" init -q "$profile_home/repos/github.com/C-FO/clusterops"
  run_git "$profile_home" init -q "$profile_home/repos/github.com/other/project"
}

setup_profile business true
setup_profile personal false
business_home="$test_root/business"
personal_home="$test_root/personal"

cfo_url="https://github.com/C-FO/clusterops"
other_url="https://github.com/other/project"
helper_pattern='^credential\..*helper$'

[[ "$(in_repo "$business_home" C-FO/clusterops ls-remote --get-url "$cfo_url")" == "$cfo_url" ]] ||
  fail "business: a C-FO URL was rewritten away from HTTPS"
[[ "$(in_repo "$business_home" C-FO/clusterops ls-remote --get-url "$other_url")" == "git@github.com:other/project" ]] ||
  fail "business: a non-C-FO URL was not rewritten to SSH"
pass "business: C-FO stays HTTPS while other owners use SSH"

business_helpers="$(in_repo "$business_home" C-FO/clusterops config --get-regexp "$helper_pattern")"
[[ "$(tail -n 1 <<<"$business_helpers")" == "credential.https://github.com/C-FO.helper !ghtkn git-credential" ]] ||
  fail "business: the ghtkn helper is not the last helper entry, so a gh helper entry would be appended after the reset"
pass "business: the C-FO ghtkn helper comes after the gh helper entries"

[[ "$(in_repo "$business_home" C-FO/clusterops config --type=bool --get-urlmatch credential.useHttpPath "$cfo_url")" == "true" ]] ||
  fail "business: useHttpPath is not enabled for C-FO URLs"
pass "business: helper lookup is path-aware"

other_helpers="$(in_repo "$business_home" other/project config --get-regexp "$helper_pattern")"
if grep -Fq "ghtkn" <<<"$other_helpers"; then
  fail "business: the ghtkn helper leaks outside the C-FO checkout"
fi
pass "business: the ghtkn helper is limited to the C-FO checkout"

if grep -Fq "C-FO" "$personal_home/.config/git/work"; then
  fail "personal: the work config mentions C-FO"
fi
personal_helpers="$(in_repo "$personal_home" C-FO/clusterops config --get-regexp "$helper_pattern")"
if grep -Fq "ghtkn" <<<"$personal_helpers"; then
  fail "personal: a ghtkn helper is configured"
fi
[[ "$(in_repo "$personal_home" C-FO/clusterops ls-remote --get-url "$other_url")" == "$other_url" ]] ||
  fail "personal: GitHub URLs were rewritten"
pass "personal: no C-FO helper or insteadOf configuration"

echo "All ghtkn git helper tests passed."
