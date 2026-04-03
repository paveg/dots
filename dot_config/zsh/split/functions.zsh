# =============================================================================
# Functions
# =============================================================================

# ghq + fzf repository navigation (cached for speed)
_GHQ_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/ghq_list"

# Update ghq cache in background
_ghq_cache_update() {
  command ghq list > "$_GHQ_CACHE" 2>/dev/null
}

# Initialize cache on shell startup (background, non-blocking)
if [[ ! -f "$_GHQ_CACHE" ]]; then
  mkdir -p "$(dirname "$_GHQ_CACHE")"
  _ghq_cache_update &!
fi

# ghq wrapper: auto-update cache when repos change
ghq() {
  local subcmd="$1"
  command ghq "$@"
  local ret=$?

  # Update cache after repo-modifying commands
  case "$subcmd" in
    get|create|rm)
      _ghq_cache_update &!
      ;;
  esac

  return $ret
}

_fzf_cd_ghq() {
  local root repo
  root="$(command ghq root 2>/dev/null)" || return 1

  # Save original buffer state for restoration on cancel
  local orig_buffer="$BUFFER"
  local orig_cursor="$CURSOR"

  # Ensure cache exists
  [[ ! -f "$_GHQ_CACHE" ]] && _ghq_cache_update

  local preview_cmd='
    repo_path='"$root"'/{}
    if [[ -f $repo_path/README.md ]]; then
      bat --color=always --style=header,grid --line-range :80 $repo_path/README.md 2>/dev/null
    elif [[ -f $repo_path/README.rst ]]; then
      bat --color=always --style=header,grid --line-range :80 $repo_path/README.rst 2>/dev/null
    elif [[ -f $repo_path/README ]]; then
      bat --color=always --style=header,grid --line-range :80 $repo_path/README 2>/dev/null
    else
      echo Contents:
      eza -la $repo_path 2>/dev/null | head -n 15
    fi
  '

  repo="$(cat "$_GHQ_CACHE" 2>/dev/null | \
    fzf --reverse --height=80% \
        --header='Ctrl+R: refresh cache' \
        --bind="ctrl-r:reload(command ghq list | tee $_GHQ_CACHE)" \
        --preview="$preview_cmd" \
        --preview-window=right:50%)"

  # Handle ESC or empty selection - restore original buffer
  if [[ -z "$repo" ]]; then
    BUFFER="$orig_buffer"
    CURSOR="$orig_cursor"
    zle reset-prompt
    return 0
  fi

  local dir="$root/$repo"
  if [[ -d "$dir" ]]; then
    # Execute cd directly instead of through BUFFER
    # This avoids issues with stray input being left in the zle buffer
    cd "$dir"
    zle reset-prompt
  else
    BUFFER="$orig_buffer"
    CURSOR="$orig_cursor"
    zle -M "Directory not found: $dir"
    zle reset-prompt
  fi
}
zle -N _fzf_cd_ghq
bindkey '^g' _fzf_cd_ghq
alias repos='_fzf_cd_ghq'

# Remove merged branches (from existing config)
PROTECTED_BRANCHES='main|master|develop|staging'
rub() {
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Error: Not in a git repository" >&2
    return 1
  fi
  local merged
  merged=$(git branch --merged | grep -Ev "*|${PROTECTED_BRANCHES}")
  [[ -z "$merged" ]] && echo "No merged branches to delete" && return 0
  echo "$merged" | xargs git branch -d
}

# Profiling
zprofiler() { ZSHRC_PROFILE=1 zsh -i -c zprof }
zshtime() { for i in {1..10}; do time zsh -i -c exit; done }

