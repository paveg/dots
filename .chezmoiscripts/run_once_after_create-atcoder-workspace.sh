#!/bin/bash
# Bootstrap ~/repos/github.com/paveg/atcoder as an empty git repo for AtCoder
# solutions. Uses the <host>/<owner>/<repo> layout shared by other repos in
# ~/repos/. Runs once per machine.

set -euo pipefail

dir="$HOME/repos/github.com/paveg/atcoder"

mkdir -p "$dir"
cd "$dir"

if [[ ! -d ".git" ]]; then
  git init -q -b main
  cat >.gitignore <<'EOF'
# Build artifacts
*.out
*.exe

# Editor
.vscode/
.idea/

# acc test cases (problem statements are copyrighted by AtCoder)
**/tests/
EOF
fi

if [[ ! -f "go.mod" ]] && command -v go >/dev/null 2>&1; then
  go mod init github.com/paveg/atcoder >/dev/null
fi

echo "AtCoder workspace ready at $dir"
