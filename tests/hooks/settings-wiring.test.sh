#!/usr/bin/env bash
# Render both Claude settings profiles and verify local hook wiring.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd "$script_dir/../.." && pwd -P)"
settings_source="$repo_root/home/dot_claude/settings.json.tmpl"
mcp_source="$repo_root/home/dot_claude/mcp-servers.json.tmpl"
sync_source="$repo_root/home/.chezmoiscripts/run_onchange_after_sync-mcp-servers.sh.tmpl"
credential_command="\$HOME/.claude/hooks/block-credential-read.sh"

for command in chezmoi jq; do
  command -v "$command" >/dev/null 2>&1 || {
    echo "required command not found: $command" >&2
    exit 1
  }
done

test_root="$(mktemp -d "${TMPDIR:-/tmp}/dots-settings-wiring.XXXXXX")"
cleanup() {
  rm -rf -- "$test_root"
}
trap cleanup EXIT

export HOME="$test_root/home"
export XDG_CONFIG_HOME="$test_root/config"
export XDG_CACHE_HOME="$test_root/cache"
export XDG_DATA_HOME="$test_root/data"
export XDG_STATE_HOME="$test_root/state"
mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME"

chezmoi_config="$test_root/chezmoi.json"
printf '{}\n' >"$chezmoi_config"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

render_profile() {
  local profile="$1"
  local business_use="$2"
  local rendered="$test_root/settings-$profile.json"

  chezmoi \
    --config "$chezmoi_config" \
    --config-format json \
    --source "$repo_root" \
    --override-data "{\"business_use\":$business_use}" \
    execute-template --file "$settings_source" >"$rendered"

  jq empty "$rendered" || fail "$profile settings are not valid JSON"
  printf '%s\n' "$rendered"
}

render_mcp_profile() {
  local profile="$1"
  local business_use="$2"
  local rendered="$test_root/mcp-servers-$profile.json"

  chezmoi \
    --config "$chezmoi_config" \
    --config-format json \
    --source "$repo_root" \
    --override-data "{\"business_use\":$business_use}" \
    execute-template --file "$mcp_source" >"$rendered"

  jq empty "$rendered" || fail "$profile mcp-servers.json is not valid JSON"
  printf '%s\n' "$rendered"
}

