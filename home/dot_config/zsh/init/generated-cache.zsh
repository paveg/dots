# generated-cache.zsh — validate and atomically publish generated zsh caches
# Provides:     _zsh_cache_prepare
# Requires:     mktemp, chmod, cat, mv, zsh
# Side-effects: create or refresh the requested cache
# Load-order:   BEFORE every generated-cache consumer

# Prepare TARGET for the caller to source.
#
# Usage:
#   _zsh_cache_prepare TARGET REFRESH FINGERPRINT GENERATOR [ARG...]
#
# A warm cache hit only reads the two metadata lines with zsh builtins. Cache
# generation and syntax validation run only for a miss or explicit refresh.
_zsh_cache_prepare() {
  emulate -L zsh
  setopt local_options pipe_fail

  local target="$1"
  local refresh="$2"
  local fingerprint="$3"
  shift 3

  local marker="# dots-generated-zsh-cache-v1"
  local fingerprint_line="# fingerprint: $fingerprint"
  local target_dir="${target:h}"
  local payload_tmp=""
  local publish_tmp=""
  local first_line=""
  local second_line=""
  local old_cache_valid=0
  local failure_reason=""

  if (( $# == 0 )); then
    print -u2 -r -- "warning: generated cache has no generator: $target"
    return 1
  fi
  if [[ -z "$target" || -z "$fingerprint" || "$fingerprint" == *$'\n'* ]]; then
    print -u2 -r -- "warning: generated cache has invalid metadata: $target"
    return 1
  fi
  if [[ -L "$target" ]]; then
    print -u2 -r -- "warning: generated cache target is a symlink: $target"
    return 1
  fi
  if [[ -e "$target" && ! -f "$target" ]]; then
    print -u2 -r -- "warning: generated cache target is not a regular file: $target"
    return 1
  fi

  if [[ -s "$target" ]]; then
    {
      IFS= read -r first_line
      IFS= read -r second_line
    } <"$target"
    if [[ "$first_line" == "$marker" && "$second_line" == "$fingerprint_line" ]]; then
      old_cache_valid=1
      if [[ "$refresh" != "1" ]]; then
        return 0
      fi
    fi
  fi

  if ! command mkdir -p -- "$target_dir"; then
    print -u2 -r -- "warning: generated cache directory could not be created: $target"
    (( old_cache_valid )) && return 0
    return 1
  fi

  local generation_status=1
  {
    if ! payload_tmp="$(command mktemp "${target}.payload.XXXXXXXX")"; then
      failure_reason="could not create payload temp file"
    elif ! publish_tmp="$(command mktemp "${target}.publish.XXXXXXXX")"; then
      failure_reason="could not create publish temp file"
    elif ! "$@" >"$payload_tmp"; then
      failure_reason="generator failed"
    elif [[ ! -s "$payload_tmp" ]]; then
      failure_reason="generator produced empty output"
    elif ! command zsh -f -n "$payload_tmp"; then
      failure_reason="generator produced invalid zsh"
    elif ! {
      print -r -- "$marker"
      print -r -- "$fingerprint_line"
      command cat -- "$payload_tmp"
    } >"$publish_tmp"; then
      failure_reason="validated cache could not be assembled"
    elif ! command zsh -f -n "$publish_tmp"; then
      failure_reason="assembled cache is invalid zsh"
    elif ! command chmod 600 "$publish_tmp"; then
      failure_reason="cache mode could not be restricted"
    elif [[ -L "$target" || ( -e "$target" && ! -f "$target" ) ]]; then
      failure_reason="target changed to a non-regular file"
    elif ! command mv -f -- "$publish_tmp" "$target"; then
      failure_reason="validated cache could not be published"
    else
      publish_tmp=""
      generation_status=0
    fi
  } always {
    [[ -z "$payload_tmp" ]] || command rm -f -- "$payload_tmp"
    [[ -z "$publish_tmp" ]] || command rm -f -- "$publish_tmp"
  }

  if (( generation_status != 0 )); then
    print -u2 -r -- "warning: generated cache refresh failed ($failure_reason): $target"
    (( old_cache_valid )) && return 0
    return 1
  fi
  return 0
}
