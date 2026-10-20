#!/usr/bin/env bash
# Fails when a change deletes or renames a deployed source file without naming
# its target in home/.chezmoiremove. chezmoi forgets a deleted source and leaves
# the deployed copy in place, so rules, skills and hooks keep running or billing
# on every machine that applied before the deletion.
#
# usage: check-chezmoiremove.sh [base] [head]   (default: origin/main HEAD)
# SOURCE_ROOT overrides the chezmoi source directory (default: home).
set -euo pipefail

base=${1:-origin/main}
head=${2:-HEAD}
source_root=${SOURCE_ROOT-home}
prefix=${source_root:+$source_root/}

for ref in "$base" "$head"; do
  git rev-parse --verify --quiet "$ref^{commit}" >/dev/null || {
    echo "✗ cannot resolve $ref: run 'git fetch origin main' (CI checkout needs fetch-depth: 0)" >&2
    exit 1
  }
done
git merge-base "$base" "$head" >/dev/null || {
  echo "✗ $base and $head share no merge base: fetch full history (fetch-depth: 0)" >&2
  exit 1
}

# Ceiling: literal_, remove_, .age, and exact_-directory deletion are not modelled; none exist here yet.
target_path() {
  local source_path="$1" component result="" stripped
  local IFS=/
  for component in $source_path; do
    stripped=$component
    while :; do
      case "$stripped" in
        exact_* | private_* | readonly_* | executable_* | empty_* | encrypted_* | external_* | once_* | onchange_* | create_* | modify_* | symlink_*)
          stripped=${stripped#*_}
          ;;
        *) break ;;
      esac
    done
    case "$stripped" in
      dot_*) stripped=.${stripped#dot_} ;;
    esac
    result+=${result:+/}$stripped
  done
  echo "${result%.tmpl}"
}

is_deployed_source() {
  local relative="$1" part
  local IFS=/
  for part in $relative; do
    case "$part" in
      run_* | .chezmoi* | .gitkeep | README.md) return 1 ;;
    esac
  done
  return 0
}

removed_sources=$(git diff --name-status -M --diff-filter=DR "$base...$head" -- "${source_root:-.}" |
  awk -F'\t' '{print $2}')

remaining_targets=$(git ls-tree -r --name-only "$head" -- "${source_root:-.}" | while IFS= read -r path; do
  relative=${path#"$prefix"}
  is_deployed_source "$relative" && target_path "$relative"
done || true)

remove_entries=$(git show "$head:${prefix}.chezmoiremove" 2>/dev/null | grep -vE '^[[:space:]]*(#|$)' || true)

missing=0
while IFS= read -r path; do
  [[ -n "$path" ]] || continue
  relative=${path#"$prefix"}
  is_deployed_source "$relative" || continue
  target=$(target_path "$relative")
  grep -Fxq -- "$target" <<<"$remaining_targets" && continue

  covered=0
  candidate=$target
  while [[ -n "$candidate" ]]; do
    if grep -Fxq -- "$candidate" <<<"$remove_entries"; then
      covered=1
      break
    fi
    [[ "$candidate" == */* ]] || break
    candidate=${candidate%/*}
  done

  if ((covered == 0)); then
    echo "✗ $path was removed but its target is not in ${prefix}.chezmoiremove: add the line '$target'" >&2
    missing=$((missing + 1))
  fi
done <<<"$removed_sources"

if ((missing > 0)); then
  echo "chezmoi leaves deployed copies of removed sources in place; list each target in ${prefix}.chezmoiremove." >&2
  exit 1
fi
echo "✓ every removed source has a .chezmoiremove entry ($base...$head)"
