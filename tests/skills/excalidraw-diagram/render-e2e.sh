#!/usr/bin/env bash
# End-to-end check of the excalidraw-diagram renderer; needs Chrome and a built renderer.
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

node "$RENDER" fixtures/minimal.excalidraw --output "$workdir/missing-dir/x.png" >/dev/null 2>"$workdir/write.err"
check "unwritable output exits 1" 1 $?
check "unwritable output is reported without a stack trace" "1:0" "$(grep -c 'could not write output' "$workdir/write.err"):$(grep -c 'node:internal' "$workdir/write.err")"

node "$RENDER" fixtures/minimal.excalidraw --output "$workdir/kept.png" --svg "$workdir/missing-dir/x.svg" >/dev/null 2>&1
check "unwritable SVG exits 1" 1 $?
check "unwritable SVG leaves no PNG behind" "no" "$([[ -e $workdir/kept.png ]] && echo yes || echo no)"

if ((fail == 0)); then
  echo "✓ excalidraw render checks passed"
fi
exit "$fail"
