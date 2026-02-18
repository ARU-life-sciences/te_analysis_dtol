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
Inside each assembly directory:

| folder     | contents                                        |
| ---------- | ----------------------------------------------- |
| `input/`   | original RepeatModeler FASTA + classified FASTA |
| `logs/`    | RepeatClassifier logs                           |
| `results/` | processed outputs                               |
| `work/`    | temporary working files                         |

The most important file is:

```bash
input/<assembly>.repeatmodeler.fa.classified
```

This contains consensus repeat sequences with annotations where possible.

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
