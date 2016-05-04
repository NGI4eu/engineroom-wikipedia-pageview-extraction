#!/usr/bin/env bash
eval "$(docopts -V - -h - : "$@" <<EOF
Usage: select_pageviews.sh [options] -l LANGUAGE WORD ...

      -d, --debug          Enable debug mode (implies --verbose).
      -i INDEX             Index file [default: index]
      -l LANGUAGE          Language code to search.
      -n NCHAR             Use as substring of lenght NCHAR for matching.
                           [default: 2]
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

compute_upper () {
    local word=$1

    local upper_limit=$(echo "${word:0:$NCHAR}" | perl -nle 'print ++$_')

    local upper_isvalid=$(echo true | awk "\"$word\" < \"$upper_limit\" {print \$0}")
    [[ -z $upper_isvalid ]] && upper_isvalid=false

    local nchar=$((10#$NCHAR))
    while ! $upper_isvalid; do
        nchar=$((nchar - 1))
        upper_limit=$(echo "${word:0:$nchar}" | perl -nle 'print ++$_')

        upper_isvalid=$(echo true | awk "\"$word\" < \"$upper_limit\" {print \$0}")
        [[ -z $upper_isvalid ]] && upper_isvalid=false
    done

    echo "$upper_limit"
}


# --debug imples --vebose
if $debug; then verbose=true; fi

INDEX=$i
LANGUAGE=$l
NCHAR=$n

if $debug; then
    echo "--- ARGUMENTS ---"
    echo "WORDS: "
    for word in "${WORD[@]}"; do
        echo "  * $word"
    done
    echo
    echo "debug (-d): $debug"
    echo "INDEX (-i): $INDEX"
    echo "LANGUAGE (-l): $LANGUAGE"
    echo "NCHAR (-n): $NCHAR"
    echo "verbose (-v): $verbose"
    echo "---"
fi

# https://stackoverflow.com/questions/12487424/
#     uppercase-first-character-in-a-variable-with-bash

# echo "$a" | tr '[:upper:]' '[:lower:]'
# echo "Eb" | perl -nle 'print --$_

for word in "${WORD[@]}"; do
    if $verbose; then
        echo "--- $word ---"
    fi

    upper=$(compute_upper $word)
    if $debug; then
        echo "  * upper_limit: $upper"
    fi

    result=$(grep -i ".gz $LANGUAGE " $INDEX | \
             awk "\$3 >= \"$word\" && \$3 < \"$upper\" {print \$0}")
    fno=$(echo $result | \
          awk '{print $1}' | \
          awk -F'-' '{print $2}' | \
          tr -d '.gz' | 
          awk '{printf "%d\n",$0;}')
    fileno=$((10#$fno))

    # print results
    printf "part-%010d.gz\n" $((fileno - 1))
    printf "part-%010d.gz\n" $((fileno))

    if $verbose; then
        echo "---"
    fi
done
