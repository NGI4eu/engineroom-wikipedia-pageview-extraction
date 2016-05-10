#!/usr/bin/env bash
eval "$(docopts -V - -h - : "$@" <<EOF
Usage: extract_pageviews.sh [options] TITLE

      -d, --debug                       Enable debug mode (implies --verbose).
      --data-folder DATA_DIR            Data directory [default: ./data]
      -l LANGUAGE                       Language code [default: en].
      -o OUTPUT_DIR                     Output directory [default: ./output].
      -v, --verbose                     Verbose mode.
      -h, --help                        Show this help message and exits.
      --version                         Print version and copyright information.
----
extract_pageviews.sh 0.1.0
copyright (c) 2016 Cristian Consonni
MIT License
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
EOF
)"

# Set "bash strict" mode
# See:
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

# Set cleanup exit trap
# See:
# http://redsymbol.net/articles/bash-exit-traps/
TEMPDIR=$(mktemp -d -t tmp.extract_pageviews.XXXXXXXXXX)
function finish {
    rm -rf "$TEMPDIR"
}
trap finish EXIT



##############################################################################
# WORKFLOW
#
# 1. Check if there is a page with title TITLE on Wikipedia.
#    If it is a redirect use the page towards which it is redirected
#
# 2. get the redirects for a page at:
#        http://dispenser.homenet.org/~dispenser/cgi-bin/rdcheck.py
#    and save them in a file named ./{output}/{lang}/{title}.redirects.txt
#
# 3. quote page and redirect titles and save everything in a file called:
#    ./{output}/{lang}/{title}.quoted-redirects.txt
#
# 4. get the pageview data this will save a bunch of files in
#    ./{data}/part_data/part-XXXXXX.gz
#
# 5. change the permissions on files in ./data/part_data/
#
# 6. Extract the pageview data
#    a. extract the pageviews only for the page named TITLE
#       and save them in ./{output}/{lang}/{title}.clean.pageviews.txt.gz
#    b. extract the pageviews only for the page named TITLE
#       and save them in
#       ./{output}/{lang}/{title}.quoted-redirects.pageviews.txt.gz
#
##############################################################################

# --debug imples --vebose
if $debug; then verbose=true; fi

LANGUAGE=$l
OUTPUT_DIR=$o
DATA_DIR=$data_folder
PAGEVIEW_DIR="$DATA_DIR/pageviews"

if $debug; then
    echo "--- ARGUMENTS ---"
    echo
    echo "TITLE: $TITLE"
    echo
    echo "debug (-d): $debug"
    echo "DATA_DIR (-data-folder): $DATA_DIR"
    echo "PAGEVIEW_DIR: (--pageview_folder): $PAGEVIEW_DIR"
    echo "LANGUAGE (-l): $LANGUAGE"
    echo "OUTPUT_DIR (-o): $OUTPUT_DIR"
    echo "verbose (-v): $verbose"
    echo "---"
fi

exit 0
# create output directory
mkdir -p "./$OUTPUT_DIR/$LANGUAGE/"
mkdir -p "./$DATA_DIR/part_data/"

# 1. Check if there is a page with title TITLE on Wikipedia.
#    If it is a redirect use the page towards which it is redirected

# Normalize TITLE
UNNORM_TITLE=$TITLE
# TITLE=normalize($TITLE)
QUOTED_TITLE=$(./quote_pagetitle.sh ${TITLE//_/ })

# 2. get redirects
# get_redirects -l LANG -o OUTPUT_DIR TITLE
#    and save them in a file named ./(output)/{lang}/{title}.redirects.txt
#
# get_redirects.sh > ./{OUTPUT_DIR}/{LANG}/{TITLE}.redirects.txt

# 3. quote page and redirect titles and save everything in a file called:
#    ./{output}/{lang}/{title}.quoted-redirects.txt
QUOTED_REDIRECTS="./$OUTPUT_DIR/$LANGUAGE/$TITLE.quoted-redirects.txt"

# Usage: quote_pagetitle.sh [options] WORD ...
#
#       -d, --debug          Enable debug mode (implies --verbose).
#       -v, --verbose        Print unified diff format (more verbose).
#       -h, --help           Show this help message and exits.
#       --version            Print version and copyright information.
cat "./$OUTPUT_DIR/$LANGUAGE/$TITLE.redirects.txt" | \
      parallel ./quote_pagetitle.sh {} | \
      sort | \
      uniq > "$QUOTED_REDIRECTS"

# 4. get the pageview data this will save a bunch of files in
#    ./data/part_data/part-XXXXXX.gz
cat "$QUOTED_REDIRECTS" |
        parallel ./select_pageviews.sh -l $LANGUAGE "{}" | \
        sort | \
        uniq  | \
        parallel cp "$PAGEVIEW_DIR/{}" "$DATA_DIR/part_data/"

# 5. change the permissions on files in ./data/part_data/
ls -1 "$DATA_DIR/part_data/" | grep gz | parallel chmod -R a-x "{}"
ls -1 "$DATA_DIR/part_data/" | grep gz | parallel chmod -R a-x "{}"

# 6. Extract the pageview data
#    a. extract the pageviews only for the page named TITLE
#       and save them in ./{output}/{lang}/{title}.clean.pageviews.txt.gz
ls -1 "$DATA_DIR/part_data/" | grep gz | \
    parallel  zgrep -E " $QUOTED_TITLE " "{}" | \
    gzip > "./$OUTPUT_DIR/$LANGUAGE/$TITLE.clean.pageviews.txt.gz"

#    b. extract the pageviews only for the page named TITLE
#       and save them in
#       ./{output}/{lang}/{title}.quoted-redirects.pageviews.txt.gz
ls -1 "$DATA_DIR/part_data/" | grep gz | \
    parallel zgrep -E -f "$QUOTED_REDIRECTS" "{}" | \
    gzip > "./$OUTPUT_DIR/$LANGUAGE/$TITLE.quoted-redirects.pageviews.txt.gz
