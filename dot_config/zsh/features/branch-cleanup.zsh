# Remove merged branches (from existing config)
PROTECTED_BRANCHES='main|master|develop|staging'
rub() {
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Error: Not in a git repository" >&2
    return 1
  fi
  local merged
  merged=$(git branch --format='%(refname:short)' --merged \
    | grep -Evx "${PROTECTED_BRANCHES}" \
    | grep -Fvx "$(git branch --show-current)")
  [[ -z "$merged" ]] && echo "No merged branches to delete" && return 0
  echo "$merged" | xargs git branch -d
}
