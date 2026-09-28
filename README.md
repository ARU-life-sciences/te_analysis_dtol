# TE data across DToL public data

This repository contains RepeatModeler consensus repeat libraries for hundreds of species from the Darwin Tree of Life (DToL) / Ensembl repeats FTP.

These data are useful for exploring:

- transposable element (TE) diversity
- genome repeat composition
- comparative genomics across species

## Directory structure

```bash
# data for each species is in the `data` directory
data/<species>/<assembly_accession>/
# example
data/zygaena_filipendulae/GCA_907165275.1
```
Inside each assembly directory, this repo tracks two files:

| file | contents |
| ---- | -------- |
| `input/<assembly>.repeatmodeler.fa.classified` | RepeatModeler consensus repeat library, classified by RepeatClassifier |
| `results/repeatmasker/<assembly>.genome.fasta.tbl` | RepeatMasker summary table: % of the genome occupied by each repeat class |

The classified library is the "who's here" list — one consensus sequence per repeat family found in that genome. The `.tbl` is the "how much" summary — genome-wide totals per class (SINEs, LINEs, LTR elements, DNA transposons, etc.), already computed by running RepeatMasker against that species' own classified library.

(Larger intermediate files — staged genomes, raw unclassified consensus, per-base RepeatMasker `.out`/`.gff` annotations — aren't tracked here, since they're regenerable and too large for git. Ask if you need per-base coordinates for a distribution-style analysis; either exists on the group's cluster or can be regenerated from the files here.)

## What is a RepeatModeler consensus?

RepeatModeler identifies repeated DNA sequences in a genome and builds a consensus sequence for each repeat family.

Each FASTA entry represents one repeat family.

e.g.

```bash
>rnd-3_family-26#DNA/hAT
```

Meaning:

- rnd-3 -> discovery round in RepeatModeler
- family-26 -> family ID
- DNA/hAT -> inferred repeat class

If no class is known:

```bash
>rnd-6_family-991#Unknown
```

Later rounds often contain rarer or harder-to-classify repeats.

## Undergraduate project: investigating transposable elements

Transposable elements (TEs) are parasitic elements in the DNA of all living organisms which replicate in a host genome. Some are ancient, and in general very little is known about the TE landscape for almost all organisms. Using the genomes in this repository — Darwin Tree of Life plant species in particular — the aim is to help plug that knowledge gap.

A rough outline of how a project could go:

1. **Choose a group of organisms to work on.** The full DToL species list is [here](https://projects.ensembl.org/darwin-tree-of-life/) — but you don't need to go looking for RepeatModeler output yourself: every species under `data/` in this repo already has it, so pick your group from there. Aim for enough species for statistical power (>30ish).
2. **Get the classified libraries.** These are already in the repo — no need to request anything separately: `data/<species>/<assembly>/input/<assembly>.repeatmodeler.fa.classified`. Each FASTA header is crudely annotated with its inferred TE class (see above), so you can see what kinds of TE are present in each genome.
3. **Classify and compare diversity between groups**, e.g. by taxonomic order/family (see `src/taxa_class.tsv` for taxonomy + genome size/assembly metadata to join against). Roughly in order of difficulty:
   - **Easy** — pick one specific repeat class (e.g. LINEs) and compare its abundance/diversity across your chosen species. The `.tbl` summary files (`results/repeatmasker/<assembly>.genome.fasta.tbl`) already give you genome-wide % for each class, so this is mostly parsing + comparing.
   - **Harder** — look at total TE diversity (number of distinct families/classes, not just one) across your groups.
   - **Hard** — look at where these repeats are distributed across the chromosomes (needs per-base RepeatMasker coordinates, which aren't tracked in this repo due to size — ask if you need these for a species).

**Skills required:** strong computational skills (BASH/command line, R).
