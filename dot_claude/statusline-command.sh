#!/usr/bin/env bash
# Claude Code statusLine command
# Displays: directory | branch | ccusage output

input=$(cat)

# --- Directory (basename of cwd) ---
cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // ""')
dir=$(basename "${cwd:-$PWD}")

# --- Git branch ---
branch=""
if [[ -n "$cwd" ]] && git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
           || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
fi

# --- Color setup ---
RESET=$'\e[0m'; RED=$'\e[31m'; YELLOW=$'\e[33m'; GREEN=$'\e[32m'

# Context info from Claude Code JSON (accurate current window usage)
pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
tokens=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')
tokens_fmt=$(LC_ALL=en_US.UTF-8 printf "%'.0f" "$tokens")
if   [[ $pct -ge 80 ]]; then ctx_color=$RED
elif [[ $pct -ge 50 ]]; then ctx_color=$YELLOW
else                          ctx_color=$GREEN
fi

# ccusage: cost/burn rate info only; strip its 🧠 section and append JSON-sourced one
cost=$(echo "$input" | npx --yes ccusage statusline 2>/dev/null)
cost="${cost/ | 🧠*/}"
cost="${cost} | 🧠 ${tokens_fmt} ${ctx_color}(${pct}%)${RESET}"

# --- Assemble output ---
parts=()
[[ -n "$dir" ]]    && parts+=("$dir")
[[ -n "$branch" ]] && parts+=("$branch")
[[ -n "$cost" ]]   && parts+=("$cost")

printf '%s' "$(IFS=' | '; echo "${parts[*]}")"