# =============================================================================
# Local config management
# =============================================================================
local-env() {
  local file="$HOME/.env.local"
  case "$1" in
    edit)
      [[ ! -f "$file" ]] && echo "# Machine-specific environment variables" > "$file"
      ${EDITOR:-nvim} "$file"
      echo "Run 'source ~/.env.local' or restart shell to apply changes"
      ;; 
    show)
      if [[ -f "$file" ]]; then
        echo "=== ~/.env.local ==="
        cat "$file"
      else
        echo "~/.env.local does not exist. Run 'local-env edit' to create."
      fi
      ;; 
    *)
      echo "Usage: local-env <command>"
      echo ""
      echo "Commands:"
      echo "  edit    Edit ~/.env.local (environment variables)"
      echo "  show    Show current ~/.env.local contents"
      echo ""
      echo "Related files:"
      echo "  ~/.env.local     - Environment variables (export VAR=value)"
      echo "  ~/.zshrc.local   - Shell config (aliases, functions)"
      echo "  .envrc           - Per-directory env (direnv)"
      ;; 
  esac
}

local-zsh() {
  local file="$HOME/.zshrc.local"
  case "$1" in
    edit)
      if [[ ! -f "$file" ]]; then
        cat > "$file" << 'EOF'
# Machine-specific zsh configuration
# This file is sourced at the end of ~/.zshrc

# Example:
# alias myalias='some-command'
# export PATH="$HOME/custom/bin:$PATH"
EOF
      fi
      ${EDITOR:-nvim} "$file"
      echo "Run 'source ~/.zshrc.local' or restart shell to apply changes"
      ;; 
    show)
      if [[ -f "$file" ]]; then
        echo "=== ~/.zshrc.local ==="
        cat "$file"
      else
        echo "~/.zshrc.local does not exist. Run 'local-zsh edit' to create."
      fi
      ;; 
    *)
      echo "Usage: local-zsh <command>"
      echo ""
      echo "Commands:"
      echo "  edit    Edit ~/.zshrc.local (shell config)"
      echo "  show    Show current ~/.zshrc.local contents"
      ;; 
  esac
}

# =============================================================================
# Neovim documentation
# =============================================================================
vdoc() {
  local readme="${XDG_CONFIG_HOME:-$HOME/.config}/nvim/README.md"
  if [[ -f "$readme" ]]; then
    glow "$readme"
  else
    echo "README not found: $readme"
    echo "Run 'chezmoi apply' to install."
  fi
}

# =============================================================================
# Dotfiles help
# =============================================================================
dots() {
  cat << 'EOF'
╭──────────────────────────────────────────────────────────────────╮
│                         dots - dotfiles                          │
╰──────────────────────────────────────────────────────────────────╯

📁 Config Locations
  ~/.config/nvim/      Neovim (kickstart + Copilot)
  ~/.config/git/       Git (delta, conditional includes)
  ~/.p10k.zsh              Prompt (powerlevel10k)
  ~/.config/lazygit/   Git TUI (conventional commits)
  ~/.config/ghostty/   Terminal (Catppuccin Mocha, OSC 52)
  ~/.config/atuin/     Shell history (fuzzy search)
  ~/.tmux.conf         Tmux (Catppuccin, vim keys, OSC 52)

🔧 Local Config (per-machine, not tracked)
  ~/.env.local         Global environment variables
  ~/.zshrc.local       Shell customizations
  .envrc               Per-project env (direnv, needs allow)
  .env                  Per-project env (auto-loaded)

⌨️  Key Bindings
  Ctrl+g       Repository navigation (ghq + fzf)
  Ctrl+t       File search with preview (fzf)
  Ctrl+r       History search (atuin)
  Alt+c        Directory navigation (fzf)
  Ctrl+u/d     Scroll preview (fzf/atuin)
  z <dir>      Smart cd (zoxide)

🖥️  Tmux (Prefix = Ctrl+a)
  prefix + |   Split horizontal
  prefix + -   Split vertical
  prefix + h/j/k/l   Navigate panes
  prefix + r   Reload config
  v            Begin selection (copy mode)
  y            Copy to clipboard (OSC 52)
  Shift+drag   Copy via terminal (bypass tmux)

🛠️  Commands
  repos        Jump to repository (ghq + fzf)
  rub          Remove merged git branches
  lg           lazygit
  kctx         Switch kube context (fzf)
  kns          Switch namespace (fzf)
  kinfo        Show current context/namespace

  le           Edit ~/.env.local
  lz           Edit ~/.zshrc.local
  local-env    Manage environment variables
  local-zsh    Manage shell config

  zsh-bench    Benchmark shell startup
  zsh-clear-cache   Clear all caches
  zsh-update-cache  Regenerate init caches

📝 Neovim (Leader = Space)
  <leader>ff   Find files
  <leader>fg   Live grep
  <leader>e    File explorer
  gd           Go to definition
  <leader>cc   Copilot Chat

🔄 Chezmoi
  chezmoi diff       Show pending changes
  chezmoi apply      Apply changes
  chezmoi edit       Edit source files
  chezmoi update     Pull & apply latest

📦 Devbox
  devbox global list   List installed tools
  devbox global add    Install tool globally

EOF
}

