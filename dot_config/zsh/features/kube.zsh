# kube.zsh - switch kubernetes context/namespace with fzf
# Provides:     kctx, kns, kinfo
# Requires:     kubectl, fzf

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
