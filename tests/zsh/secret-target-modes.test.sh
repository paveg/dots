#!/usr/bin/env bash
# Verify that no rendered target carries a credential, and that the two files which
# historically did are still mode 0600.
#
# This began as the inverse: it asserted sentinel tokens reached the npm and telemetry
# targets. Both credentials are gone — telemetry moved to obs-01, which authenticates no
# one, and the npm token expired and had its 1Password item deleted. What is worth a test
# now is that neither comes back into a file every shell reads.
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
  "homebrew_prefix": "/opt/homebrew"
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
  .[".npmrc"].contents | (contains("_authToken") | not)
' "$target_state" >/dev/null

# Inverted on purpose. Telemetry used to carry a Grafana Cloud token and this asserted the
# token reached the rendered file; it now goes to obs-01, which authenticates no one, so the
# same test earns its keep as a guard that no credential comes back into a file whose whole
# job is to be sourced by every shell.
jq -e '
  .[".zshrc"].contents |
  (contains("Authorization") | not) and
  (contains("OTEL_EXPORTER_OTLP_HEADERS") | not)
' "$target_state" >/dev/null

jq -e '
  .[".config/zsh/modules/telemetry.zsh"].contents |
  (contains("Authorization") | not) and
  (contains("OTEL_EXPORTER_OTLP_HEADERS") | not) and
  contains("192.168.10.60")
' "$target_state" >/dev/null

echo "PASS: npm and telemetry targets render 0600 and carry no credential"
