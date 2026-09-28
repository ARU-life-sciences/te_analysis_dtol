#!/usr/bin/env bash
set -euo pipefail

LIST="${1:-src/repeatmodeler_links_ensembl_dtol.tsv}"

QUEUE="${QUEUE:-basement}"
CORES="${CORES:-4}"
MEM_MB="${MEM_MB:-24000}"
MEM_PER_GB_MB="${MEM_PER_GB_MB:-20000}"
MEM_CAP_MB="${MEM_CAP_MB:-200000}"
MAX_INFLIGHT="${MAX_INFLIGHT:-100}"
SLEEP_SEC="${SLEEP_SEC:-30}"

REPO_ROOT="/lustre/scratch122/tol/teams/blaxter/users/mb39/repeatmodeler_ensembl"
RUN_ONE="${REPO_ROOT}/src/run_repeatmasker_one.sh"

mkdir -p "${REPO_ROOT}/lsf/out" "${REPO_ROOT}/lsf/err"

inflight_count() {
  # bjobs -noheader wraps EXEC_HOST onto continuation lines for multi-slot
  # jobs (our -n 4 jobs get one line per host), which inflates a raw
  # `wc -l` count. Count unique job IDs instead.
  bjobs -noheader -o "jobid" 2>/dev/null | sort -u | wc -l | tr -d ' '
}

job_in_flight() {
  bjobs -w -J "$1" 2>/dev/null | awk 'NR>1 {print $3}' | grep -qE '^(RUN|PEND)$'
}

# 24000MB is fine for most (mostly insect) genomes, but a handful of large
# vertebrate genomes (Bufo bufo, Canis lupus, Cervus elaphus, ...) need far
# more and were previously getting killed by LSF at that flat ceiling after
# 1-2 days of runtime. Once a genome has been staged once (including by a
# prior OOM-killed attempt), size memory off its real footprint instead.
mem_for_species() {
  local staged="$1"
  if [[ -s "$staged" ]]; then
    stat -c%s "$staged" | awk -v per_gb="$MEM_PER_GB_MB" -v floor="$MEM_MB" -v cap="$MEM_CAP_MB" '
      { mem = ($1 / 1e9) * per_gb + 2000
        if (mem < floor) mem = floor
        if (mem > cap) mem = cap
        printf "%d", mem }'
  else
    echo "$MEM_MB"
  fi
}

submitted=0
skipped=0
missing=0
running=0
total=0

while IFS= read -r URL; do
  [[ -z "${URL// }" ]] && continue
  [[ "$URL" =~ ^# ]] && continue
  total=$((total + 1))

  species="$(echo "$URL" | awk -F'/' '{print $(NF-1)}')"
  file="$(basename "$URL")"
  acc="${file%.repeatmodeler.fa}"

  root="${REPO_ROOT}/data/${species}/${acc}"
  classified="${root}/input/${acc}.repeatmodeler.fa.classified"
  outdir="${root}/results/repeatmasker"
  staged="${root}/input/${acc}.genome.fasta"

  if [[ ! -s "$classified" ]]; then
    echo "[missing] ${species}/${acc} classified library absent"
    missing=$((missing + 1))
    continue
  fi

  if compgen -G "${outdir}"/*.out >/dev/null 2>&1; then
    echo "[skip] ${species}/${acc} RepeatMasker output exists"
    skipped=$((skipped + 1))
    continue
  fi

  jobname="rmask_${species}_${acc}"
  jobname="${jobname:0:120}"

  if job_in_flight "$jobname"; then
    echo "[skip] ${species}/${acc} already RUN/PEND as ${jobname}"
    running=$((running + 1))
    continue
  fi

  while true; do
    inflight="$(inflight_count)"
    if [[ "$inflight" -lt "$MAX_INFLIGHT" ]]; then
      break
    fi
    echo "[throttle] inflight=${inflight} >= ${MAX_INFLIGHT}; sleeping ${SLEEP_SEC}s"
    sleep "$SLEEP_SEC"
  done

  mem_mb="$(mem_for_species "$staged")"

  echo "[submit] $jobname (mem=${mem_mb}MB)"
  bsub -q "$QUEUE" \
    -J "$jobname" \
    -n "$CORES" -M "$mem_mb" \
    -R "span[hosts=1] select[mem>${mem_mb}] rusage[mem=${mem_mb}]" \
    -o "${REPO_ROOT}/lsf/out/%J.repeatmasker.out" \
    -e "${REPO_ROOT}/lsf/err/%J.repeatmasker.err" \
    "CORES=${CORES} bash '${RUN_ONE}' '${URL}'"

  submitted=$((submitted + 1))
done < "$LIST"

echo
echo "Total URLs read:         $total"
echo "Submitted:               $submitted"
echo "Skipped existing RM:     $skipped"
echo "Skipped already running: $running"
echo "Missing classified:      $missing"
echo "LSF logs:                lsf/out and lsf/err"
