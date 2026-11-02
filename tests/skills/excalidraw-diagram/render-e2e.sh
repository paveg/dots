#!/usr/bin/env bash
# Opt-in end-to-end check of the excalidraw-diagram renderer. Needs Google
# Chrome and a built renderer (pnpm install --frozen-lockfile && node build.mjs
# in ~/.claude/skills/excalidraw-diagram/renderer, or in the source copy).
set -uo pipefail
cd "$(dirname "$0")" || exit 1
RENDER="${EXCALIDRAW_RENDER:-$(cd ../../.. && pwd)/home/dot_claude/skills/excalidraw-diagram/renderer/render.mjs}"

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

fail=0
check() {
  if [[ $2 != "$3" ]]; then
    fail=1
    echo "FAIL: $1 (expected: $2, actual: $3)" >&2
  fi
}

stdout=$(node "$RENDER" fixtures/minimal.excalidraw --output "$workdir/minimal.png" 2>"$workdir/minimal.err")
check "minimal fixture exits 0" 0 $?
check "minimal fixture prints the PNG path" "$workdir/minimal.png" "$stdout"
check "minimal fixture writes a PNG" "89504e47" "$(head -c 4 "$workdir/minimal.png" | od -An -tx1 | tr -d ' \n')"

node "$RENDER" fixtures/outbound-request.excalidraw --output "$workdir/outbound.png" >/dev/null 2>"$workdir/outbound.err"
check "outbound request exits 1" 1 $?
check "outbound request is reported" 1 "$(grep -c 'https://example.invalid/pixel.png' "$workdir/outbound.err")"
check "outbound request writes nothing" "no" "$([[ -e $workdir/outbound.png ]] && echo yes || echo no)"

if ((fail == 0)); then
  echo "✓ excalidraw render checks passed"
fi
exit "$fail"