# Cache management
zsh-clear-cache() {
  rm -rf "${XDG_CACHE_HOME}/zsh/init"
  rm -rf "${XDG_CACHE_HOME}/zsh/completions"
  rm -rf "${XDG_CACHE_HOME}/p10k"*
  rm -rf "${XDG_CACHE_HOME}/gitstatus"
  rm -f "${XDG_CACHE_HOME}/devbox/shellenv.zsh"
  rm -rf "${XDG_DATA_HOME}/zinit"
  echo "All cache cleared. Restart shell to reinstall zinit."
  echo "Note: atuin history is preserved in ~/.local/share/atuin/"
}

zsh-update-cache() {
  rm -rf "${XDG_CACHE_HOME}/zsh/init"
  rm -rf "${XDG_CACHE_HOME}/zsh/completions"
  rm -rf "${XDG_CACHE_HOME}/p10k"*
  rm -rf "${XDG_CACHE_HOME}/gitstatus"
  rm -f "${XDG_CACHE_HOME}/devbox/shellenv.zsh"
  echo "Init cache cleared. Restart shell to regenerate."
}

zsh-bench() {
  for i in {1..10}; do
    time zsh -i -c exit
  done
}

# =============================================================================
# Auto-load .env files (fallback when no .envrc exists)
# =============================================================================
# Note: If .envrc exists, direnv handles everything (use dotenv_if_exists in .envrc)
# This hook only activates when .env exists but .envrc doesn't

_dotenv_loaded_dir=""

_auto_dotenv() {
  # Skip if direnv will handle this directory
  [[ -f ".envrc" ]] && return

  # Load .env if exists
  if [[ -f ".env" ]]; then
    if [[ "$_dotenv_loaded_dir" != "$PWD" ]]; then
      # shellcheck disable=SC1091
      set -a
      source ".env"
      set +a
      _dotenv_loaded_dir="$PWD"
    fi
  fi
}

autoload -Uz add-zsh-hook
add-zsh-hook chpwd _auto_dotenv

# =============================================================================
# Kubernetes context/namespace switching
# =============================================================================
# Switch kube context with fzf
kctx() {
  local context
  context=$( (echo "(none)"; kubectl config get-contexts -o name 2>/dev/null) | \
    fzf --reverse --height=40% \
        --header='Select Kubernetes context (none = unset)' \
        --preview='[[ {} == "(none)" ]] && echo "Unset current context" || kubectl config view --minify --context={} 2>/dev/null | head -20')

  [[ -z "$context" ]] && return 0
  if [[ "$context" == "(none)" ]]; then
    kubectl config unset current-context
    echo "Context unset"
  else
    kubectl config use-context "$context"
  fi
}

# Switch namespace with fzf
kns() {
  local ns
  ns=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' 2>/dev/null | \
    tr ' ' '\n' | \
    fzf --reverse --height=40% \
        --header='Select namespace' \
        --preview='kubectl get pods -n {} --no-headers 2>/dev/null | head -20')

  [[ -z "$ns" ]] && return 0
  kubectl config set-context --current --namespace="$ns"
  echo "Switched to namespace: $ns"
}

# Show current context and namespace
kinfo() {
  echo "Context:   $(kubectl config current-context 2>/dev/null || echo 'none')"
  echo "Namespace: $(kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null || echo 'default')"
}

