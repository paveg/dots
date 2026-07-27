#!/usr/bin/env bash
set -euo pipefail

readonly version="2.70.5"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <bin-dir>" >&2
  exit 2
fi

bin_dir="$1"
platform="$(uname -s)"
architecture="$(uname -m)"

case "$platform:$architecture" in
  Linux:x86_64)
    asset="chezmoi-linux-amd64"
    expected_sha256="da4f1346e3626c68cbe3620abc12134d886733420df92e32edb48d0406c7f9e5"
    ;;
  Darwin:x86_64)
    asset="chezmoi-darwin-amd64"
    expected_sha256="ddc01ecec92eae115a889e71a31c9d4473067429bfdb4e5c9d9d41221aca6b76"
    ;;
  Darwin:arm64)
    asset="chezmoi-darwin-arm64"
    expected_sha256="f6b1be4caf2edec0addfde57a391c1c77ddf32bc2f57c8b594eac483ba30d2a1"
    ;;
  *)
    echo "Unsupported platform: $platform $architecture" >&2
    exit 1
    ;;
esac

mkdir -p "$bin_dir"
tmp_file="$(mktemp "$bin_dir/.chezmoi.XXXXXX")"
trap 'rm -f "$tmp_file"' EXIT

url="https://github.com/twpayne/chezmoi/releases/download/v${version}/${asset}"
curl --fail --silent --show-error --location "$url" --output "$tmp_file"

if command -v sha256sum >/dev/null 2>&1; then
  actual_sha256="$(sha256sum "$tmp_file")"
elif command -v shasum >/dev/null 2>&1; then
  actual_sha256="$(shasum -a 256 "$tmp_file")"
else
  echo "No SHA-256 tool found (sha256sum or shasum required)" >&2
  exit 1
fi
actual_sha256="${actual_sha256%% *}"

if [[ "$actual_sha256" != "$expected_sha256" ]]; then
  echo "SHA-256 mismatch for $asset" >&2
  echo "expected: $expected_sha256" >&2
  echo "actual:   $actual_sha256" >&2
  exit 1
fi

chmod 0755 "$tmp_file"
mv -f "$tmp_file" "$bin_dir/chezmoi"
trap - EXIT

echo "Installed chezmoi v$version to $bin_dir/chezmoi"
