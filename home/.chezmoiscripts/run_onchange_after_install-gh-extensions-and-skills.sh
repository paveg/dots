#!/bin/bash
# Install the gh CLI extensions and agent skills this setup relies on. Both sit
# outside the devbox/mise/Homebrew waterfall because gh vendors them itself —
# extensions under ~/.local/share/gh/extensions, skills under ~/.claude/skills —
# so without this list they never reach a new machine.
#
# Upstream releases are not tracked: the script re-runs only when its own
# contents change, so upgrades need `gh extension upgrade` / `gh skill update`.
#
# Triggered on chezmoi apply when this script changes.

set -euo pipefail

extensions=(
  babarot/gh-infra
  github/gh-stack
)

# "<repository> <skill>" pairs, installed for Claude Code at user scope.
skills=(
  "github/gh-stack gh-stack"
)

if ! command -v gh >/dev/null 2>&1; then
  echo "gh not found — skipping gh extension and skill install" >&2
  exit 0
fi

# Both installers hit the API, so an unauthenticated first-run apply would abort
# here instead of reaching run_once_setup-gh-auth.sh.
if ! gh auth status >/dev/null 2>&1; then
  echo "gh is not authenticated — skipping gh extension and skill install" >&2
  exit 0
fi

installed_extensions="$(gh extension list 2>/dev/null | awk -F'\t' '{print $2}')"

for extension in "${extensions[@]}"; do
  if grep -qxF "$extension" <<<"$installed_extensions"; then
    continue
  fi
  echo "Installing gh extension: $extension"
  gh extension install "$extension"
done

# gh skill install exits non-zero when the skill is already present, so each one
# needs a presence check before install rather than a tolerated failure.
installed_skills="$(gh skill list 2>/dev/null | awk -F'\t' '$2 == "claude-code" { print $1 }')"

for skill in "${skills[@]}"; do
  read -r repository name <<<"$skill"
  if grep -qxF "$name" <<<"$installed_skills"; then
    continue
  fi
  echo "Installing gh skill: $repository $name"
  gh skill install "$repository" "$name" --agent claude-code --scope user
done
