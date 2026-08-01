#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
feature_script="$repo_root/home/dot_config/zsh/features/devbox-brew.zsh"
renderer="$repo_root/tests/devbox/render-and-assert.sh"
zsh_program="source \"\$1\"; brewbundle"
test_home=$(mktemp -d)
trap 'rm -rf "$test_home"' EXIT

source_repo="$test_home/.local/share/chezmoi"
source_root="$source_repo/home"
stub_bin="$test_home/bin"
brew_log="$test_home/brew.log"
rendered_root="$test_home/rendered"
devbox_dir="$test_home/.local/share/devbox/global/default"
source_devbox_dir="$source_root/dot_local/share/devbox/global/default"
chezmoi_config="$test_home/.config/chezmoi/chezmoi.yaml"

mkdir -p \
  "$source_root/homebrew" \
  "$stub_bin" \
  "$test_home/.config/chezmoi" \
  "$test_home/.cache" \
  "$test_home/.state" \
  "$test_home/tmp" \
  "$devbox_dir" \
  "$source_devbox_dir"
printf 'home\n' >"$source_repo/.chezmoiroot"
touch "$source_root/homebrew/Brewfile" "$source_root/homebrew/Brewfile.work"
cp \
  "$repo_root/home/dot_local/share/devbox/global/default/devbox.json.tmpl" \
  "$source_devbox_dir/devbox.json.tmpl"

cat >"$stub_bin/brew" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >"$BREW_LOG"

