#!/usr/bin/env bash
# Tests for home/dot_claude/skills/pr-monitor/scripts/pr-monitor.sh
#
# Stubs `gh` via PATH; the stub serves staged JSON fixtures (one per poll,
# clamped at the last) so the loop can be driven through state transitions
# without network access.
set -uo pipefail
cd "$(dirname "$0")" || exit 1
SCRIPT="$(cd ../../.. && pwd)/home/dot_claude/skills/pr-monitor/scripts/pr-monitor.sh"

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT
mkdir -p "$workdir/bin"

cat >"$workdir/bin/gh" <<'FAKE'
#!/usr/bin/env bash
case "$1" in
  pr)
    n=$(cat "$FIXDIR/pr.count" 2>/dev/null || echo 0)
    n=$((n + 1))
    echo "$n" > "$FIXDIR/pr.count"
    last=$(find "$FIXDIR" -name 'pr-*.json' | wc -l | tr -d ' ')
    ((n > last)) && n=$last
    cat "$FIXDIR/pr-$n.json"
    ;;
  api)
    query=""
    after=""
    previous=""
    for arg in "$@"; do
      case $arg in
        query=*) query=${arg#query=} ;;
        after=*)
          [[ $previous == -f ]] || exit 1
          after=${arg#after=}
          ;;
      esac
      previous=$arg
    done
    [[ $query == *'after:$after'* ]] || exit 1
    [[ $query == *'pageInfo{hasNextPage endCursor}'* ]] || exit 1

    if [[ -z $after ]]; then
      n=$(cat "$FIXDIR/th.count" 2>/dev/null || echo 0)
      n=$((n + 1))
      echo "$n" > "$FIXDIR/th.count"
      page=1
      echo "$page" > "$FIXDIR/th.page"
    else
      n=$(cat "$FIXDIR/th.count")
      page=$(cat "$FIXDIR/th.page")
      previous_fixture="$FIXDIR/th-$n-$page.json"
      expected_after=$(jq -er \
        '.data.repository.pullRequest.reviewThreads.pageInfo.endCursor
         | select(type == "string" and length > 0)' \
        "$previous_fixture") || exit 1
      [[ $after == "$expected_after" ]] || exit 1
      printf '%s\n' "$after" >>"$FIXDIR/after.log"
      page=$((page + 1))
      echo "$page" > "$FIXDIR/th.page"
    fi

    fixture="$FIXDIR/th-$n-$page.json"
    if [[ $page -eq 1 && ! -f $fixture ]]; then
      fixture="$FIXDIR/th-$n.json"
    fi
    cat "$fixture"
    ;;
  *)
    exit 1
    ;;
esac
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
    # shellcheck disable=SC2001 # Prefix every line of multi-line diagnostics.
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
    # shellcheck disable=SC2001 # Prefix every line of multi-line diagnostics.
    echo "$4" | sed 's/^/       /'
    fail=1
  fi
}

# --- scenario 1: until=green — transitions, exclusion, failure coverage, DONE
export FIXDIR="$workdir/fix1"
mkdir -p "$FIXDIR"
# polls 1-2: one pending CheckRun, one success, one pending StatusContext,
# plus an excluded approval gate (must not count toward total)
cat >"$FIXDIR/pr-1.json" <<'J'
{"state":"OPEN","statusCheckRollup":[
  {"name":"test","status":"IN_PROGRESS","conclusion":""},
  {"name":"lint","status":"COMPLETED","conclusion":"SUCCESS"},
  {"context":"ci/build","state":"PENDING"},
  {"name":"require-approval","status":"IN_PROGRESS","conclusion":""}]}
J
cp "$FIXDIR/pr-1.json" "$FIXDIR/pr-2.json"
# poll 3: CANCELLED must be classified as a failure (not only FAILURE)
cat >"$FIXDIR/pr-3.json" <<'J'
{"state":"OPEN","statusCheckRollup":[
  {"name":"test","status":"COMPLETED","conclusion":"CANCELLED"},
  {"name":"lint","status":"COMPLETED","conclusion":"SUCCESS"},
  {"context":"ci/build","state":"SUCCESS"},
  {"name":"require-approval","status":"IN_PROGRESS","conclusion":""}]}
J
# poll 4: all green
cat >"$FIXDIR/pr-4.json" <<'J'
{"state":"OPEN","statusCheckRollup":[
  {"name":"test","status":"COMPLETED","conclusion":"SUCCESS"},
  {"name":"lint","status":"COMPLETED","conclusion":"SUCCESS"},
  {"context":"ci/build","state":"SUCCESS"},
  {"name":"require-approval","status":"IN_PROGRESS","conclusion":""}]}
