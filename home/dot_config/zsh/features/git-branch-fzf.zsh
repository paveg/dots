# git-branch-fzf.zsh - switch git branches with fzf
# Provides:     git_branch_fzf_switch, gcof, gbc, gswf
# Requires:     git, fzf

_git_branch_fzf_list() {
  local mode="${1:-all}"
  local current short full date kind marker
  local reset bold dim cyan green magenta branch_style kind_style
  local branch_display branch_text date_text display

  reset=$'\033[0m'
  bold=$'\033[1m'
  dim=$'\033[2m'
  cyan=$'\033[36m'
  green=$'\033[32m'
  magenta=$'\033[35m'

  current="$(command git symbolic-ref --quiet --short HEAD 2>/dev/null)"

  command git for-each-ref \
    --sort=-committerdate \
    --format=$'%(refname:short)\t%(refname)\t%(committerdate:relative)' \
    refs/heads refs/remotes |
    while IFS=$'\t' read -r short full date; do
      [[ "$full" == */HEAD ]] && continue
      case "$mode" in
        local)
          [[ "$full" == refs/remotes/* ]] && continue
          ;;
        remote)
          [[ "$full" == refs/remotes/* ]] || continue
          ;;
        all)
          ;;
        *)
          return 2
          ;;
      esac

      marker=" "
      branch_style="$cyan"
      if [[ "$short" == "$current" ]]; then
        marker="${green}*${reset}"
        branch_style="${bold}${cyan}"
      fi

      kind="L"
      kind_style="$green"
      if [[ "$full" == refs/remotes/* ]]; then
        kind="R"
        kind_style="$magenta"
      fi

      branch_display="$short"
      (( ${#branch_display} > 42 )) && branch_display="${branch_display[1,39]}..."
      printf -v branch_text "%-42s" "$branch_display"
      printf -v date_text "%12s" "$date"

      display="${marker}  ${kind_style}${kind}${reset}  ${branch_style}${branch_text}${reset}  ${dim}${date_text}${reset}"

      printf "%s\t%s\t%s\n" "$short" "$kind" "$display"
    done
}

git_branch_fzf_switch() {
  if ! command git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Error: Not in a git repository" >&2
    return 1
  fi

  if ! (( $+commands[fzf] )); then
    echo "Error: git_branch_fzf_switch requires fzf" >&2
    return 1
  fi

  local tmp_dir all_file local_file remote_file
  tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/gcof.XXXXXX")" || return 1
  all_file="$tmp_dir/all"
  local_file="$tmp_dir/local"
  remote_file="$tmp_dir/remote"

  _git_branch_fzf_list all > "$all_file"
  _git_branch_fzf_list local > "$local_file"
  _git_branch_fzf_list remote > "$remote_file"

  local all_cmd local_cmd remote_cmd
  all_cmd="cat ${(q)all_file}"
  local_cmd="cat ${(q)local_file}"
  remote_cmd="cat ${(q)remote_file}"

  local selected branch kind display
  selected="$(cat "$local_file" |
    fzf --ansi --layout=reverse --height=85% --border --cycle --no-hscroll \
      --prompt="local> " \
      --header="Enter: switch | Ctrl-A all / Ctrl-L local / Ctrl-R remote | Ctrl-/ preview" \
      --delimiter=$'\t' \
      --nth=1 \
      --with-nth=3 \
      --bind="ctrl-a:reload($all_cmd)+change-prompt(all> )" \
      --bind="ctrl-l:reload($local_cmd)+change-prompt(local> )" \
      --bind="ctrl-r:reload($remote_cmd)+change-prompt(remote> )" \
      --bind="ctrl-/:toggle-preview" \
      --preview='branch={1}; kind={2}; printf "\033[1;36m%s\033[0m  \033[2m%s\033[0m\n\n" "$branch" "$kind"; git log --graph --decorate --color=always --date=relative --max-count=40 --pretty=format:"%C(auto)%h%d %s %C(green)(%cr)%C(reset)" "$branch" --' \
      --preview-window=right:55%:wrap)"

  command rm -f "$all_file" "$local_file" "$remote_file"
  command rmdir "$tmp_dir" 2>/dev/null

  [[ -z "$selected" ]] && return 0

  IFS=$'\t' read -r branch kind display <<< "$selected"
  [[ -z "$branch" ]] && return 0

  if [[ "$kind" == "R" ]]; then
    local local_branch="${branch#*/}"

    if command git show-ref --verify --quiet "refs/heads/$local_branch"; then
      command git switch "$local_branch"
    else
      command git switch --track "$branch"
    fi
  else
    command git switch "$branch"
  fi
}

alias gcof='git_branch_fzf_switch'
alias gbc='git_branch_fzf_switch'
alias gswf='git_branch_fzf_switch'
