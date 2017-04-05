#!/usr/bin/env bash
SOURCED=false && [ "$0" = "$BASH_SOURCE" ] || SOURCED=true

# get script path
# See:
# https://stackoverflow.com/questions/630372
SCRIPT_PATH="$( cd "$(dirname "$0")" && pwd )"

file=''
INFILE=''
gzdir=''
GZDIR=''
yearmonth=''
YEARMONTH=''
indexdir=''
debug=false
datadir=''
outputdir=''
lang=''
dry_run=''
read -d '' docstring <<EOF
Usage:
  copy_pageview_files.sh [options] -f INFILE -y YEARMONTH -g GZDIR
  copy_pageview_files.sh ( -h | --help )
  copy_pageview_files.sh ( --version )

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

tmpdir=$(mktemp -d -t tmp.extract_data.XXXXXXXXXX)
function finish {
  rm -rf "$tmpdir"
}
trap finish EXIT

#################### Utils
if $debug; then
  echodebug_skip_header=false
  echodebug() {
    local numargs="$#"

    if ! $echodebug_skip_header; then
      echo -en "[$(date '+%F_%k:%M:%S')][debug]\t"
    else
      echodebug_skip_header=false
    fi

    if [ "$numargs" -gt 1 ] && [[ "$1" =~ ^'-n'* ]]; then
      echodebug_skip_header=true
    fi
    echo "$@" 1>&2
  }
else
  echodebug() { true; }
fi


INFILE="$file"
GZDIR="$gzdir"
YEARMONTH="$yearmonth"

if $debug; then
  echodebug "--- ARGUMENTS ---"
  echodebug "INFILE: $INFILE"
  echodebug "GZDIR: $GZDIR"
  echodebug "YEARMONTH: $YEARMONTH"
  echodebug
  echodebug "indexdir (-i): $indexdir"
  echodebug "debug (-d): $debug"
  echodebug "datadir (--datadir): $datadir"
  echodebug "outputdir (-o): $outputdir"
  echodebug "lang (-l): $lang"

  echodebug "dry_run (-n): $dry_run"
  echodebug "---"
fi

# Extract estension and base filename
# See:
# http://stackoverflow.com/questions/965053
filename=$(basename "$INFILE")
pagename="${filename%.*}"
echodebug "pagename: $pagename"

containsElement () {
  local el
  for el in "${@:2}"; do [[ "$el" == "$1" ]] && return 0; done
  return 1
}

transfer_logfile="${SCRIPT_PATH}/extract_data.${pagename}.${yearmonth}.log"
write_log () {
    # write_log "201204" "download.start" 
    # echo "download.start" > "${scriptdir}/azure-transfer.201204.log"   
    echo "$1" >> "$transfer_logfile"   
}

transfer_log=('')
if [ -f "$transfer_logfile" ]; then
    transfer_log=($( cat "$transfer_logfile" ))
fi

wrap_run () {

    local cmd_name
    cmd_name="$1"
    shift

    local numargs="$#"
    local continue_opt=''

    if containsElement "$cmd_name.completed" "${transfer_log[@]}"; then
        echodebug "skipping (already done) ... "
        return 0;
    fi

    # if containsElement "$cmd_name.start" "${transfer_log[@]}"; then
    #     echoq -en "continuing ... "
    #     continue_opt="${continue_opts[$cmd_name]}"
    # else
    #     write_log "$cmd_name.start"
    # fi
    write_log "$cmd_name.start"

    local cmd=()
    for (( i=1; i<=numargs; i++ )); do
        cmd+=("$1")
        if [ "$i" -eq "2" ] && [ ! -z "$continue_opt" ]; then
            cmd+=("$continue_opt")
        fi
        shift
    done

    echodebug -ne "\t ---> "
    echodebug "${cmd[@]}"

    if $dry_run; then
        echodebug "(dry run)"
    else
        # "$@"
        "${cmd[@]}"
        echodebug "done"
    fi
    write_log "$cmd_name.completed"

}
####################

gzfile=$(find "${GZDIR}/${YEARMONTH}" \
              -maxdepth 2 -type f \
              -name '*.gz' \
              -print -quit )
gzdir_yearmonth=$(dirname "${gzfile}")

indexfile="${indexdir}/${yearmonth}_index"

echodebug -ne "  * Build index for ${yearmonth} \t\t ... "
wrap_run "build_index" "$SCRIPT_PATH/build_index.sh" -d \
                          -o "${indexfile}" \
                          "${gzdir_yearmonth}"

echodebug -ne "  * Copy data files \t\t ... "
wrap_run "copy_files" "$SCRIPT_PATH/copy_pageview_files.sh" \
                          -f "$INFILE" \
                          -i "${indexfile}" \
                          -g "${GZDIR}/${YEARMONTH}"

echodebug -ne "  * Extract data \t\t ... "
outputfile="${outputdir}/$lang/${pagename}.pageviews.${yearmonth}.txt.gz"
# zgrep -E -f ./output/en/Zika_virus.quoted-redirects.txt \
#             ./data/2016-05/part* | \
#   gzip > ./output/en/Zika_virus.quoted-redirects.pageviews.2016-05.txt.gz
wrap_run "extract" zgrep -E -f "$INFILE" "${datadir}/${yearmonth}/"part* | gzip > "${outputfile}"

