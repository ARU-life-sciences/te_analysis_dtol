# This is for the data from https://projects.ensembl.org/darwin-tree-of-life/
# 
# 1) build a taxa file (strip path + extension, convert _ -> space)
for f in ../data/*; do
  b=$(basename "$f")
  b=${b%.*}
  printf '%s\n' "${b//_/ }"
done > taxa.txt

# 2) query GoaT in one go; ranks up to "class" gives: superkingdom..class columns
goat-cli taxon search -f taxa.txt -R class --size 500 > taxa_class.tsv


# this is for the data from https://ftp.ebi.ac.uk/pub/databases/ensembl/repeats/unfiltered_repeatmodeler/species/
# I.e. all unflitered repeatmodeler content out there, on ebi
# curl https://ftp.ebi.ac.uk/pub/databases/ensembl/repeats/unfiltered_repeatmodeler/species/c \
#   | awk -F"href" '{print $2}' \
#   | cut -d/ -f1 \
#   | cut -d'"' -f2 > taxa_ebi.txt

# # split and sanitise
# split -l 500 -d -a 3 taxa_ebi.txt taxa_ebi
# # sanitise the files, no blank lines, no numbers
# for chunk in taxa_ebi*; do
#   sed -i '/^$/d' "$chunk"
#   sed -i '/^[0-9]/d' "$chunk"
#   # and also lines with periods in them
#   sed -i '/\./d' "$chunk"
#   # and also any lines not starting with a letter
#   sed -i '/^[^A-Za-z]/d' "$chunk"
#   # and replace all underscores with spaces
#   sed -i 's/_/ /g' "$chunk"
# done

# for chunk in taxa_ebi*; do
#   # wait a couple of seconds to avoid overloading the server
#   sleep 2
#   goat-cli taxon search -f "$chunk" -R family --size 500
# done > taxa_class_ebi.tsv

# inspect the output, get 10 species per plant family or something?
# the data can then be downloaded from the same site:
# https://ftp.ebi.ac.uk/pub/databases/ensembl/repeats/unfiltered_repeatmodeler/species/
# and classified with RepeatClassifier
#
# I think the output should be kept separate from the DToL ones, perhaps in a separate data dir
