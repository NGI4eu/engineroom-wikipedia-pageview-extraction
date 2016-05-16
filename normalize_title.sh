#!/usr/bin/env bash
eval "$(docopts -V - -h - : "$@" <<EOF
Usage: normalize_title.sh [options] TITLE

      -d, --debug                       Enable debug mode (implies --verbose).
      -l LANGUAGE                       Language code [default: en].
      -v, --verbose                     Verbose mode.
      -h, --help                        Show this help message and exits.
      --version                         Print version and copyright information.
----
normalize_title.sh 0.1.0
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

# --debug imples --vebose
if $debug; then verbose=true; fi

LANGUAGE=$l

if $debug; then
    echo -e "--- ARGUMENTS ---"
    echo -e
    echo -e "TITLE: $TITLE"
    echo -e
    echo -e "debug (-d): $debug"
    echo -e "LANGUAGE (-l): $LANGUAGE"
    echo -e "verbose (-v): $verbose"
    echo -e "---"
fi

baseurl="https://${LANGUAGE}.wikipedia.org/w/api.php"

tmptrim="${TITLE%\"}"
tmptrim="${tmptrim#\"}"
utitle=${tmptrim// /_}

request_url="${baseurl}?action=query&titles=${utitle}&redirects&format=json"
response=$(curl -q -s $request_url)

exists=$(echo $response | jq '.query.pages | .[].pageid ' | tr -d '"')

if [[ $exists == 'null' ]]; then
    echo -e "No such title on ${LANGUAGE}wiki: ${TITLE}"
    exit 1
else

    redirect_to=$(echo $response | jq '.query.redirects[0].to' | tr -d '"')
    normalized_to=$(echo $response | jq '.query.normalized[0].to' | tr -d '"')

    if $verbose; then
        echo -e "exists: $exists"
        echo -e "normalized_to: $normalized_to"
        echo -e "redirect_to: $redirect_to"
    fi

    if [[ $redirect_to == 'null' ]]; then

        if [[ $normalized_to == 'null' ]]; then
            echo ${utitle//_/ }
        else
            echo $normalized_to
        fi

    else
        echo $redirect_to
    fi
fi
