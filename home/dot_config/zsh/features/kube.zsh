# kube.zsh - switch kubernetes context/namespace/EKS-cluster with fzf
# Provides:     kctx, kns, kinfo, keks
# Requires:     kubectl, fzf, aws, jq

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

# Switch kubeconfig to an EKS cluster in the current AWS profile with fzf, and
# make it the current context. Needs an active AWS session first (awsp / s2a /
# s2ak). Region precedence: KEKS_REGION override > the active profile's region
# (aws configure get region) > ap-northeast-1.
# The context is aliased "<profile>/<cluster>" so kctx stays readable across
# many accounts that reuse cluster names (e.g. prod).
keks() {
  if [[ -z "$AWS_PROFILE" ]]; then
    echo "keks: AWS_PROFILE is unset — run awsp or s2ak first" >&2
    return 1
  fi

  local region="${KEKS_REGION:-$(aws configure get region 2>/dev/null)}"
  region="${region:-ap-northeast-1}"

  local out
  if ! out=$(aws eks list-clusters --region "$region" --output json 2>&1); then
    if grep -qiE 'expired|invalid.*token|sso session|load sso token|refresh failed' <<<"$out"; then
      echo "keks: AWS session expired for $AWS_PROFILE — run awsp/s2ak to re-auth" >&2
    elif grep -qiE 'not authorized|accessdenied|unauthorized' <<<"$out"; then
      echo "keks: $AWS_PROFILE lacks eks:ListClusters in $region — pick a profile/role with EKS access (awsp/s2ak)" >&2
    else
      echo "keks: list-clusters failed in $region" >&2
    fi
    echo "$out" >&2
    return 1
  fi

  local clusters
  clusters=$(jq -r '.clusters[]' <<<"$out")
  [[ -z "$clusters" ]] && { echo "keks: no EKS clusters in $AWS_PROFILE ($region)" >&2; return 1; }

  local cluster
  cluster=$(fzf --reverse --height=40% \
      --header="EKS cluster in $AWS_PROFILE ($region)" <<<"$clusters") || return 1
  [[ -z "$cluster" ]] && return 1

  aws eks update-kubeconfig --region "$region" --name "$cluster" \
      --alias "$AWS_PROFILE/$cluster" \
    && echo "kube context: $AWS_PROFILE/$cluster"
}
