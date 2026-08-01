# devbox-brew.zsh - wrap devbox to persist global changes via chezmoi; dump Brewfile
# Provides:     devbox, brewbundle
# Requires:     devbox, chezmoi, brew, jq
devbox() {
  command devbox "$@"
  local ret=$?

  if [[ "$1" == "global" ]] && [[ "$2" =~ ^(add|rm|install|remove|update)$ ]]; then
    local json="${HOME}/.local/share/devbox/global/default/devbox.json"
    local src
    src="$(chezmoi source-path "$json" 2>/dev/null)"

    if [[ "$src" == *.tmpl ]]; then
      # chezmoi re-add silently skips template sources, so it can't round-trip
      # the business/personal split — edit the template by hand instead.
      echo "⚠ devbox.json is a chezmoi template — change NOT auto-persisted." >&2
      echo "  Update ${src} (personal packages: the 'not .business_use' block)." >&2
    elif [[ -n "$src" ]]; then
      chezmoi re-add "$json" 2>/dev/null && echo "📦 chezmoi re-add: devbox.json"
    fi
  fi

  return $ret
}

# Brewfile management (macOS)
brewbundle() {
  setopt local_options pipefail

  local source_hint="${CHEZMOI_SOURCE_DIR:-}"
  local config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"
  local chezmoi_config="$config_home/chezmoi/chezmoi.yaml"
  local source_dir
  local brewfile
  local devbox_manifest="${HOME}/.local/share/devbox/global/default/devbox.json"
  local devbox_template
  local temp_dir
  local business_use
  local rendered_manifest
  local rendered_canonical
  local active_canonical
  local dumped_brewfile
  local homebrew_entries
  local devbox_packages
  local overlaps

  if [[ ! -f "$chezmoi_config" ]]; then
    echo "Chezmoi config not found: $chezmoi_config" >&2
    echo "Run 'chezmoi apply' before brewbundle." >&2
    return 1
  fi

  if [[ -n "$source_hint" ]]; then
    source_dir="$(chezmoi --config "$chezmoi_config" --source "$source_hint" source-path 2>/dev/null)" || {
      echo "Could not resolve the chezmoi source directory from CHEZMOI_SOURCE_DIR: $source_hint" >&2
      return 1
    }
  else
    source_dir="$(chezmoi --config "$chezmoi_config" source-path 2>/dev/null)" || {
      echo "Could not resolve the active chezmoi source directory." >&2
      return 1
    }
  fi

  if [[ -z "$source_dir" ]]; then
    echo "chezmoi returned an empty source directory." >&2
    return 1
  fi

  devbox_template="$source_dir/dot_local/share/devbox/global/default/devbox.json.tmpl"
  if [[ ! -f "$devbox_template" ]]; then
    echo "Devbox manifest template not found: $devbox_template" >&2
    return 1
  fi

  temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/brewbundle.XXXXXX")" || return 1
  rendered_manifest="$temp_dir/rendered-devbox.json"
  rendered_canonical="$temp_dir/rendered-canonical.json"
  active_canonical="$temp_dir/active-canonical.json"
  dumped_brewfile="$temp_dir/Brewfile"
  homebrew_entries="$temp_dir/homebrew-entries"
  devbox_packages="$temp_dir/devbox-packages"
  overlaps="$temp_dir/overlaps"

  if ! business_use="$(
    command chezmoi \
      --config "$chezmoi_config" \
      --source "$source_dir" \
      data --format json |
      command jq -er '
        if (.business_use | type) == "boolean" then
          .business_use | tostring
        else
          error(".business_use must be boolean")
        end
      '
  )"; then
    echo "Chezmoi data must contain a boolean .business_use profile." >&2
    echo "Run 'chezmoi apply' before brewbundle." >&2
    rm -rf "$temp_dir"
    return 1
  fi

  if [[ "$business_use" == "true" ]]; then
    brewfile="$source_dir/homebrew/Brewfile.work"
  else
    brewfile="$source_dir/homebrew/Brewfile"
  fi
  if [[ ! -f "$brewfile" ]]; then
    echo "Brewfile not found: $brewfile" >&2
    rm -rf "$temp_dir"
    return 1
  fi

  if ! command chezmoi \
    --config "$chezmoi_config" \
    --source "$source_dir" \
    execute-template --file "$devbox_template" >"$rendered_manifest"; then
    echo "Could not render the Devbox manifest from the current chezmoi source." >&2
    echo "Run 'chezmoi apply' before brewbundle." >&2
    rm -rf "$temp_dir"
    return 1
  fi
  if ! command jq -e '.packages | type == "array" and all(.[]; type == "string")' "$rendered_manifest" >/dev/null; then
    echo "Rendered source Devbox manifest is invalid: $devbox_template" >&2
    echo "Run 'chezmoi apply' before brewbundle." >&2
    rm -rf "$temp_dir"
    return 1
  fi
  if [[ ! -f "$devbox_manifest" ]]; then
    echo "Rendered Devbox manifest not found: $devbox_manifest" >&2
    echo "Run 'chezmoi apply' before brewbundle." >&2
    rm -rf "$temp_dir"
    return 1
  fi
  if ! command jq -e '.packages | type == "array" and all(.[]; type == "string")' "$devbox_manifest" >/dev/null; then
    echo "Rendered Devbox manifest is invalid: $devbox_manifest" >&2
    echo "Run 'chezmoi apply' before brewbundle." >&2
    rm -rf "$temp_dir"
    return 1
  fi

  if ! command jq -S -c . "$rendered_manifest" >"$rendered_canonical" ||
    ! command jq -S -c . "$devbox_manifest" >"$active_canonical"; then
    echo "Could not canonicalize Devbox manifests for comparison." >&2
    echo "Run 'chezmoi apply' before brewbundle." >&2
    rm -rf "$temp_dir"
    return 1
  fi
  if ! cmp -s "$rendered_canonical" "$active_canonical"; then
    echo "Active Devbox manifest differs from the current chezmoi source/profile." >&2
    echo "Run 'chezmoi apply' before brewbundle." >&2
    rm -rf "$temp_dir"
    return 1
  fi

  if ! command brew bundle dump --force --file="$dumped_brewfile"; then
    rm -rf "$temp_dir"
    return 1
  fi

  if ! sed -nE \
    -e 's/^[[:space:]]*(brew|cargo|npm|uv) "([^"]+)".*/\2/p' \
    -e 's/^[[:space:]]*go "([^"]*\/)?([^/"]+)".*/\2/p' \
    "$dumped_brewfile" |
    sed -e 's/^git-delta$/delta/' |
    LC_ALL=C sort -u >"$homebrew_entries"; then
    echo "Could not read CLI package entries from the temporary Brewfile." >&2
    rm -rf "$temp_dir"
    return 1
  fi
  if ! command jq -r '.packages[] | split("@")[0]' "$rendered_manifest" |
    LC_ALL=C sort -u >"$devbox_packages"; then
    echo "Could not read package names from the source-rendered Devbox manifest." >&2
    rm -rf "$temp_dir"
    return 1
  fi
  if ! comm -12 "$homebrew_entries" "$devbox_packages" >"$overlaps"; then
    echo "Could not compare Homebrew and Devbox package names." >&2
    rm -rf "$temp_dir"
    return 1
  fi

  if [[ -s "$overlaps" ]]; then
    echo "Refusing to update $brewfile: Homebrew CLI entries overlap with the rendered Devbox profile:" >&2
    sed 's/^/  - /' "$overlaps" >&2
    echo "Remove the exact-name overlap from Homebrew or Devbox, then retry." >&2
    rm -rf "$temp_dir"
    return 1
  fi

  if ! mv "$dumped_brewfile" "$brewfile"; then
    echo "Could not replace $brewfile." >&2
    rm -rf "$temp_dir"
    return 1
  fi
  rm -rf "$temp_dir"
  echo "Updated: $brewfile"
}
