#!/usr/bin/env bash
# Mechanical scoring for writing-bench outputs (Tier 1 of ADR 0006).
#
# Usage: ./score.sh outputs/<run-id>
#
# Per artifact: bench_metrics.py (volume/shape vs the norms' effort targets;
# PR artifacts get the 40-line budget), lint.py --json (rhythm/statistics,
# skipped without uv), and a prh hit count via the proofreader's bundled
# textlint fallback (skipped without npx/network). JSONs land in
# <outputs-dir>/scores/; one summary line per file goes to stdout.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPTS="${REPO_ROOT}/home/dot_claude/skills/writing-proofread/scripts"
ASSETS="${REPO_ROOT}/home/dot_claude/skills/writing-proofread/assets"

outputs_dir="${1:?usage: score.sh <outputs-dir>}"
scores_dir="${outputs_dir}/scores"
mkdir -p "${scores_dir}"

for artifact in "${outputs_dir}"/[0-9][0-9]-*.md; do
  [[ -e ${artifact} ]] || { echo "no NN-*.md artifacts in ${outputs_dir}" >&2; exit 1; }
  stem="$(basename "${artifact}" .md)"

  type_args=()
  [[ ${stem} == *-pr-* ]] && type_args=(--type pr)
  genre=tech
  [[ ${stem} == *-article-* ]] && genre=essay

  python3 "${SCRIPTS}/bench_metrics.py" ${type_args[@]+"${type_args[@]}"} "${artifact}" \
    > "${scores_dir}/${stem}-metrics.json"

  rhythm="skipped"
  rload="skipped"
  if command -v uv >/dev/null; then
    uv run "${SCRIPTS}/lint.py" --json --reading-load --genre "${genre}" "${artifact}" \
      > "${scores_dir}/${stem}-rhythm.json" || true
    rhythm=$(jq -r '[.findings[] | select(.severity != "info")] | length' \
      "${scores_dir}/${stem}-rhythm.json" 2>/dev/null || echo "error")
    rload=$(jq -r '.reading_load.findings | length' \
      "${scores_dir}/${stem}-rhythm.json" 2>/dev/null || echo "error")
  fi

  prh="skipped"
  if command -v npx >/dev/null; then
    prh_config="$(mktemp -d)/textlintrc.json"
    printf '{"rules":{"prh":{"rulePaths":["%s"]}}}' "${ASSETS}/prh.yml" > "${prh_config}"
    npx --loglevel=error -y -p textlint -p textlint-rule-prh \
      textlint --config "${prh_config}" --format json "${artifact}" \
      > "${scores_dir}/${stem}-prh.json" 2>/dev/null || true
    prh=$(jq -r '[.[].messages[]] | length' "${scores_dir}/${stem}-prh.json" 2>/dev/null || echo "error")
    rm -f "${prh_config}"
  fi

  jq -r --arg rhythm "${rhythm}" --arg rload "${rload}" --arg prh "${prh}" '
    "\(.file | split("/") | last)\t" +
    "sent>60:\(.sentences.over_60)\t" +
    "para>150:\(.paragraphs.over_150_chars) para>4s:\(.paragraphs.over_4_sentences)\t" +
    "sect>400:\(.sections.over_400_chars)\t" +
    "h>3:\(.headings.over_h3) nest>2:\(.list_nesting.items_deeper_than_2)\t" +
    "lines:\(.lines.total)/\(.lines.budget // "-")\t" +
    "rhythm:\($rhythm) load:\($rload)\tprh:\($prh)"
  ' "${scores_dir}/${stem}-metrics.json"
done
