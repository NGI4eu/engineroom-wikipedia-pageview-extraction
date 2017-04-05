#!/usr/bin/env bash
SOURCED=false && [ "$0" = "$BASH_SOURCE" ] || SOURCED=true

# get script path
# See:
# https://stackoverflow.com/questions/630372
SCRIPT_PATH="$( cd "$(dirname "$0")" && pwd )"

read -d '' docstring <<EOF
Usage:
  extract_all.sh [options] -f INFILE -y YEARMONTH -g GZDIR
  extract_all.sh ( -h | --help )
  extract_all.sh ( --version )

  Options:
    -d, --debug                 Enable debug mode (implies --verbose).
    --datadir DATADIR           Data directory [default: ./data]
    -o, --outputdir OUTPUTDIR   Output directory [default: ./output]
    -g, --gzdir gzdir           Directory with the .gz files.
    -i, --indexdir INDEXDIR     Index directory [default: ./indexes].
    -f, --file INFILE           File with the list of titles to search.
    -y, --yearmonth YEARMONTH   Year and month to analyze, in the format
                                YYYY-MM
    -l, --lang LANG             Language [default: en]
    -n, --dry-run               Dry run, only show the commands to be executed.
    -h, --help                  Show this help message and exits.
    --version                   Print version and copyright information.
----
extract_all.sh 0.1.0
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

YEARS=( $(seq 2007 2016) )
MONTHS=( $(seq -w 1 01 12) )

for year in "${YEARS[@]}"; do
  for month in "${MONTHS[@]}"; do
    echo "${year}-${month}"
      # ./scripts/extract_data.sh -d \
      #     -f ./output/en/Zika_virus.quoted-redirects.txt \
      #     -y "${year}-${month}" \
      #     -g /mnt/fluiddata/cconsonni/pagecounts/data/output
  done
done
