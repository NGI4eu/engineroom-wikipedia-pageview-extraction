#!/usr/bin/env bash
SOURCED=false && [ "$0" = "$BASH_SOURCE" ] || SOURCED=true

# get script path
# See:
# https://stackoverflow.com/questions/630372
SCRIPT_PATH="$( cd "$(dirname "$0")" && pwd )"

infile=''
yearmonth=''
gzdir=''
read -d '' docstring <<EOF
Usage:
  copy_pageview_files.sh [options] <infile> <yearmonth> <gzdir>
  copy_pageview_files.sh ( -h | --help )
  copy_pageview_files.sh ( --version )

  Options:
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

if $debug; then
  echodebug "--- ARGUMENTS ---"
  echodebug "infile: $infile"
  echodebug "yearmonth: $yearmonth"
  echodebug "gzdir: $gzdir"
  echodebug
  echodebug "debug (-d): $debug"
  echodebug "---"
fi

# cat ./output/en/Zika_virus.quoted-redirects.txt | \
#    parallel ./scripts/select_pageviews.sh --output-length 5 -l 'en' -i 2016-04_index "{}" | \
#    sort | uniq  | \
#    parallel cp /mnt/fluiddata/cconsonni/pagecounts/data/output/2016-04/{} ./data/2016-04/
# shellcheck disable=SC2002
cat "${infile}" | \
  parallel ./scripts/select_pageviews.sh --output-length 5 -l 'en' -i "${yearmonth}_index" "{}" | \
  sort | \
  uniq | \
  while read -r gz_file; do
  	find "${gzdir}" -maxdepth 2 -type f -name "${gz_file}"
 done > "${tmpdir}/gz_files_to_copy.txt"

mkdir -p "./data/${yearmonth}/"

# shellcheck disable=SC2002
cat "${tmpdir}/gz_files_to_copy.txt" | \
   parallel cp "{}" "./data/${yearmonth}/"
