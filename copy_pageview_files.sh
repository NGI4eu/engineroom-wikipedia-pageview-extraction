#!/usr/bin/env bash
SOURCED=false && [ "$0" = "$BASH_SOURCE" ] || SOURCED=true

debug=false
index=''
file=''
gzdir=''
INFILE=''
INDEX=''
GZDIR=''
read -d '' docstring <<EOF
Usage:
  copy_pageview_files.sh [options] -f INFILE -i INDEX -g GZDIR
  copy_pageview_files.sh ( -h | --help )
  copy_pageview_files.sh ( --version )

  Options:
    -g, --gzdir GZDIR    Directory with the .gz files.
    -i, --index INDEX    Index file.
    -f, --file INFILE    File with the list of titles to search.
    -d, --debug          Enable debug mode (implies --verbose).
    -h, --help           Show this help message and exits.
    --version            Print version and copyright information.
----
copy_pageview_files.sh 0.1.0
copyright (c) 2017 Cristian Consonni
MIT License
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
EOF

eval "$(echo "$docstring" | docopts -V - -h - : "$@" )"

# Bash strict mode
# See:
# https://balist.es/blog/2017/03/21/
#     enhancing-the-unofficial-bash-strict-mode/ 
if ! $SOURCED; then
  set -euo pipefail
  IFS=$'\n\t'
fi

tmpdir=$(mktemp -d -t tmp.copy_pageview_files.XXXXXXXXXX)
function finish {
  rm -rf "$tmpdir"
}
trap finish EXIT

#################### Utils
if $debug; then
  echodebug() {
    echo -en "[$(date '+%F_%k:%M:%S')][debug]\t"
    echo "$@" 1>&2
  }
else
  echodebug() { true; }
fi

INDEX="$index"
INFILE="$file"
GZDIR="$gzdir"

if $debug; then
  echodebug "--- ARGUMENTS ---"
  echodebug "INDEX: $INDEX"
  echodebug "INFILE: $INFILE"
  echodebug "GZDIR: $GZDIR"
  echodebug
  echodebug "debug (-d): $debug"
  echodebug "---"
fi


yearmonth="$(basename "$INDEX" | cut -c1-7)"
echodebug "yearmonth: $yearmonth"

# cat ./output/en/Zika_virus.quoted-redirects.txt | \
#    parallel ./scripts/select_pageviews.sh --output-length 5 -l 'en' -i 2016-04_index "{}" | \
#    sort | uniq  | \
#    parallel cp /mnt/fluiddata/cconsonni/pagecounts/data/output/2016-04/{} ./data/2016-04/
# shellcheck disable=SC2002
cat "${INFILE}" | \
  parallel ./scripts/select_pageviews.sh --output-length 5 -l 'en' -i "$INDEX" "{}" | \
  sort | \
  uniq | \
  while read -r gz_file; do
    find "${GZDIR}" -maxdepth 2 -type f -name "${gz_file}"
 done > "${tmpdir}/gz_files_to_copy.txt"

mkdir -p "./data/${yearmonth}/"

# shellcheck disable=SC2002
cat "${tmpdir}/gz_files_to_copy.txt" | \
   parallel cp "{}" "./data/${yearmonth}/"
