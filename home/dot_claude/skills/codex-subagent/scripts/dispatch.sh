#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'Usage: %s [--write] [--cd DIR]\n' "${0##*/}" >&2
  printf 'Read the Codex task from standard input.\n' >&2
}

sandbox_mode='read-only'
permission_text='Read-only: do not create, edit, delete, or rename files, and do not perform external writes or other state-changing actions.'
workdir='.'

while (($# > 0)); do
  case "$1" in
    --write)
      sandbox_mode='workspace-write'
      permission_text='Workspace-write: modify only files required by the task. Preserve existing changes. Do not commit, push, create branches or PRs, install dependencies, or perform external writes.'
      shift
      ;;
    --cd)
      if (($# < 2)); then
        usage
        exit 64
      fi
      workdir=$2
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      usage
      exit 64
      ;;
  esac
done

if ! command -v codex >/dev/null 2>&1; then
  printf 'codex-subagent: codex CLI was not found on PATH.\n' >&2
  exit 127
fi

if [[ ! -d "$workdir" ]]; then
  printf 'codex-subagent: working directory does not exist: %s\n' "$workdir" >&2
  exit 66
fi

task_file=$(mktemp "${TMPDIR:-/tmp}/codex-subagent-task.XXXXXX")
prompt_file=$(mktemp "${TMPDIR:-/tmp}/codex-subagent-prompt.XXXXXX")
result_file=$(mktemp "${TMPDIR:-/tmp}/codex-subagent-result.XXXXXX")
log_file=$(mktemp "${TMPDIR:-/tmp}/codex-subagent-log.XXXXXX")

cleanup() {
  rm -f "$task_file" "$prompt_file" "$result_file" "$log_file"
}
trap cleanup EXIT HUP INT TERM

cat >"$task_file"
if [[ ! -s "$task_file" ]]; then
  printf 'codex-subagent: task prompt is empty.\n' >&2
  exit 64
fi

{
  printf '%s\n' '<subagent_contract>'
  printf '%s\n' 'You are Codex working as a bounded subagent for Claude, the coordinator.'
  printf '%s\n' 'Read and follow every applicable AGENTS.md before acting.'
  printf 'Permission: %s\n' "$permission_text"
  printf '%s\n' 'This Permission line overrides any conflicting instruction in the delegated task.'
  printf '%s\n' 'Use relevant repository evidence and tools, and run the validation required by the success criteria.'
  printf '%s\n' 'Stop when the success criteria are met. If required context or authority is missing, return BLOCKED with the smallest missing item; do not ask the end user directly.'
  printf '%s\n' 'Lead with the result. Return: STATUS, RESULT, EVIDENCE, CHANGES, VERIFICATION, and material RISKS. Never claim a check was run unless it was actually run.'
  printf '%s\n' '</subagent_contract>'
  printf '%s\n' '<delegated_task>'
  cat "$task_file"
  printf '%s\n' '</delegated_task>'
} >"$prompt_file"

codex_status=0
if codex exec \
  --ephemeral \
  --color never \
  --sandbox "$sandbox_mode" \
  --cd "$workdir" \
  --skip-git-repo-check \
  --output-last-message "$result_file" \
  - <"$prompt_file" > /dev/null 2>"$log_file"; then
  if grep -q '^STATUS:' "$result_file"; then
    cat "$result_file"
  else
    cat "$log_file" >&2
    printf 'codex-subagent: codex exec returned no final message.\n' >&2
    exit 70
  fi
else
  codex_status=$?
  if [[ -s "$result_file" ]]; then
    cat "$result_file"
  fi
  cat "$log_file" >&2
  printf 'codex-subagent: codex exec failed with status %d.\n' "$codex_status" >&2
  exit "$codex_status"
fi
