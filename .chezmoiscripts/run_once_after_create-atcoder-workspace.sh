#!/bin/bash
# Bootstrap ~/repos/github.com/paveg/atcoder as an empty git repo for AtCoder
# solutions. Uses the <host>/<owner>/<repo> layout shared by other repos in
# ~/repos/. Runs once per machine.

set -euo pipefail

dir="$HOME/repos/github.com/paveg/atcoder"

if [[ -d "$dir/.git" ]]; then
  exit 0
fi

mkdir -p "$dir"
cd "$dir"
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

echo "Initialized empty AtCoder workspace at $dir"
