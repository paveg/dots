#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
template="$repo_root/home/dot_local/share/devbox/global/default/devbox.json.tmpl"
requested_output_root="${1:-}"
scratch_dir=$(mktemp -d)
trap 'rm -rf "$scratch_dir"' EXIT

if [[ -n "$requested_output_root" ]]; then
  output_root="$requested_output_root"
else
  output_root="$scratch_dir/rendered"
fi

for command_name in chezmoi jq; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Required command not found: $command_name" >&2
    exit 1
  fi
done

mkdir -p \
  "$scratch_dir/home" \
  "$scratch_dir/cache" \
  "$scratch_dir/config" \
  "$scratch_dir/data" \
  "$scratch_dir/state" \
  "$output_root"
printf '{}\n' >"$scratch_dir/chezmoi.json"

render_profile() {
  local profile="$1"
  local business_use="$2"
  local output_dir="$output_root/$profile"
  local output="$output_dir/devbox.json"

  mkdir -p "$output_dir"
  env \
    -u BUSINESS_USE \
    HOME="$scratch_dir/home" \
    XDG_CACHE_HOME="$scratch_dir/cache" \
    XDG_CONFIG_HOME="$scratch_dir/config" \
    XDG_DATA_HOME="$scratch_dir/data" \
    XDG_STATE_HOME="$scratch_dir/state" \
    chezmoi \
    --config "$scratch_dir/chezmoi.json" \
    --config-format json \
    --source "$repo_root" \
    --override-data "{\"business_use\":$business_use}" \
    execute-template --file "$template" >"$output"

  jq -e . "$output" >/dev/null
}

render_profile personal false
render_profile business true

personal_manifest="$output_root/personal/devbox.json"
business_manifest="$output_root/business/devbox.json"

for manifest in "$personal_manifest" "$business_manifest"; do
  jq -e '.packages | type == "array" and all(.[]; type == "string")' "$manifest" >/dev/null
done

cat >"$scratch_dir/expected-personal-only" <<'EOF'
gitleaks@latest
protobuf@latest
protoc-gen-go@latest
cloudflared@latest
flyctl@latest
grpcurl@latest
gibo@latest
lazydocker@latest
mcp-proxy@latest
navi@latest
ncdu@latest
hyperfine@latest
vhs@latest
yamllint@latest
EOF

cat >"$scratch_dir/expected-business-only" <<'EOF'
aws-sso-util@latest
colima@latest
docker-client@latest
docker-compose@latest
docker-credential-helpers@latest
dive@latest
EOF

LC_ALL=C sort -u "$scratch_dir/expected-personal-only" -o "$scratch_dir/expected-personal-only"
LC_ALL=C sort -u "$scratch_dir/expected-business-only" -o "$scratch_dir/expected-business-only"

jq -n -r \
  --slurpfile personal "$personal_manifest" \
  --slurpfile business "$business_manifest" \
  '$personal[0].packages - $business[0].packages | sort | .[]' \
  >"$scratch_dir/actual-personal-only"
jq -n -r \
  --slurpfile personal "$personal_manifest" \
  --slurpfile business "$business_manifest" \
  '$business[0].packages - $personal[0].packages | sort | .[]' \
  >"$scratch_dir/actual-business-only"

if ! diff -u "$scratch_dir/expected-personal-only" "$scratch_dir/actual-personal-only"; then
  echo "Personal-only Devbox package set does not match the profile contract." >&2
  exit 1
fi
if ! diff -u "$scratch_dir/expected-business-only" "$scratch_dir/actual-business-only"; then
  echo "Business-only Devbox package set does not match the profile contract." >&2
  exit 1
fi

echo "Validated rendered Devbox manifests for personal and business profiles."