J
# threads: one unresolved until poll 4
cat >"$FIXDIR/th-1.json" <<'J'
{"data":{"repository":{"pullRequest":{"reviewThreads":{"nodes":[{"isResolved":false}],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
J
cp "$FIXDIR/th-1.json" "$FIXDIR/th-2.json"
cp "$FIXDIR/th-1.json" "$FIXDIR/th-3.json"
cat >"$FIXDIR/th-4.json" <<'J'
{"data":{"repository":{"pullRequest":{"reviewThreads":{"nodes":[{"isResolved":true}],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
J

out=$(bash "$SCRIPT" 1 owner repo 2>&1)
rc=$?
if [[ $rc -eq 0 ]]; then echo "  ok   green: exits 0"; else
  echo "  FAIL green: exit code $rc"
  fail=1
fi
expect_count "green: emits only on change" 3 '^CI ' "$out"
expect "green: excluded check dropped" '"total":3' "$out"
expect "green: pending counted" '"pending":2' "$out"
expect "green: CANCELLED is a failure" '"failures":["test"]' "$out"
expect "green: unresolved thread seen" '"unresolved":1' "$out"
expect "green: DONE line" "DONE: all checks green and threads resolved" "$out"

# --- scenario 2: until=merged — keeps watching past green, exits on MERGED
export FIXDIR="$workdir/fix2"
mkdir -p "$FIXDIR"
cat >"$FIXDIR/pr-1.json" <<'J'
{"state":"OPEN","statusCheckRollup":[{"name":"test","status":"COMPLETED","conclusion":"SUCCESS"}]}
J
cat >"$FIXDIR/pr-2.json" <<'J'
{"state":"MERGED","statusCheckRollup":[{"name":"test","status":"COMPLETED","conclusion":"SUCCESS"}]}
J
cat >"$FIXDIR/th-1.json" <<'J'
{"data":{"repository":{"pullRequest":{"reviewThreads":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
J
cp "$FIXDIR/th-1.json" "$FIXDIR/th-2.json"

out=$(bash "$SCRIPT" 1 owner repo "require-approval,check-approval" merged 2>&1)
rc=$?
[[ $rc -eq 0 ]] || {
  echo "  FAIL merged: exit code $rc"
  fail=1
}
expect "merged: survives green state" '| PR OPEN' "$out"
expect "merged: DONE on merge" "DONE: merged" "$out"

# --- scenario 3: paginates review threads past the first 100
export FIXDIR="$workdir/fix3"
mkdir -p "$FIXDIR"
cat >"$FIXDIR/pr-1.json" <<'J'
{"state":"OPEN","statusCheckRollup":[{"name":"test","status":"COMPLETED","conclusion":"SUCCESS"}]}
J
cp "$FIXDIR/pr-1.json" "$FIXDIR/pr-2.json"

jq -cn '{
  data: {repository: {pullRequest: {reviewThreads: {
    nodes: [range(100) | {isResolved: true}],
    pageInfo: {hasNextPage: true, endCursor: "@opaque-cursor"}
  }}}}
}' >"$FIXDIR/th-1-1.json"
cat >"$FIXDIR/th-1-2.json" <<'J'
{"data":{"repository":{"pullRequest":{"reviewThreads":{"nodes":[{"isResolved":false}],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
J
jq -cn '{
  data: {repository: {pullRequest: {reviewThreads: {
    nodes: [range(100) | {isResolved: true}],
    pageInfo: {hasNextPage: true, endCursor: "cursor-2"}
  }}}}
}' >"$FIXDIR/th-2-1.json"
cat >"$FIXDIR/th-2-2.json" <<'J'
{"data":{"repository":{"pullRequest":{"reviewThreads":{"nodes":[{"isResolved":true}],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
J

out=$(bash "$SCRIPT" 1 owner repo 2>&1)
rc=$?
[[ $rc -eq 0 ]] || {
  echo "  FAIL pagination: exit code $rc"
  fail=1
}
expect "pagination: counts page 2" '"total":101' "$out"
expect "pagination: sees thread 101" '"unresolved":1' "$out"
expect "pagination: waits for resolution" "DONE: all checks green and threads resolved" "$out"
expect "pagination: forwards @ cursor literally" "@opaque-cursor" "$(cat "$FIXDIR/after.log")"
expect "pagination: forwards refreshed endCursor" "cursor-2" "$(cat "$FIXDIR/after.log")"

# --- scenario 4: a later-page failure cannot become fake green
export FIXDIR="$workdir/fix4"
mkdir -p "$FIXDIR"
cp "$workdir/fix3/pr-1.json" "$FIXDIR/pr-1.json"
jq -cn '{
  data: {repository: {pullRequest: {reviewThreads: {
    nodes: [range(100) | {isResolved: true}],
    pageInfo: {hasNextPage: true, endCursor: "missing-page"}
  }}}}
}' >"$FIXDIR/th-1-1.json"

export PR_MONITOR_MAX_POLLS=1
out=$(bash "$SCRIPT" 1 owner repo 2>&1)
rc=$?
[[ $rc -eq 1 ]] || {
  echo "  FAIL page failure: exit code $rc"
  fail=1
}
expect "page failure: times out" "[TIMEOUT] max polls reached" "$out"
expect_count "page failure: never reports DONE" 0 '^DONE:' "$out"

# --- scenario 5: repeated cursors fail instead of looping forever
export FIXDIR="$workdir/fix5"
mkdir -p "$FIXDIR"
cp "$workdir/fix3/pr-1.json" "$FIXDIR/pr-1.json"
cat >"$FIXDIR/th-1-1.json" <<'J'
{"data":{"repository":{"pullRequest":{"reviewThreads":{"nodes":[],"pageInfo":{"hasNextPage":true,"endCursor":"repeat"}}}}}}
J
cp "$FIXDIR/th-1-1.json" "$FIXDIR/th-1-2.json"

out=$(bash "$SCRIPT" 1 owner repo 2>&1)
rc=$?
[[ $rc -eq 1 ]] || {
  echo "  FAIL cursor cycle: exit code $rc"
  fail=1
}
expect "cursor cycle: times out" "[TIMEOUT] max polls reached" "$out"
expect_count "cursor cycle: never reports DONE" 0 '^DONE:' "$out"

# --- scenario 6: GraphQL partial data with errors cannot become fake green
export FIXDIR="$workdir/fix6"
mkdir -p "$FIXDIR"
cp "$workdir/fix3/pr-1.json" "$FIXDIR/pr-1.json"
cat >"$FIXDIR/th-1.json" <<'J'
{"errors":[{"message":"partial failure"}],"data":{"repository":{"pullRequest":{"reviewThreads":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
J

out=$(bash "$SCRIPT" 1 owner repo 2>&1)
rc=$?
[[ $rc -eq 1 ]] || {
  echo "  FAIL GraphQL errors: exit code $rc"
  fail=1
}
expect "GraphQL errors: times out" "[TIMEOUT] max polls reached" "$out"
expect_count "GraphQL errors: never reports DONE" 0 '^DONE:' "$out"

# --- scenario 7: malformed errors fields cannot masquerade as no errors
malformed_index=0
for malformed_errors in '{}' '""'; do
  malformed_index=$((malformed_index + 1))
  export FIXDIR="$workdir/fix7-$malformed_index"
  mkdir -p "$FIXDIR"
  cp "$workdir/fix3/pr-1.json" "$FIXDIR/pr-1.json"
  jq -cn --argjson errors "$malformed_errors" '{
    errors: $errors,
    data: {repository: {pullRequest: {reviewThreads: {
      nodes: [],
      pageInfo: {hasNextPage: false, endCursor: null}
    }}}}
  }' >"$FIXDIR/th-1.json"

  out=$(bash "$SCRIPT" 1 owner repo 2>&1)
  rc=$?
  [[ $rc -eq 1 ]] || {
    echo "  FAIL malformed errors $malformed_index: exit code $rc"
    fail=1
  }
  expect "malformed errors $malformed_index: times out" "[TIMEOUT] max polls reached" "$out"
  expect_count "malformed errors $malformed_index: never reports DONE" 0 '^DONE:' "$out"
done

# --- scenario 8: unique cursors cannot make one poll fetch forever
export FIXDIR="$workdir/fix8"
mkdir -p "$FIXDIR"
cp "$workdir/fix3/pr-1.json" "$FIXDIR/pr-1.json"
for page in {1..100}; do
  jq -cn --arg cursor "unique-$page" '{
    data: {repository: {pullRequest: {reviewThreads: {
      nodes: [],
      pageInfo: {hasNextPage: true, endCursor: $cursor}
    }}}}
  }' >"$FIXDIR/th-1-$page.json"
done

out=$(bash "$SCRIPT" 1 owner repo 2>&1)
rc=$?
[[ $rc -eq 1 ]] || {
  echo "  FAIL page limit: exit code $rc"
  fail=1
}
expect "page limit: times out" "[TIMEOUT] max polls reached" "$out"
expect "page limit: stops at 100 requests" "100" "$(cat "$FIXDIR/th.page")"
expect_count "page limit: never reports DONE" 0 '^DONE:' "$out"
export PR_MONITOR_MAX_POLLS=20

echo
if [[ $fail -eq 0 ]]; then echo "passed"; else echo "FAILED"; fi
exit "$fail"
