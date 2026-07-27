#!/usr/bin/env bash
# Verify rendered targets that contain credentials are private.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd "$script_dir/../.." && pwd -P)"

for required_command in chezmoi jq mktemp; do
  command -v "$required_command" >/dev/null 2>&1 || {
    echo "required command not found: $required_command" >&2
    exit 1
  }
done

test_root="$(mktemp -d "${TMPDIR:-/tmp}/dots-secret-target-modes.XXXXXX")"
cleanup() {
  rm -rf -- "$test_root"
}
trap cleanup EXIT

config_file="$test_root/chezmoi.json"
target_state="$test_root/target-state.json"
destination="$test_root/home"
printf '{}\n' >"$config_file"

data='{
  "business_use": false,
  "auto_tmux": false,
  "homebrew_prefix": "/opt/homebrew",
  "npm_token": "sentinel-npm-token",
  "grafana_instance_id": "sentinel-grafana-instance",
  "grafana_api_token": "sentinel-grafana-api-token",
  "grafana_sa_token": "sentinel-grafana-sa-token"
}'

chezmoi \
  --config "$config_file" \
  --config-format json \
  --source "$repo_root" \
  --destination "$destination" \
  --cache "$test_root/cache" \
  --persistent-state "$test_root/state.boltdb" \
  --refresh-externals=never \
  --override-data "$data" \
  dump --format json \
  "$destination/.npmrc" \
  "$destination/.zshrc" \
  "$destination/.config/zsh/modules/telemetry.zsh" >"$target_state"

jq -e '
  .[".npmrc"].type == "file" and
  .[".npmrc"].perm == 384 and
  .[".zshrc"].type == "file" and
  .[".zshrc"].perm == 384 and
  .[".config/zsh/modules/telemetry.zsh"].type == "file" and
  .[".config/zsh/modules/telemetry.zsh"].perm == 384
' "$target_state" >/dev/null

jq -e '
  .[".npmrc"].contents | contains("sentinel-npm-token")
' "$target_state" >/dev/null

jq -e '
  .[".zshrc"].contents |
  contains("sentinel-grafana-instance") and
  contains("sentinel-grafana-api-token") and
  contains("sentinel-grafana-sa-token")
' "$target_state" >/dev/null

jq -e '
  .[".config/zsh/modules/telemetry.zsh"].contents |
  contains("sentinel-grafana-instance") and
  contains("sentinel-grafana-api-token") and
  contains("sentinel-grafana-sa-token")
' "$target_state" >/dev/null

echo "PASS: secret-bearing npm and telemetry targets render with mode 0600"
