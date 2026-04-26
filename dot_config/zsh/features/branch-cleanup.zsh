# Remove merged branches (from existing config)
PROTECTED_BRANCHES='main|master|develop|staging'
rub() {
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Error: Not in a git repository" >&2
    return 1
  fi
  local merged
  merged=$(git branch --merged | grep -Ev "*|${PROTECTED_BRANCHES}")
  [[ -z "$merged" ]] && echo "No merged branches to delete" && return 0
  echo "$merged" | xargs git branch -d
}
