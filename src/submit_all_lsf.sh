#!/usr/bin/env bash
#
# This is a script to submit all of the DToL RepeatModeler classification jobs to LSF.
# It can be run multiple times, as it checks directories of already run species.
set -euo pipefail

# One URL per line (no header)
LIST="${1:-src/repeatmodeler_links_ensembl_dtol.tsv}"

# LSF defaults (tweak)
QUEUE="${QUEUE:-normal}"
CORES="${CORES:-4}"
MEM_MB="${MEM_MB:-12000}"         # per job
MAX_INFLIGHT="${MAX_INFLIGHT:-200}"  # throttle submissions
SLEEP_SEC="${SLEEP_SEC:-30}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_ONE="${REPO_ROOT}/src/run_one.sh"

mkdir -p "${REPO_ROOT}/lsf/out" "${REPO_ROOT}/lsf/err"

if [[ ! -f "$LIST" ]]; then
  echo "List file not found: $LIST" >&2
  exit 2
fi

# helper: how many matching jobs currently in LSF?
inflight_count() {
  # bjobs -noheader wraps EXEC_HOST onto continuation lines for multi-slot
  # jobs (our -n 4 jobs get one line per host), which inflates a raw
  # `wc -l` count. Count unique job IDs instead.
  bjobs -noheader -o "jobid" 2>/dev/null | sort -u | wc -l | tr -d ' '
}

submitted=0
skipped=0
total=0

while IFS= read -r URL; do
  # skip blanks/comments
  [[ -z "${URL// }" ]] && continue
  [[ "$URL" =~ ^# ]] && continue
  total=$((total + 1))

  # parse species + accession from URL
  species="$(echo "$URL" | awk -F'/' '{print $(NF-1)}')"
  file="$(basename "$URL")"
  acc="${file%.repeatmodeler.fa}"

  root="${REPO_ROOT}/data/${species}/${acc}"
  # Strong "done" check: classified output exists
  classified="${root}/input/${acc}.repeatmodeler.fa.classified"

  if [[ -s "$classified" ]]; then
    echo "[skip] ${species}/${acc} (classified exists)"
    skipped=$((skipped + 1))
    continue
  fi


  # throttle submission count to avoid dumping 500 jobs instantly
  while true; do
    inflight="$(inflight_count)"
    if [[ "$inflight" -lt "$MAX_INFLIGHT" ]]; then
      break
    fi
    echo "[throttle] inflight=${inflight} >= ${MAX_INFLIGHT}; sleeping ${SLEEP_SEC}s"
    sleep "$SLEEP_SEC"
  done

  jobname="rmclass_${species}_${acc}"
  # LSF job names have length limits; keep it short-ish
  jobname="${jobname:0:120}"

  # -n 20 -q normal -R"span[hosts=1] select[mem>${mbMem}] rusage[mem=${mbMem}]" -M${mbMem} -o ./logs/${spp}.out -e ./logs/${spp}.err
  echo "[submit] $jobname  $URL"
  bsub -q "$QUEUE" \
    -J "$jobname" \
    -n "$CORES" -M "$MEM_MB" \
    -R "span[hosts=1] select[mem>${MEM_MB}] rusage[mem=${MEM_MB}]" \
    -o "${REPO_ROOT}/lsf/out/%J.out" \
    -e "${REPO_ROOT}/lsf/err/%J.err" \
    "bash '${RUN_ONE}' '${URL}'"

  submitted=$((submitted + 1))
done < "$LIST"

echo
echo "Total URLs read:   $total"
echo "Submitted:         $submitted"
echo "Skipped (done):    $skipped"
echo "LSF logs:          lsf/out and lsf/err"