assert_profile_wiring() {
  local profile="$1"
  local rendered="$2"
  local business_use="$3"
  local bash_matchers
  local credential_count
  local credential_hook
  local target
  local expected_source
  local actual_source

  bash_matchers="$(
    jq '[.hooks.PreToolUse[] | select(.matcher == "Bash")] | length' "$rendered"
  )"
  [[ "$bash_matchers" == "1" ]] ||
    fail "$profile settings contain $bash_matchers Bash matchers, expected 1"

  credential_count="$(
    jq --arg command "$credential_command" \
      '[.. | objects | select(.command? == $command)] | length' "$rendered"
  )"
  [[ "$credential_count" == "1" ]] ||
    fail "$profile settings contain credential hook $credential_count times, expected 1"

  while IFS= read -r target; do
    [[ -n "$target" ]] || fail "$profile settings contain an empty local hook target"
    expected_source="$repo_root/home/dot_claude/hooks/executable_$target"
    [[ -f "$expected_source" ]] ||
      fail "$profile hook has no managed source: $target"

    actual_source="$(
      chezmoi \
        --config "$chezmoi_config" \
        --config-format json \
        --source "$repo_root" \
        --override-data "{\"business_use\":$business_use}" \
        source-path "$HOME/.claude/hooks/$target"
    )"
    [[ "$actual_source" == "$expected_source" ]] ||
      fail "$profile hook maps to $actual_source, expected $expected_source"
  done < <(
    jq -r '
      .. | objects | .command? // empty
      | capture("\\$HOME/\\.claude/hooks/(?<target>[^[:space:]]+)").target?
      // empty
    ' "$rendered"
  )

  credential_hook="$(
    jq -r --arg command "$credential_command" '
      .hooks.PreToolUse[]
      | select(.matcher == "Bash")
      | .hooks[]
      | select(.command == $command)
      | .command
    ' "$rendered"
  )"
  target="${credential_hook##*/}"
  expected_source="$repo_root/home/dot_claude/hooks/executable_$target"

  deny_output="$(
    printf '%s' \
      '{"tool_name":"Bash","tool_input":{"command":"cat ~/.aws/credentials"}}' |
      bash "$expected_source"
  )"
  jq -e '.hookSpecificOutput.permissionDecision == "deny"' \
    <<<"$deny_output" >/dev/null ||
    fail "$profile configured credential hook did not deny a credential read"

  allow_output="$(
    printf '%s' \
      '{"tool_name":"Bash","tool_input":{"command":"cat README.md"}}' |
      bash "$expected_source"
  )"
  [[ -z "$allow_output" ]] ||
    fail "$profile configured credential hook emitted a decision for a benign command"

  local mcp_rendered
  mcp_rendered="$(render_mcp_profile "$profile" "$business_use")"

  jq -e 'has("mcpServers") | not' "$rendered" >/dev/null ||
    fail "$profile settings.json contains mcpServers (not a supported source)"

  if [[ "$business_use" == "true" ]]; then
    jq -e '
      (.mcpServers | keys) == [
        "fdev-argocd-production", "fdev-argocd-staging", "fdev-aws",
        "fdev-aws-doc", "fdev-datadog", "fdev-helmfile",
        "fdev-kubernetes", "fdev-slack", "fdev-terraform"
      ]
      and ([.mcpServers[].command] | all(. == "fdev-mcp-server"))
      and (.mcpServers["fdev-helmfile"]["env"]["AQUA_GLOBAL_CONFIG"]
        | endswith("/.config/aquaproj-aqua/aqua.yaml"))
      and (.mcpServers["fdev-helmfile"]["env"]["HELM_BIN"]
        | endswith("/.local/share/aquaproj-aqua/bin/helm"))
      and (.mcpServers["fdev-helmfile"]["env"]["HELMFILE_COMMAND"]
        | endswith("/.local/share/aquaproj-aqua/bin/helmfile"))
      and (.mcpServers["fdev-terraform"]["env"]["AQUA_GLOBAL_CONFIG"]
        | endswith("/.config/aquaproj-aqua/aqua.yaml"))
      and (.mcpServers["fdev-terraform"]["env"]["TERRAFORM_COMMAND"]
        | endswith("/.local/share/aquaproj-aqua/bin/terraform"))
      and (.mcpServers["fdev-aws"]["env"]["UV_CONSTRAINT"]
        | endswith("/.config/fdev-mcp/uv-constraints.txt"))
      and (.mcpServers["fdev-aws"]["env"]["SSL_CERT_FILE"]
        | endswith("/.config/fdev-mcp/ca-bundle.crt"))
    ' "$mcp_rendered" >/dev/null ||
      fail "$profile mcp-servers.json does not match the expected fdev server set"
  else
    jq -e '
      (.mcpServers | keys) == ["1password", "textlint"]
    ' "$mcp_rendered" >/dev/null ||
      fail "$profile mcp-servers.json contains unexpected MCP servers"
  fi
}

for profile in personal business; do
  case "$profile" in
    personal)
      business_use=false
      ;;
    business)
      business_use=true
      ;;
  esac

  rendered="$(render_profile "$profile" "$business_use")"
  assert_profile_wiring "$profile" "$rendered" "$business_use"
  echo "profile wiring OK: $profile"
done

echo "all assertions passed"

merge_home="$test_root/merge-home"
mkdir -p "$merge_home/.claude"
printf '%s\n' \
  '{"mcpServers": {"alpha": {"command": "a"}, "beta": {"command": "b"}}}' \
  >"$merge_home/.claude/mcp-servers.json"
printf '%s\n' \
  '{"other": true, "mcpServers": {"manual": {"command": "m"}, "stale": {"command": "s"}, "alpha": {"command": "old"}}}' \
  >"$merge_home/.claude.json"
printf '["stale", "alpha"]\n' >"$merge_home/.claude/mcp-servers.state.json"

sync_rendered="$test_root/sync-mcp-servers.sh"
chezmoi \
  --config "$chezmoi_config" \
  --config-format json \
  --source "$repo_root" \
  --override-data '{"business_use":true}' \
  execute-template --file "$sync_source" >"$sync_rendered"

HOME="$merge_home" bash "$sync_rendered" >/dev/null || fail "mcp sync script failed"

jq -e '
  (.mcpServers | keys) == ["alpha", "beta", "manual"]
  and .mcpServers.alpha.command == "a"
  and .other == true
' "$merge_home/.claude.json" >/dev/null ||
  fail "mcp sync script produced a wrong merge result"
