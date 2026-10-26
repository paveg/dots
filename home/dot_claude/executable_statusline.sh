#!/usr/bin/env bash
# Claude Code statusLine: reads the session JSON on stdin and prints two lines.
# Everything except git branch/changes comes from that JSON, so the only
# subprocess besides jq is one cached `git status`.
set -uo pipefail

input=$(cat)

IFS=$'\x1f' read -r session_id current_dir repo_name worktree pr_number model effort \
  context_percent cost_usd duration_ms five_hour_percent five_hour_resets_at < <(
  jq -r '[
    .session_id // "",
    .workspace.current_dir // .cwd // "",
    .workspace.repo.name // "",
    .workspace.git_worktree // "",
    .pr.number // "",
    .model.display_name // "",
    .effort.level // "",
    (.context_window.used_percentage // 0 | floor),
    (.cost.total_cost_usd // 0),
    (.cost.total_duration_ms // 0),
    (.rate_limits.five_hour.used_percentage // "" | if . == "" then . else floor end),
    .rate_limits.five_hour.resets_at // ""
  ] | map(tostring) | join("\u001f")' <<<"$input"
)

reset=$'\033[0m'
blue=$'\033[34m'
cyan=$'\033[36m'
magenta=$'\033[35m'
yellow=$'\033[33m'
green=$'\033[32m'
red=$'\033[31m'

git_cache="${TMPDIR:-/tmp}/claude-statusline-git-${session_id:-none}"
now=$(date +%s)
cached_at=0
[[ -f $git_cache ]] && IFS=$'\x1f' read -r cached_at branch staged modified untracked <"$git_cache"
if ((now - cached_at > 5)); then
  git -C "$current_dir" status --porcelain=v2 --branch 2>/dev/null | awk -v now="$now" '
    $1 == "#" && $2 == "branch.head" { branch = $3 }
    $1 ~ /^[12u]$/ && substr($2, 1, 1) != "." { staged++ }
    $1 ~ /^[12u]$/ && substr($2, 2, 1) != "." { modified++ }
    $1 == "?" { untracked++ }
    END { printf "%s\037%s\037%d\037%d\037%d\n", now, branch, staged, modified, untracked }
  ' >"$git_cache"
  IFS=$'\x1f' read -r cached_at branch staged modified untracked <"$git_cache"
fi

email=$(jq -r '.oauthAccount.emailAddress // empty' "$HOME/.claude.json" 2>/dev/null)

line1=()
[[ -n $email ]] && line1+=("${blue}${email}${reset}")
location=${repo_name:-${current_dir##*/}}
[[ -n $worktree ]] && location+="/${worktree}"
line1+=("${cyan}${location}${reset}")
if [[ -n ${branch:-} ]]; then
  changes=""
  ((staged > 0)) && changes+=" +${staged}"
  ((modified > 0)) && changes+=" ~${modified}"
  ((untracked > 0)) && changes+=" ?${untracked}"
  line1+=("${magenta}${branch}${reset}${yellow}${changes}${reset}")
fi
[[ -n $pr_number ]] && line1+=("${cyan}#${pr_number}${reset}")

if ((context_percent >= 80)); then
  bar_color=$red
elif ((context_percent >= 50)); then
  bar_color=$yellow
else
  bar_color=$green
fi
filled=$((context_percent / 10))
printf -v bar_filled '%*s' "$filled" ''
printf -v bar_empty '%*s' "$((10 - filled))" ''
bar="${bar_color}${bar_filled// /▓}${bar_empty// /░}${reset} ${context_percent}%"

line2=("${cyan}${model}${reset}${effort:+ ${magenta}${effort}${reset}}" "$bar")
if [[ -n $five_hour_percent ]]; then
  five_hour="5h ${five_hour_percent}%"
  [[ -n $five_hour_resets_at ]] && five_hour+=" ↻$(date -r "$five_hour_resets_at" +%H:%M 2>/dev/null || date -d "@$five_hour_resets_at" +%H:%M)"
  line2+=("${yellow}${five_hour}${reset}")
fi
line2+=("${yellow}$((duration_ms / 60000))m${reset}")
printf -v cost '$%.2f' "$cost_usd"
line2+=("${green}${cost}${reset}")

join_with_separator() {
  local separator=" | " output="$1"
  shift
  for part in "$@"; do output+="${separator}${part}"; done
  printf '%s\n' "$output"
}
join_with_separator "${line1[@]}"
join_with_separator "${line2[@]}"
