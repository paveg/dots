#!/usr/bin/env bash
# Tests for executable_statusline.sh: the statusLine command that renders the
# session JSON from stdin into one or two lines without network or package managers.
set -uo pipefail
unset COLUMNS
export LC_ALL=C.UTF-8

script="$HOOKS_DIR/../executable_statusline.sh"
[[ -f $script ]] || { echo "statusline not found: $script"; exit 1; }

repo="$(mktemp -d "${TMPDIR:-/tmp}/statusline-repo.XXXXXX")"
trap 'rm -rf -- "$repo" "${TMPDIR:-/tmp}"/claude-statusline-git-statusline-test-*' EXIT
git -C "$repo" init -q -b topic
touch "$repo/untracked-file"

run() {
  printf '%s' "$1" | bash "$script" | sed $'s/\033\\[[0-9;]*m//g'
}

full_input=$(jq -n --arg dir "$repo" '{
  session_id: "statusline-test-full",
  workspace: {current_dir: $dir, repo: {name: "dots"}, git_worktree: "wt"},
  pr: {number: 42},
  model: {display_name: "Opus"},
  effort: {level: "high"},
  context_window: {used_percentage: 57.9},
  cost: {total_cost_usd: 1.234, total_duration_ms: 754000},
  rate_limits: {five_hour: {used_percentage: 31.6, resets_at: 1793000000}}
}')
out=$(run "$full_input")
line1=$(sed -n 1p <<<"$out")
line2=$(sed -n 2p <<<"$out")
[[ $(wc -l <<<"$out") -eq 2 ]] || { echo "expected two lines: $out"; exit 1; }
[[ $line1 == "dots/wt | topic ?1 | #42" ]] || { echo "line 1 wrong: $line1"; exit 1; }
[[ $line2 == "Opus high | ▓▓▓▓▓░░░░░ 57% | 5h 31% ↻"*" | 12m | \$1.23" ]] || { echo "line 2 wrong: $line2"; exit 1; }

# Fields Claude Code omits (no effort, rate limits, PR, repo) must not leave empty segments.
sparse_input=$(jq -n --arg dir "$repo" '{session_id: "statusline-test-sparse", workspace: {current_dir: $dir}, model: {display_name: "Haiku"}}')
out=$(run "$sparse_input")
[[ $(sed -n 1p <<<"$out") == "${repo##*/} | topic ?1" ]] || { echo "sparse line 1 wrong: $out"; exit 1; }
[[ $(sed -n 2p <<<"$out") == "Haiku | ░░░░░░░░░░ 0% | 0m | \$0.00" ]] || { echo "sparse line 2 wrong: $out"; exit 1; }

# Outside a git repository the branch segment is dropped, not filled by a shifted count.
plain_dir="$repo/not-a-repo-$$"
mkdir -p "$plain_dir"
out=$(GIT_CEILING_DIRECTORIES="$repo" run "$(jq -n --arg dir "$plain_dir" '{session_id: "statusline-test-nogit", workspace: {current_dir: $dir}}')")
[[ $(sed -n 1p <<<"$out") == "${plain_dir##*/}" ]] || { echo "non-git line 1 wrong: $out"; exit 1; }

# With $COLUMNS wide enough (notification margin included), both lines join into one.
out=$(COLUMNS=200 run "$full_input")
[[ $(wc -l <<<"$out") -eq 1 && $out == "$line1 | $line2" ]] || { echo "wide terminal should print one line: $out"; exit 1; }
# One column short of fitting falls back to two lines; ▓░↻ must count as one column each even without a UTF-8 locale.
fit_columns=$(( ${#line1} + 3 + ${#line2} + 20 ))
out=$(COLUMNS=$fit_columns run "$full_input")
[[ $(wc -l <<<"$out") -eq 1 ]] || { echo "exact fit should print one line: $out"; exit 1; }
out=$(printf '%s' "$full_input" | env -u LANG -u LC_ALL -u LC_CTYPE COLUMNS=$((fit_columns - 1)) bash "$script" | sed $'s/\033\\[[0-9;]*m//g')
[[ $(wc -l <<<"$out") -eq 2 ]] || { echo "one column short should print two lines: $out"; exit 1; }
out=$(printf '%s' "$full_input" | env -u LANG -u LC_ALL -u LC_CTYPE COLUMNS=$fit_columns bash "$script" | sed $'s/\033\\[[0-9;]*m//g')
[[ $(wc -l <<<"$out") -eq 1 ]] || { echo "exact fit without a UTF-8 locale should print one line: $out"; exit 1; }
