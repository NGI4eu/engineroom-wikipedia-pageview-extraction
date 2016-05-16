#!/usr/bin/env bash
eval "$(docopts -V - -h - : "$@" <<EOF
Usage: quote_pagetitle.sh [options] WORD ...

      -d, --debug          Enable debug mode (implies --verbose).
      -v, --verbose        Print unified diff format (more verbose).
      -h, --help           Show this help message and exits.
      --version            Print version and copyright information.
----
select_pageviews.sh 0.1.0
copyright (c) 2016 Cristian Consonni
MIT License
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
EOF
)"

set -euo pipefail
IFS=$'\n\t'

# --debug imples --vebose
if $debug; then verbose=true; fi

if $debug; then
    echo -e "--- ARGUMENTS ---"
    echo -e "WORDS: "
    for word in "${WORD[@]}"; do
        echo -e "  * $word"
    done
    echo -e
    echo -e "debug (-d): $debug"
    echo -e "verbose (-v): $verbose"
    echo -e "---"
fi

for word in "${WORD[@]}"; do
    if $verbose; then
        echo -e "--- $word ---"
    fi

    quoted_word=$(printf '%s' "$word" | sed 's/[.[\*^$()+?{|]/\\&/g')
    echo ${quoted_word// /( |_|%20)}

    if $verbose; then
        echo -e "---"
    fi
done
