# =============================================================================
# AtCoder login via 1Password
# =============================================================================
# Fetches credentials from the AtCoder item in Personal vault and runs oj login,
# then propagates the REVEL_SESSION cookie to acc (atcoder-cli) so both tools
# share authentication. oj and acc authenticate against the same AtCoder domain
# but use different session stores, and acc's `login` command requires an
# interactive inquirer prompt, so sharing oj's freshly-minted cookie is the
# cleanest automation path.
#
# Uses field id (not label) to disambiguate duplicate-labeled fields created by
# 1Password's web form autofill. Session cookies are written under:
#   oj:  ~/Library/Application Support/online-judge-tools/cookie.jar  (macOS)
#        $XDG_CONFIG_HOME/online-judge-tools/cookie.jar               (Linux)
#   acc: ~/Library/Preferences/atcoder-cli-nodejs/session.json        (macOS)
#        $XDG_CONFIG_HOME/atcoder-cli-nodejs/session.json             (Linux)
atcoder-login() {
  if ! command -v op >/dev/null 2>&1; then
    echo "Error: op (1Password CLI) not found" >&2
    return 1
  fi
  if ! command -v oj >/dev/null 2>&1; then
    echo "Error: oj (online-judge-tools) not found — run 'devbox install'" >&2
    return 1
  fi

  local item='tcrb5hlxmncj3d45ttchkx6y5y'
  local json user pass
  json=$(op item get "$item" --format json --reveal) || return 1
  user=$(echo "$json" | jq -r '.fields[] | select(.id == "username") | .value')
  pass=$(echo "$json" | jq -r '.fields[] | select(.id == "password") | .value')

  if [[ -z "$user" || -z "$pass" ]]; then
    echo "Error: failed to extract credentials (id='username'/'password' not found)" >&2
    return 1
  fi

  oj login https://atcoder.jp/ -u "$user" -p "$pass" || return 1

  # Sync REVEL_SESSION to acc so `acc session` reports logged-in.
  if command -v acc >/dev/null 2>&1; then
    local oj_jar acc_conf_dir session
    if [[ "$OSTYPE" == linux* ]]; then
      oj_jar="${XDG_CONFIG_HOME:-$HOME/.config}/online-judge-tools/cookie.jar"
      acc_conf_dir="${XDG_CONFIG_HOME:-$HOME/.config}/atcoder-cli-nodejs"
    else
      oj_jar="$HOME/Library/Application Support/online-judge-tools/cookie.jar"
      acc_conf_dir="$HOME/Library/Preferences/atcoder-cli-nodejs"
    fi

    if [[ -f "$oj_jar" ]]; then
      session=$(sed -nE 's/^Set-Cookie3: REVEL_SESSION="([^"]+)".*$/\1/p' "$oj_jar" | head -1)
      if [[ -n "$session" ]]; then
        mkdir -p "$acc_conf_dir"
        jq -n --arg s "$session" '{cookies: ["REVEL_FLASH=", "REVEL_SESSION=" + $s]}' \
          >"$acc_conf_dir/session.json"
        echo "Synced REVEL_SESSION to acc"
      else
        echo "Warning: REVEL_SESSION not found in $oj_jar — acc session not updated" >&2
      fi
    fi
  fi
}

# Open the current AtCoder task's problem page in the browser.
# Run from a task directory (e.g., ~/repos/github.com/paveg/atcoder/abc321/a).
# Derives URL from the directory hierarchy: <contest>/<task>.
atc-open() {
  local task contest
  task=$(basename "$PWD")
  contest=$(basename "$(dirname "$PWD")")
  open "https://atcoder.jp/contests/${contest}/tasks/${contest}_${task}"
}

# Open the contest's task list page in the browser.
# If run from a task directory, uses the parent (contest) name.
# If run from a contest directory, uses the cwd name.
atc-top() {
  local contest
  # Heuristic: if cwd contains tests/ or main.go, treat as task dir → use parent
  if [[ -d tests || -f main.go ]]; then
    contest=$(basename "$(dirname "$PWD")")
  else
    contest=$(basename "$PWD")
  fi
  open "https://atcoder.jp/contests/${contest}/tasks"
}

# Build main.go and run sample tests.
# acc writes samples to tests/ (plural), oj defaults to test/ (singular) — both
# are supported. Additional args pass through to oj t (e.g., --print-input).
atc-test() {
  go build -o a.out main.go || return 1
  local dir
  if [[ -d tests ]]; then
    dir=tests
  elif [[ -d test ]]; then
    dir=test
  else
    echo "No tests/ or test/ directory found" >&2
    return 1
  fi
  oj t -d "$dir" "$@"
}

# Submit the current task's main.go to AtCoder by calling oj directly.
# Bypasses `acc submit` because acc's facade-arg handling currently breaks
# oj's URL guess when extra options (e.g. -l) are passed. Derives URL from
# the cwd hierarchy (same convention as atc-open). `-l 6051` pins to
# "Go (go 1.25.1)" so oj does not prompt between that and gccgo (6050).
# Override language with `atc-submit -l <id>`; auto-yes with `-y`.
atc-submit() {
  local task contest url
  task=$(basename "$PWD")
  contest=$(basename "$(dirname "$PWD")")
  url="https://atcoder.jp/contests/${contest}/tasks/${contest}_${task}"
  oj s "$url" main.go -l 6051 "$@"
}
