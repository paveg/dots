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

THREADS_QUERY="query(\$o:String!,\$r:String!,\$n:Int!,\$after:String){repository(owner:\$o,name:\$r){pullRequest(number:\$n){reviewThreads(first:100,after:\$after){nodes{isResolved}pageInfo{hasNextPage endCursor}}}}}"

last_state=""
polls=0
errors=0

fetch_threads() {
  local after=""
  local seen=$'\n'
  local page stats has_next next page_total page_unresolved
  local pages=0
  local total=0
  local unresolved=0
  local -a args

  while true; do
    # Bound each poll even if the API returns an endless sequence of cursors.
    ((pages >= 100)) && return 1
    pages=$((pages + 1))

    args=(api graphql -f query="$THREADS_QUERY" -f o="$OWNER" -f r="$REPO" -F n="$PR")
    [[ -n $after ]] && args+=(-f after="$after")
    page=$(gh "${args[@]}" 2>/dev/null) || return 1

    stats=$(jq -ec '
      select(
        (.errors == null)
        or ((.errors | type) == "array" and (.errors | length) == 0)
      )
      | .data.repository.pullRequest.reviewThreads
      | select((.nodes | type) == "array")
      | select(all(.nodes[]; (.isResolved | type) == "boolean"))
      | select((.pageInfo.hasNextPage | type) == "boolean")
      | { total: (.nodes | length),
          unresolved: ([.nodes[] | select(.isResolved == false)] | length),
          hasNextPage: .pageInfo.hasNextPage,
          endCursor: .pageInfo.endCursor }' <<<"$page") || return 1

    page_total=$(jq -r '.total' <<<"$stats")
    page_unresolved=$(jq -r '.unresolved' <<<"$stats")
    total=$((total + page_total))
    unresolved=$((unresolved + page_unresolved))

    has_next=$(jq -r '.hasNextPage' <<<"$stats")
    [[ $has_next == true ]] || break

    next=$(jq -er '.endCursor | select(type == "string" and length > 0)' <<<"$stats") || return 1
    [[ $seen == *$'\n'"$next"$'\n'* ]] && return 1
    seen+="$next"$'\n'
    after=$next
  done

  jq -cn --argjson total "$total" --argjson unresolved "$unresolved" \
    '{total: $total, unresolved: $unresolved}'
}

while true; do
  polls=$((polls + 1))
  if ((MAX_POLLS > 0 && polls > MAX_POLLS)); then
    echo "[TIMEOUT] max polls reached"
    exit 1
  fi

  if pr_json=$(gh pr view "$PR" --repo "$OWNER/$REPO" --json state,statusCheckRollup 2>/dev/null) &&
    threads=$(fetch_threads); then
    errors=0
  else
    errors=$((errors + 1))
    if ((errors % 3 == 0)); then
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
  state="CI $ci | Reviews $threads | PR $pr_state"
  if [[ $state != "$last_state" ]]; then
    echo "$state"
    last_state=$state
  fi

  case $pr_state in
    MERGED)
      echo "DONE: merged"
      exit 0
      ;;
    CLOSED)
      echo "DONE: closed without merge"
      exit 0
      ;;
  esac

  if [[ $UNTIL == green ]]; then
    pending=$(jq -r '.pending' <<<"$ci")
    failed=$(jq -r '.failed' <<<"$ci")
    unresolved=$(jq -r '.unresolved' <<<"$threads")
    if ((pending == 0 && failed == 0 && unresolved == 0)); then
      echo "DONE: all checks green and threads resolved"
      exit 0
    fi
  fi

  sleep "$INTERVAL"
done
