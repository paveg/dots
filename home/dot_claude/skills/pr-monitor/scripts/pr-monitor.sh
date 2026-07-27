#!/usr/bin/env bash
# Poll a GitHub PR's CI checks and review threads; emit one line per state change.
#
# Usage: pr-monitor.sh <pr> <owner> <repo> [excluded-csv] [until]
#   excluded-csv  check names to ignore (default: require-approval,check-approval)
#   until         green  → exit DONE when checks pass and threads resolve (default)
#                 merged → keep watching; exit only on MERGED / CLOSED
#
# Env overrides: PR_MONITOR_INTERVAL (seconds, default 30),
#                PR_MONITOR_MAX_POLLS (0 = unlimited, default 0)
#
# Transient fetch failures keep the last known state instead of substituting
# empty JSON — fake "all green" data would satisfy the termination predicate
# and fire DONE prematurely on a flaky network.
set -uo pipefail

PR=$1
OWNER=$2
REPO=$3
EXCLUDED=${4:-require-approval,check-approval}
UNTIL=${5:-green}
INTERVAL=${PR_MONITOR_INTERVAL:-30}
MAX_POLLS=${PR_MONITOR_MAX_POLLS:-0}

THREADS_QUERY='query($o:String!,$r:String!,$n:Int!){repository(owner:$o,name:$r){pullRequest(number:$n){reviewThreads(first:100){nodes{isResolved}}}}}'

last_state=""
polls=0
errors=0

while true; do
  polls=$((polls + 1))
  if (( MAX_POLLS > 0 && polls > MAX_POLLS )); then
    echo "[TIMEOUT] max polls reached"
    exit 1
  fi

  if pr_json=$(gh pr view "$PR" --repo "$OWNER/$REPO" --json state,statusCheckRollup 2>/dev/null) &&
     th_json=$(gh api graphql -f query="$THREADS_QUERY" -F o="$OWNER" -F r="$REPO" -F n="$PR" 2>/dev/null); then
    errors=0
  else
    errors=$((errors + 1))
    if (( errors % 3 == 0 )); then
      echo "[POLL_ERROR] $errors consecutive fetch failures — check gh auth / network"
    fi
    sleep "$INTERVAL"
    continue
  fi

  pr_state=$(jq -r '.state' <<<"$pr_json")
  ci=$(jq -c --arg ex "$EXCLUDED" '
    [.statusCheckRollup[]?
      | {name: (.name // .context), c: ((.conclusion // .state // "") | ascii_upcase)}
      | select(.name as $n | ($ex | split(",") | index($n)) | not)]
    | { total: length,
        failures: [.[] | select(.c | IN("FAILURE","CANCELLED","TIMED_OUT","ACTION_REQUIRED","STALE","ERROR","STARTUP_FAILURE")) | .name],
        ok: ([.[] | select(.c | IN("SUCCESS","NEUTRAL","SKIPPED"))] | length) }
    | { total,
        pending: (.total - .ok - (.failures | length)),
        failed: (.failures | length),
        failures }' <<<"$pr_json")
  threads=$(jq -c '
    [.data.repository.pullRequest.reviewThreads.nodes[]?.isResolved]
    | {total: length, unresolved: ([.[] | select(. == false)] | length)}' <<<"$th_json")

  state="CI $ci | Reviews $threads | PR $pr_state"
  if [[ $state != "$last_state" ]]; then
    echo "$state"
    last_state=$state
  fi

  case $pr_state in
    MERGED) echo "DONE: merged"; exit 0 ;;
    CLOSED) echo "DONE: closed without merge"; exit 0 ;;
  esac

  if [[ $UNTIL == green ]]; then
    pending=$(jq -r '.pending' <<<"$ci")
    failed=$(jq -r '.failed' <<<"$ci")
    unresolved=$(jq -r '.unresolved' <<<"$threads")
    if (( pending == 0 && failed == 0 && unresolved == 0 )); then
      echo "DONE: all checks green and threads resolved"
      exit 0
    fi
  fi

  sleep "$INTERVAL"
done
