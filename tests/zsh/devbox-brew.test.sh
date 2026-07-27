#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
feature_script="$repo_root/home/dot_config/zsh/features/devbox-brew.zsh"
zsh_program="source \"\$1\"; brewbundle"
test_home=$(mktemp -d)
trap 'rm -rf "$test_home"' EXIT

source_repo="$test_home/.local/share/chezmoi"
source_root="$source_repo/home"
stub_bin="$test_home/bin"
brew_log="$test_home/brew.log"

mkdir -p "$source_root/homebrew" "$stub_bin" "$test_home/.config" "$test_home/.cache"
printf 'home\n' >"$source_repo/.chezmoiroot"
touch "$source_root/homebrew/Brewfile" "$source_root/homebrew/Brewfile.work"

cat >"$stub_bin/brew" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >"$BREW_LOG"
EOF
chmod +x "$stub_bin/brew"

for command_name in chezmoi git zsh; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Required command not found: $command_name" >&2
    exit 1
  fi
done

run_case() {
  local label="$1"
  local source_override="$2"
  local business_use="$3"
  local expected_brewfile="$4"
  local -a environment=(
    env
    -u CHEZMOI_SOURCE_DIR
    -u BUSINESS_USE
    "BREW_LOG=$brew_log"
    "HOME=$test_home"
    "PATH=$stub_bin:$PATH"
    "XDG_CACHE_HOME=$test_home/.cache"
    "XDG_CONFIG_HOME=$test_home/.config"
    "XDG_DATA_HOME=$test_home/.local/share"
  )

  if [[ "$source_override" != "unset" ]]; then
    environment+=("CHEZMOI_SOURCE_DIR=$source_override")
  fi
  if [[ "$business_use" == "business" ]]; then
    environment+=("BUSINESS_USE=1")
  fi

  : >"$brew_log"
  "${environment[@]}" zsh -f -c "$zsh_program" devbox-brew-test "$feature_script" >/dev/null

  local actual_args
  actual_args=$(<"$brew_log")
  local expected_args="bundle dump --force --file=$expected_brewfile"
  if [[ "$actual_args" != "$expected_args" ]]; then
    echo "FAIL: $label" >&2
    echo "  expected: $expected_args" >&2
    echo "  actual:   $actual_args" >&2
    return 1
  fi
  echo "PASS: $label"
}

run_case "active source, personal" unset personal "$source_root/homebrew/Brewfile"
run_case "active source, business" unset business "$source_root/homebrew/Brewfile.work"
run_case "repo-root override, personal" "$source_repo" personal "$source_root/homebrew/Brewfile"
run_case "repo-root override, business" "$source_repo" business "$source_root/homebrew/Brewfile.work"
run_case "resolved-root override, personal" "$source_root" personal "$source_root/homebrew/Brewfile"
run_case "resolved-root override, business" "$source_root" business "$source_root/homebrew/Brewfile.work"

echo "All devbox-brew tests passed."
