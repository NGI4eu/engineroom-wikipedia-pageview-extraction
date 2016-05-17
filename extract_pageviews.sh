#!/usr/bin/env bash
eval "$(docopts -V - -h - : "$@" <<EOF
Usage: extract_pageviews.sh [options] TITLE

      -d, --debug                  Enable debug mode (implies --verbose).
      --data-folder DATA_DIR       Data directory [default: ./data]
      -i INDEX                     Index file [default: ./input/index]
      -l LANGUAGE                  Language code [default: en].
      -n NCHAR                     Use as substring of lenght NCHAR for matching.
                                   [default: 2]
      -o OUTPUT_DIR                Output directory [default: ./output].
      -v, --verbose                Verbose mode.
      -h, --help                   Show this help message and exits.
      --version                    Print version and copyright information.
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

INDEX=$i
LANGUAGE=$l
NCHAR=$n
OUTPUT_DIR=$o
DATA_DIR=$data_folder
PAGEVIEW_DIR="$DATA_DIR/pageviews"

if $debug; then
    echo -e "--- ARGUMENTS ---"
    echo -e
    echo -e "TITLE: $TITLE"
    echo -e
    echo -e "debug (-d): $debug"
    echo -e "DATA_DIR (-data-folder): $DATA_DIR"
    echo -e "PAGEVIEW_DIR: (--pageview_folder): $PAGEVIEW_DIR"
    echo -e "LANGUAGE (-l): $LANGUAGE"
    echo -e "INDEX (-i): $INDEX"
    echo -e "NCHAR (-n): $NCHAR"
    echo -e "OUTPUT_DIR (-o): $OUTPUT_DIR"
    echo -e "verbose (-v): $verbose"
    echo -e "---"
fi

# create output directory
mkdir -p "./$OUTPUT_DIR/$LANGUAGE/"
mkdir -p "./$DATA_DIR/part_data/"

# 1. Check if there is a page with title TITLE on Wikipedia.
#    If it is a redirect use the page towards which it is redirected

if $debug; then
    echo -e "--- # 1. Check if there is a page with title ${TITLE} on Wikipedia ---"
fi
# Normalize TITLE
UNNORMALIZED_TITLE=$TITLE
TITLE=$( ./normalize_title.sh $TITLE)
QUOTED_TITLE=$(./quote_pagetitle.sh ${TITLE//_/ })
UNDERSCORE_TITLE="${TITLE// /_}"

# 2. get redirects
# get_redirects -l $LANGUAGE -o $OUTPUT_DIR TITLE
#    and save them in a file named ./(output)/{lang}/{title}.redirects.txt
if $debug; then
    echo -e "TITLE: $TITLE"
    echo -e "UNNORMALIZED_TITLE: $UNNORMALIZED_TITLE"
    echo -e "QUOTED_TITLE: $QUOTED_TITLE"
    echo -e "UNDERSCORE_TITLE: $UNDERSCORE_TITLE"
fi

if $debug; then
    echo -e "--- # 2. get redirects ---"
fi
REDIRECTS_FILE="${OUTPUT_DIR}/${LANGUAGE}/${UNDERSCORE_TITLE}.redirects.txt"
./get_redirects.sh -l "$LANGUAGE" "$TITLE" > "$REDIRECTS_FILE"

# 3. quote page and redirect titles and save everything in a file called:
#    ./{output}/{lang}/{title}.quoted-redirects.txt
if $debug; then
    echo -e "--- # 3. quote page and redirect titles ---"
fi
QUOTED_REDIRECTS="${OUTPUT_DIR}/${LANGUAGE}/${UNDERSCORE_TITLE}.quoted-redirects.txt"
cat "$REDIRECTS_FILE" | \
      parallel ./quote_pagetitle.sh {} | \
      sort | \
      uniq > "$QUOTED_REDIRECTS"

# 4. get the pageview data this will save a bunch of files in
#    ./data/part_data/part-XXXXXX.gz
if $debug; then
    echo -e "--- # 4. get the pageview data ---"
fi
cat "$QUOTED_REDIRECTS" | \
        parallel ./select_pageviews.sh -i "$INDEX" -l "$LANGUAGE" -n "$NCHAR" "{}" | \
        sort | \
        uniq  | \
        parallel cp "$PAGEVIEW_DIR/{}" "$DATA_DIR/part_data/"

# 5. change the permissions on files in ./data/part_data/
if $debug; then
    echo -e "--- # 5. change the permissions ---"
fi
find "$DATA_DIR/part_data/" -name '*.gz' | parallel chmod -R a-x  "{}"
find "$DATA_DIR/part_data/" -name '*.gz' | parallel chmod -R u+rw "{}"

# 6. Extract the pageview data
if $debug; then
    echo -e "--- # 6. Extract the pageview data ---"
    echo -e "--- #   a. extract clean pageviews ---"
fi
#    a. extract the pageviews only for the page named TITLE
#       and save them in ./{output}/{lang}/{title}.clean.pageviews.txt.gz
CLEAN_PAGEVIEWS="${OUTPUT_DIR}/${LANGUAGE}/${UNDERSCORE_TITLE}.clean.pageviews.txt.gz"
find "$DATA_DIR/part_data/" -name '*.gz' | \
    parallel  zgrep -E "\" $QUOTED_TITLE \"" "{}" | \
    gzip > "$CLEAN_PAGEVIEWS" || true

#    b. extract the pageviews only for the page named TITLE
#       and save them in
#       ./{output}/{lang}/{title}.quoted-redirects.pageviews.txt.gz
if $debug; then
    echo -e "--- #   b. extract redirects pageviews ---"
fi
REDIRECT_PAGEVIEWS="./${OUTPUT_DIR}/${LANGUAGE}/${UNDERSCORE_TITLE}.quoted-redirects.pageviews.txt.gz"
find "$DATA_DIR/part_data/" -name '*.gz' | \
    parallel zgrep -E -f "$QUOTED_REDIRECTS" "{}" | \
    gzip > "$REDIRECT_PAGEVIEWS" || true

if $debug; then
    echo -e "--- # done ---"
fi