# =============================================================================
# Devbox wrapper - auto re-add to chezmoi after global changes
# =============================================================================
devbox() {
  command devbox "$@"
  local ret=$?

  # Re-add devbox global config to chezmoi after modifying commands
  if [[ "$1" == "global" ]] && [[ "$2" =~ ^(add|rm|install|remove|update)$ ]]; then
    local devbox_global="${HOME}/.local/share/devbox/global/default"
    if [[ -f "${devbox_global}/devbox.json" ]]; then
      chezmoi re-add "${devbox_global}/devbox.json" "${devbox_global}/devbox.lock" 2>/dev/null
      echo "📦 chezmoi re-add: devbox.json, devbox.lock"
    fi
  fi

  return $ret
}

# =============================================================================
# macOS specific
# =============================================================================
# Brewfile management
brewbundle() {
  local chezmoi_dir="${CHEZMOI_SOURCE_DIR:-$HOME/.local/share/chezmoi}"
  local brewfile
  if [[ -n "$BUSINESS_USE" ]]; then
    brewfile="$chezmoi_dir/homebrew/Brewfile.work"
  else
    brewfile="$chezmoi_dir/homebrew/Brewfile"
  fi
  [[ ! -f "$brewfile" ]] && echo "Brewfile not found: $brewfile" && return 1
  brew bundle dump --force --file="$brewfile"
  echo "Updated: $brewfile"
}

# =============================================================================
# git worktree + tmux automation
# =============================================================================
_wt_repo_basename() {
  basename "$(git rev-parse --show-toplevel 2>/dev/null)"
}

_wt_dir() {
  local toplevel name
  toplevel="$(git rev-parse --show-toplevel 2>/dev/null)" || return 1
  name="$1"
  echo "${toplevel}/../$(_wt_repo_basename)-${name}"
}

_wt_guard() {
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Error: Not in a git repository" >&2
    return 1
  fi
  if [[ -z "$TMUX" ]]; then
    echo "Error: Not inside tmux" >&2
    return 1
  fi
}

_wt_add() {
  local name="$1" base="${2:-HEAD}"
  if [[ -z "$name" ]]; then
    echo "Usage: wt add <name> [base-branch]" >&2
    return 1
  fi
  _wt_guard || return 1

  local dir
  dir="$(_wt_dir "$name")"

  if [[ -d "$dir" ]]; then
    echo "Error: Worktree already exists: $dir" >&2
    return 1
  fi

  if git show-ref --verify --quiet "refs/heads/$name"; then
    git worktree add "$dir" "$name" || return 1
  else
    git worktree add -b "$name" "$dir" "$base" || return 1
  fi
  tmux new-window -n "$name" -c "$dir"
  tmux set-option -w automatic-rename off
  echo "Created worktree: $dir (branch: $name)"
}

_wt_fzf_select() {
  local repo_base
  repo_base="$(_wt_repo_basename)"
  git worktree list --porcelain | awk -v base="$repo_base" '
    /^worktree / {
      n = split(substr($0, 10), parts, "/")
      dir = parts[n]
      if (dir == base) next
      sub("^" base "-", "", dir)
      print dir
    }
  ' | fzf --reverse --height=40% --prompt="${1:-worktree}> "
}

_wt_rm() {
  local name="$1" force=""
  if [[ -z "$name" ]]; then
    _wt_guard || return 1
    name="$(_wt_fzf_select "rm")"
    [[ -z "$name" ]] && return 0
  fi
  _wt_guard || return 1

  # Protect main worktree
  if [[ "$name" == "$(_wt_repo_basename)" ]]; then
    echo "Error: Cannot remove the main worktree" >&2
    return 1
  fi

  [[ "${@[-1]}" == "--force" ]] && force="--force"

  local dir
  dir="$(_wt_dir "$name")"

  tmux kill-window -t ":$name" 2>/dev/null
  git worktree remove "$dir" $force || return 1
  git worktree prune
  # Clean up branch if it exists and is fully merged
  git branch -d "$name" 2>/dev/null || git branch -D "$name" 2>/dev/null
  echo "Removed worktree: $dir"
}

