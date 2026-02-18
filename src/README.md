# Primary data for TE analysis

Collect the links first. We have two data sources, DToL and EBI. These are from two separate sites:

- https://ftp.ebi.ac.uk/pub/databases/ensembl/repeats/unfiltered_repeatmodeler/species/
- https://projects.ensembl.org/darwin-tree-of-life/

## Get all EBI data

```bash
# get all the ftps from the web
python scrape_all_ebi.py > repeatmodeler_links.tsv
# get the higher taxonomic groups
bash get_higher_ranks.sh
# TODO: filter on Viridiplantae, download all repeatmodeler output
# and run RepeatClassifier
```

## Get all DToL data

```bash
python scrape_ensembl_dtol.py > repeatmodeler_links_ensembl_dtol.tsv

```
