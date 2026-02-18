#!/usr/bin/env bash
set -euo pipefail

URL="${1:?Usage: run_one.sh <repeatmodeler.fa URL>}"

REPEATCLASSIFIER="/software/team301/repeat-annotation/RepeatModeler-2.0.5/RepeatClassifier"

# parse species + accession from URL
species="$(echo "$URL" | awk -F'/' '{print $(NF-1)}')"
file="$(basename "$URL")"
acc="${file%.repeatmodeler.fa}"

# run script from repo root no matter where invoked
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

root="${REPO_ROOT}/data/${species}/${acc}"
mkdir -p "${root}"/{input,work,results,logs}

infa="${root}/input/${file}"
stdout_log="${root}/logs/repeatclassifier.stdout.txt"
stderr_log="${root}/logs/repeatclassifier.stderr.txt"

# download
if [[ ! -s "$infa" ]]; then
  echo "[download] $URL"
  curl -L --fail -o "$infa" "$URL"
else
  echo "[download] exists: ${infa#${REPO_ROOT}/}"
fi

echo "[classify] running RepeatClassifier on ${infa#${REPO_ROOT}/}"

# Run in work dir, but log to absolute paths
pushd "${root}/work" >/dev/null
"${REPEATCLASSIFIER}" -consensi "$infa" > "$stdout_log" 2> "$stderr_log"
popd >/dev/null

echo "[collect] gathering outputs"
# Copy everything produced in work/ into results/ (keeps a full record)
rsync -a --delete "${root}/work/" "${root}/results/work_outputs/"

# Also bubble up the common "headline" files if present
shopt -s nullglob
for f in "${root}/work/"*.classified* "${root}/work/"*.tbl "${root}/work/"*.out "${root}/work/"*.log; do
  cp -av "$f" "${root}/results/" >/dev/null 2>&1 || true
done
shopt -u nullglob

echo "[done] ${species} ${acc}"
echo "  input:   ${infa#${REPO_ROOT}/}"
echo "  results: ${root#${REPO_ROOT}/}/results"
echo "  logs:    ${root#${REPO_ROOT}/}/logs"