dump_file=
for argument in "$@"; do
  case "$argument" in
    --file=*)
      dump_file=${argument#--file=}
      ;;
  esac
done

if [[ -z "$dump_file" ]]; then
  echo "Missing --file argument" >&2
  exit 1
fi

printf '%s\n' "$BREW_DUMP_CONTENT" >"$dump_file"
EOF
chmod +x "$stub_bin/brew"

for command_name in chezmoi git jq zsh; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Required command not found: $command_name" >&2
    exit 1
  fi
done

bash "$renderer" "$rendered_root" >/dev/null

set_profile_config() {
  local profile="$1"

  if [[ "$profile" == "business" ]]; then
    printf 'data:\n  business_use: true\n' >"$chezmoi_config"
  else
    printf 'data:\n  business_use: false\n' >"$chezmoi_config"
  fi
}

assert_tracked_brewfile_has_no_overlap() {
  local profile="$1"
  local brewfile="$2"
  local homebrew_entries="$test_home/$profile-homebrew-entries"
  local devbox_packages="$test_home/$profile-devbox-packages"
  local overlaps="$test_home/$profile-overlaps"

  sed -nE \
    -e 's/^[[:space:]]*(brew|cargo|npm|uv) "([^"]+)".*/\2/p' \
    -e 's/^[[:space:]]*go "([^"]*\/)?([^/"]+)".*/\2/p' \
    "$brewfile" |
    sed -e 's/^git-delta$/delta/' |
    LC_ALL=C sort -u >"$homebrew_entries"
  jq -r '.packages[] | split("@")[0]' "$rendered_root/$profile/devbox.json" |
    LC_ALL=C sort -u >"$devbox_packages"
  comm -12 "$homebrew_entries" "$devbox_packages" >"$overlaps"

  if [[ -s "$overlaps" ]]; then
    echo "FAIL: tracked $profile Brewfile overlaps with its rendered Devbox profile:" >&2
    sed 's/^/  - /' "$overlaps" >&2
    return 1
  fi
  echo "PASS: tracked $profile Brewfile has no exact-name Devbox overlap"
}

run_success_case() {
  local label="$1"
  local source_override="$2"
  local business_use="$3"
  local expected_brewfile="$4"
  local dump_content="${5:-brew \"openssl@3\"}"
  local -a environment=(
    env
    -u CHEZMOI_SOURCE_DIR
    -u BUSINESS_USE
    "BREW_DUMP_CONTENT=$dump_content"
    "BREW_LOG=$brew_log"
    "HOME=$test_home"
    "PATH=$stub_bin:$PATH"
    "TMPDIR=$test_home/tmp"
    "XDG_CACHE_HOME=$test_home/.cache"
    "XDG_CONFIG_HOME=$test_home/.config"
    "XDG_DATA_HOME=$test_home/.local/share"
    "XDG_STATE_HOME=$test_home/.state"
  )

  if [[ "$source_override" != "unset" ]]; then
    environment+=("CHEZMOI_SOURCE_DIR=$source_override")
  fi
  if [[ "$business_use" == "personal" ]]; then
    # Deliberately contradict the config to prove the raw environment is ignored.
    environment+=("BUSINESS_USE=1")
  fi

  set_profile_config "$business_use"
  cp "$rendered_root/$business_use/devbox.json" "$devbox_dir/devbox.json"
  printf 'original\n' >"$expected_brewfile"
  : >"$brew_log"
  "${environment[@]}" zsh -f -c "$zsh_program" devbox-brew-test "$feature_script" >/dev/null

  local actual_args
  actual_args=$(<"$brew_log")
  if [[ "$actual_args" != bundle\ dump\ --force\ --file=* ]]; then
    echo "FAIL: $label" >&2
    echo "  expected: bundle dump --force --file=<temporary Brewfile>" >&2
    echo "  actual:   $actual_args" >&2
    return 1
  fi
  if [[ "$actual_args" == *"--file=$expected_brewfile"* ]]; then
    echo "FAIL: $label dumped directly to the tracked Brewfile" >&2
    return 1
  fi
  if [[ "$(<"$expected_brewfile")" != "$dump_content" ]]; then
    echo "FAIL: $label did not replace the tracked Brewfile after validation" >&2
    return 1
  fi
  echo "PASS: $label"
}

run_overlap_case() {
  local profile="$1"
  local directive="$2"
  local overlap="$3"
  local expected_name="${4:-$overlap}"
  local expected_brewfile
  local output
  local status
  local -a environment=(
    env
    -u BUSINESS_USE
    "BREW_DUMP_CONTENT=$directive \"$overlap\""
    "BREW_LOG=$brew_log"
    "CHEZMOI_SOURCE_DIR=$source_repo"
    "HOME=$test_home"
    "PATH=$stub_bin:$PATH"
    "TMPDIR=$test_home/tmp"
    "XDG_CACHE_HOME=$test_home/.cache"
    "XDG_CONFIG_HOME=$test_home/.config"
    "XDG_DATA_HOME=$test_home/.local/share"
    "XDG_STATE_HOME=$test_home/.state"
  )

  if [[ "$profile" == "business" ]]; then
    expected_brewfile="$source_root/homebrew/Brewfile.work"
  else
    environment+=("BUSINESS_USE=1")
    expected_brewfile="$source_root/homebrew/Brewfile"
  fi

  set_profile_config "$profile"
  cp "$rendered_root/$profile/devbox.json" "$devbox_dir/devbox.json"
  printf 'original\n' >"$expected_brewfile"

  set +e
  output=$("${environment[@]}" zsh -f -c "$zsh_program" devbox-brew-test "$feature_script" 2>&1)
  status=$?
  set -e

  if [[ "$status" -eq 0 ]]; then
    echo "FAIL: $profile $directive overlap should be rejected" >&2
    return 1
  fi
  if [[ "$(<"$expected_brewfile")" != "original" ]]; then
    echo "FAIL: $profile $directive overlap changed the tracked Brewfile" >&2
    return 1
  fi
  if [[ "$output" != *"Refusing to update"* || "$output" != *"  - $expected_name"* ]]; then
    echo "FAIL: $profile $directive overlap diagnostic did not name $expected_name" >&2
    echo "$output" >&2
    return 1
  fi
  echo "PASS: $profile $directive overlap rejected as $expected_name"
}

run_stale_manifest_case() {
  local expected_brewfile="$source_root/homebrew/Brewfile"
  local output
  local status
  local -a environment=(
    env
    "BREW_DUMP_CONTENT=brew \"openssl@3\""
    "BREW_LOG=$brew_log"
    "BUSINESS_USE=1"
    "CHEZMOI_SOURCE_DIR=$source_repo"
    "HOME=$test_home"
    "PATH=$stub_bin:$PATH"
    "TMPDIR=$test_home/tmp"
    "XDG_CACHE_HOME=$test_home/.cache"
    "XDG_CONFIG_HOME=$test_home/.config"
    "XDG_DATA_HOME=$test_home/.local/share"
    "XDG_STATE_HOME=$test_home/.state"
  )

  set_profile_config personal
  cp "$rendered_root/business/devbox.json" "$devbox_dir/devbox.json"
  printf 'original\n' >"$expected_brewfile"
  : >"$brew_log"

  set +e
  output=$("${environment[@]}" zsh -f -c "$zsh_program" devbox-brew-test "$feature_script" 2>&1)
  status=$?
  set -e

  if [[ "$status" -eq 0 ]]; then
    echo "FAIL: stale active manifest should be rejected" >&2
    return 1
  fi
  if [[ "$(<"$expected_brewfile")" != "original" ]]; then
    echo "FAIL: stale active manifest changed the config-derived personal Brewfile" >&2
    return 1
  fi
  if [[ -s "$brew_log" ]]; then
    echo "FAIL: stale active manifest invoked brew before validation" >&2
    return 1
  fi
  if [[ "$output" != *"Active Devbox manifest differs"* || "$output" != *"chezmoi apply"* ]]; then
    echo "FAIL: stale active manifest diagnostic is incomplete" >&2
    echo "$output" >&2
    return 1
  fi
  echo "PASS: stale active manifest rejected before brew dump"
}

assert_tracked_brewfile_has_no_overlap personal "$repo_root/home/homebrew/Brewfile"
assert_tracked_brewfile_has_no_overlap business "$repo_root/home/homebrew/Brewfile.work"
run_success_case "active source, personal" unset personal "$source_root/homebrew/Brewfile"
run_success_case "active source, business" unset business "$source_root/homebrew/Brewfile.work"
run_success_case "repo-root override, personal" "$source_repo" personal "$source_root/homebrew/Brewfile"
run_success_case "repo-root override, business" "$source_repo" business "$source_root/homebrew/Brewfile.work"
run_success_case "resolved-root override, personal" "$source_root" personal "$source_root/homebrew/Brewfile"
run_success_case "resolved-root override, business" "$source_root" business "$source_root/homebrew/Brewfile.work"
# Every Node distribution ships corepack in its global node_modules, so `brew
# bundle dump` reports it on any machine that has Node at all. Treating it as a
# duplicate of the Devbox nodejs package would block brewbundle unconditionally.
run_success_case "node-bundled corepack, personal" unset personal "$source_root/homebrew/Brewfile" 'npm "corepack"'
run_overlap_case personal brew protobuf
run_overlap_case business brew colima
run_overlap_case business cargo atuin
run_overlap_case business cargo git-delta delta
run_overlap_case personal go github.com/fullstorydev/grpcurl/cmd/grpcurl grpcurl
run_overlap_case personal npm pnpm
run_overlap_case personal uv yamllint
run_stale_manifest_case

echo "All devbox-brew tests passed."
