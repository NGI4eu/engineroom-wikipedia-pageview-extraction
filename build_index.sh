#!/usr/bin/env bash

SOURCED=false && [ "$0" = "$BASH_SOURCE" ] || SOURCED=true

OUTPUT=''
o=''
DIRECTORY=''
debug=false
verbose=false

read -d '' docstring <<EOF
Usage:
  build_index.sh [options] -o OUTPUT DIRECTORY
  build_index.sh ( -h | --help )
  build_index.sh --version

  Options:
    -d, --debug          Enable debug mode (implies --verbose).
    -o OUTPUT            Output index filename
    -v, --verbose        Print unified diff format (more verbose).
    -h, --help           Show this help message and exits.
    --version            Print version and copyright information.
----
build_index.sh 0.1.0
copyright (c) 2016 Cristian Consonni
MIT License
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
EOF

eval "$(echo "$docstring" | docopts -V - -h - : "$@" )"

if ! $SOURCED; then
  set -euo pipefail
  IFS=$'\n\t'
fi

OUTPUT="$o"

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
####################

if $debug; then
  echodebug "--- ARGUMENTS ---"
  echodebug "DIRECTORY: $DIRECTORY"
  echodebug "output (-o): $OUTPUT"
  echodebug
  echodebug "debug (-d): $debug"
  echodebug "verbose (-v): $verbose"
  echodebug "---"
fi

logfile="${DIRECTORY}/build_index.log"
resultsdir="${DIRECTORY}/index"
if $debug; then
  echodebug "* logfile: $logfile"
  echodebug "* resultsdir: $resultsdir"
fi

set -x
find "$DIRECTORY" -maxdepth '1' -type 'f' -name '*.gz' -printf "%f\n" | \
  parallel \
    -j8 \
    --eta \
    --joblog "${logfile}.joblog" \
    --results "${resultsdir}" \
    "echo -n '{} '; zcat $DIRECTORY/{} | head -n 1" \
    1>/dev/null 2>>"${logfile}"

find "${resultsdir}" -type f -name 'stdout' -exec cat {} \; | \
  sort -k 1 -g > "${OUTPUT}"
