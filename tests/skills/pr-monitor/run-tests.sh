#!/usr/bin/env bash
# Tests for home/dot_claude/skills/pr-monitor/scripts/pr-monitor.sh
#
# Stubs `gh` via PATH; the stub serves staged JSON fixtures (one per poll,
# clamped at the last) so the loop can be driven through state transitions
# without network access.
set -uo pipefail
cd "$(dirname "$0")"
SCRIPT="$(cd ../../.. && pwd)/home/dot_claude/skills/pr-monitor/scripts/pr-monitor.sh"

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT
mkdir -p "$workdir/bin"

cat > "$workdir/bin/gh" <<'FAKE'
#!/usr/bin/env bash
case "$1" in
  pr)  prefix=pr ;;
  api) prefix=th ;;
  *)   exit 1 ;;
esac
n=$(cat "$FIXDIR/$prefix.count" 2>/dev/null || echo 0)
n=$((n + 1))
echo "$n" > "$FIXDIR/$prefix.count"
last=$(find "$FIXDIR" -name "$prefix-*.json" | wc -l | tr -d ' ')
(( n > last )) && n=$last
cat "$FIXDIR/$prefix-$n.json"
FAKE
chmod +x "$workdir/bin/gh"
export PATH="$workdir/bin:$PATH"
export PR_MONITOR_INTERVAL=0
export PR_MONITOR_MAX_POLLS=20

fail=0
expect() { # expect <label> <needle> <haystack>
  if grep -qF -- "$2" <<<"$3"; then
    echo "  ok   $1"
  else
    echo "  FAIL $1 — expected to find: $2"
    echo "$3" | sed 's/^/       /'
    fail=1
  fi
}
expect_count() { # expect_count <label> <n> <pattern> <haystack>
  local got
  got=$(grep -c -- "$3" <<<"$4")
  if [[ $got == "$2" ]]; then
    echo "  ok   $1"
  else
    echo "  FAIL $1 — expected $2 lines matching '$3', got $got"
    echo "$4" | sed 's/^/       /'
    fail=1
  fi
}

# --- scenario 1: until=green — transitions, exclusion, failure coverage, DONE
export FIXDIR="$workdir/fix1"
mkdir -p "$FIXDIR"
# polls 1-2: one pending CheckRun, one success, one pending StatusContext,
# plus an excluded approval gate (must not count toward total)
cat > "$FIXDIR/pr-1.json" <<'J'
{"state":"OPEN","statusCheckRollup":[
  {"name":"test","status":"IN_PROGRESS","conclusion":""},
  {"name":"lint","status":"COMPLETED","conclusion":"SUCCESS"},
  {"context":"ci/build","state":"PENDING"},
  {"name":"require-approval","status":"IN_PROGRESS","conclusion":""}]}
J
cp "$FIXDIR/pr-1.json" "$FIXDIR/pr-2.json"
# poll 3: CANCELLED must be classified as a failure (not only FAILURE)
cat > "$FIXDIR/pr-3.json" <<'J'
{"state":"OPEN","statusCheckRollup":[
  {"name":"test","status":"COMPLETED","conclusion":"CANCELLED"},
  {"name":"lint","status":"COMPLETED","conclusion":"SUCCESS"},
  {"context":"ci/build","state":"SUCCESS"},
  {"name":"require-approval","status":"IN_PROGRESS","conclusion":""}]}
J
# poll 4: all green
cat > "$FIXDIR/pr-4.json" <<'J'
{"state":"OPEN","statusCheckRollup":[
  {"name":"test","status":"COMPLETED","conclusion":"SUCCESS"},
  {"name":"lint","status":"COMPLETED","conclusion":"SUCCESS"},
  {"context":"ci/build","state":"SUCCESS"},
  {"name":"require-approval","status":"IN_PROGRESS","conclusion":""}]}
J
# threads: one unresolved until poll 4
cat > "$FIXDIR/th-1.json" <<'J'
{"data":{"repository":{"pullRequest":{"reviewThreads":{"nodes":[{"isResolved":false}]}}}}}
J
cp "$FIXDIR/th-1.json" "$FIXDIR/th-2.json"
cp "$FIXDIR/th-1.json" "$FIXDIR/th-3.json"
cat > "$FIXDIR/th-4.json" <<'J'
{"data":{"repository":{"pullRequest":{"reviewThreads":{"nodes":[{"isResolved":true}]}}}}}
J

out=$(bash "$SCRIPT" 1 owner repo 2>&1)
rc=$?
if [[ $rc -eq 0 ]]; then echo "  ok   green: exits 0"; else echo "  FAIL green: exit code $rc"; fail=1; fi
expect_count "green: emits only on change"    3 '^CI ' "$out"
expect       "green: excluded check dropped"  '"total":3' "$out"
expect       "green: pending counted"         '"pending":2' "$out"
expect       "green: CANCELLED is a failure"  '"failures":["test"]' "$out"
expect       "green: unresolved thread seen"  '"unresolved":1' "$out"
expect       "green: DONE line"               "DONE: all checks green and threads resolved" "$out"

# --- scenario 2: until=merged — keeps watching past green, exits on MERGED
export FIXDIR="$workdir/fix2"
mkdir -p "$FIXDIR"
cat > "$FIXDIR/pr-1.json" <<'J'
{"state":"OPEN","statusCheckRollup":[{"name":"test","status":"COMPLETED","conclusion":"SUCCESS"}]}
J
cat > "$FIXDIR/pr-2.json" <<'J'
{"state":"MERGED","statusCheckRollup":[{"name":"test","status":"COMPLETED","conclusion":"SUCCESS"}]}
J
cat > "$FIXDIR/th-1.json" <<'J'
{"data":{"repository":{"pullRequest":{"reviewThreads":{"nodes":[]}}}}}
J

out=$(bash "$SCRIPT" 1 owner repo "require-approval,check-approval" merged 2>&1)
rc=$?
[[ $rc -eq 0 ]] || { echo "  FAIL merged: exit code $rc"; fail=1; }
expect "merged: survives green state"  '| PR OPEN' "$out"
expect "merged: DONE on merge"         "DONE: merged" "$out"

echo
if [[ $fail -eq 0 ]]; then echo "passed"; else echo "FAILED"; fi
exit "$fail"