_wt_ls() {
  _wt_guard || return 1

  local repo_base tmux_windows
  repo_base="$(_wt_repo_basename)"
  tmux_windows=$(tmux list-windows -F '#{window_name}' 2>/dev/null | paste -sd, -)

  git worktree list --porcelain | awk -v base="$repo_base" -v wins="$tmux_windows" '
    BEGIN { split(wins, w, ","); for (i in w) win_set[w[i]] = 1 }
    /^worktree / {
      path = substr($0, 10)
      # Extract name: strip repo-base- prefix from dirname
      n = split(path, parts, "/")
      dir = parts[n]
      sub("^" base "-", "", dir)
      name = dir
    }
    /^branch / {
      branch = substr($0, 8)
      sub("^refs/heads/", "", branch)
    }
    /^HEAD / { branch = "(detached)" }
    /^$/ {
      tmux = (name in win_set) ? "+" : "-"
      printf "%-4s %-30s %-30s %s\n", tmux, name, branch, path
      name = ""; branch = ""; path = ""
    }
    END {
      if (name != "") {
        tmux = (name in win_set) ? "+" : "-"
        printf "%-4s %-30s %-30s %s\n", tmux, name, branch, path
      }
    }
  '
}

_wt_cd() {
  _wt_guard || return 1

  local name="$1"
  if [[ -z "$name" ]]; then
    name="$(_wt_fzf_select "cd")"
    [[ -z "$name" ]] && return 0
  fi

  tmux select-window -t ":$name" 2>/dev/null || {
    echo "Error: tmux window '$name' not found. Try 'wt ls'" >&2
    return 1
  }
}

_wt_list_names() {
  local repo_base
  repo_base="$(_wt_repo_basename)"
  git worktree list --porcelain | awk -v base="$repo_base" '
    /^worktree / {
      path = substr($0, 10)
      n = split(path, parts, "/")
      dir = parts[n]
      if (dir == base) next
      sub("^" base "-", "", dir)
      name = dir
    }
    /^branch / {
      branch = substr($0, 8)
      sub("^refs/heads/", "", branch)
    }
    /^HEAD / { branch = "(detached)" }
    /^$/ {
      if (name != "") printf "%-30s %-30s %s\n", name, branch, path
      name = ""; branch = ""; path = ""
    }
    END {
      if (name != "") printf "%-30s %-30s %s\n", name, branch, path
    }
  '
}

_wt_interactive() {
  _wt_guard || return 1

  local items
  items=$(_wt_list_names)
  [[ -z "$items" ]] && items="(no worktrees)"

  local reload_cmd="source ~/.config/zsh/split/functions.zsh && _wt_list_names"
  local add_cmd="source ~/.config/zsh/split/functions.zsh && read 'b?branch: ' && wt add \$b"
  local rm_cmd="source ~/.config/zsh/split/functions.zsh && wt rm {1}"

  echo "$items" | fzf \
    --reverse \
    --header="enter:switch / ctrl-a:add / ctrl-d:remove" \
    --bind "enter:become(tmux select-window -t :{1})" \
    --bind "ctrl-a:execute($add_cmd)+reload($reload_cmd)" \
    --bind "ctrl-d:execute($rm_cmd)+reload($reload_cmd)"
}

_wt_usage() {
  cat <<'EOF'
Usage: wt <command> [args]

Commands:
  add <name> [base]    Create worktree + tmux window (default base: HEAD)
  rm  <name> [--force] Remove worktree + tmux window
  ls                   List worktrees (+ = tmux window exists)
  cd  [name]           Switch to worktree tmux window (fzf if no name)
  help                 Show this help

  (no args)            Interactive mode (fzf)
EOF
}

wt() {
  case "$1" in
    add)  _wt_add "${@:2}" ;;
    rm)   _wt_rm "${@:2}" ;;
    ls)   _wt_ls ;;
    cd)   _wt_cd "${@:2}" ;;
    help) _wt_usage ;;
    "")   _wt_interactive ;;
    *)    _wt_cd "$@" ;;
  esac
}
