#!/usr/bin/env bash
set -euo pipefail

URL="${1:?Usage: run_repeatmasker_one.sh <repeatmodeler.fa URL>}"

REPEATMASKER="${REPEATMASKER:-/software/team301/repeat-annotation/RepeatMasker/RepeatMasker}"
CORES="${CORES:-4}"

species_slug="$(echo "$URL" | awk -F'/' '{print $(NF-1)}')"
species_name="$(
  echo "$species_slug" |
  awk -F'_' '{printf toupper(substr($1,1,1)) substr($1,2); for (i=2;i<=NF;i++) printf " " $i; print ""}'
)"

file="$(basename "$URL")"
acc="${file%.repeatmodeler.fa}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
root="${REPO_ROOT}/data/${species_slug}/${acc}"

classified="${root}/input/${acc}.repeatmodeler.fa.classified"
outdir="${root}/results/repeatmasker"
staged="${root}/input/${acc}.genome.fasta"

mkdir -p "$outdir" "${root}/logs"

if [[ ! -s "$classified" ]]; then
    echo "[error] missing classified library: $classified" >&2
    exit 1
fi

if compgen -G "${outdir}"/*.out >/dev/null; then
    echo "[skip] RepeatMasker output already exists"
    exit 0
fi

if [[ -s "$staged" ]]; then
    echo "[genome]  $staged (already staged)"
else
    module load speciesops >/dev/null 2>&1 || true

    echo "[speciesops] $species_name"

    # speciesops (rich/click) wraps stdout to 80 columns when it isn't a
    # TTY, which pushes the path in "Species directory path: <path>" onto
    # its own line for longer species names and breaks a same-line parse.
    # Force a wide width so the path never wraps.
    species_dir="$(
        COLUMNS=300 speciesops getdir --species_name "$species_name" 2>/dev/null |
        awk -F': ' '/Species directory path:/ {print $2}'
    )"

    if [[ -z "${species_dir:-}" || ! -d "$species_dir" ]]; then
        echo "[error] could not resolve species directory for: $species_name" >&2
        exit 1
    fi

    asm_dir="${species_dir}/assembly/release/${acc}/insdc"

    echo "[species_dir] $species_dir"
    echo "[asm_dir]     $asm_dir"

    if [[ ! -d "$asm_dir" ]]; then
        echo "[error] missing assembly dir: $asm_dir" >&2
        exit 1
    fi

    genome_gz="${asm_dir}/${acc}.fasta.gz"

    if [[ ! -s "$genome_gz" ]]; then
        genome_gz="$(
            find "$asm_dir" -maxdepth 1 -type f \
                \( -name "*.fa.gz" -o -name "*.fasta.gz" \) |
                head -n 1
        )"
    fi

    if [[ -z "${genome_gz:-}" || ! -s "$genome_gz" ]]; then
        echo "[error] no genome FASTA.gz found in: $asm_dir" >&2
        exit 1
    fi

    echo "[stage] decompressing genome:"
    echo "        from: $genome_gz"
    echo "        to:   $staged"
    zcat "$genome_gz" > "$staged"

    echo "[genome]  $staged"
fi

echo "[library] $classified"
echo "[outdir]  $outdir"

# RepeatMasker always tries to create its RM_<pid>.<date> scratch dir in the
# process's cwd first (falling back to -dir only if that fails), regardless
# of -dir. Run from inside outdir so that scratch dir lands there too instead
# of littering the repo root, and gets cleaned up alongside real output.
pushd "$outdir" >/dev/null
"$REPEATMASKER" \
    -pa "$CORES" \
    -e rmblast \
    -gff \
    -xsmall \
    -lib "$classified" \
    -dir "$outdir" \
    "$staged"
popd >/dev/null

echo
echo "[done] ${species_slug}/${acc}"
