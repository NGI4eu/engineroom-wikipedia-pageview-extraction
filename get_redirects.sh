#!/usr/bin/env bash
debug=false
verbose=false
l=''
eval "$(docopts -V - -h - : "$@" <<EOF
Usage: get_redirects.sh [options] TITLE

      -d, --debug                       Enable debug mode (implies --verbose).
      -l LANGUAGE                       Language code [default: en].
      -v, --verbose                     Verbose mode.
      -h, --help                        Show this help message and exits.
      --version                         Print version and copyright information.
----
get_redirects.sh 0.1.0
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

# Set cleanup exit trap
# See:
# http://redsymbol.net/articles/bash-exit-traps/
TEMPDIR=$(mktemp -d -t tmp.get_redirects.XXXXXXXXXX)
function finish {
    rm -rf "$TEMPDIR"
}
trap finish EXIT

# --debug imples --vebose
if $debug; then verbose=true; fi

MAX_API_REQUESTS=10
LANGUAGE="$l"

if $debug; then
    echodebug "--- ARGUMENTS ---"
    echodebug
    echodebug "TITLE: $TITLE"
    echodebug
    echodebug "debug (-d): $debug"
    echodebug "LANGUAGE (-l): $LANGUAGE"
    echodebug "verbose (-v): $verbose"
    echodebug "---"
fi

baseurl="https://${LANGUAGE}.wikipedia.org/w/api.php"

# Normalize TITLE
UNNORMALIZED_TITLE="$TITLE"
TITLE=$( ./normalize_title.sh -l "$LANGUAGE" "$TITLE")
utitle=${TITLE// /_}

echodebug "utitle: $utitle"

echo "$UNNORMALIZED_TITLE" >> "$TEMPDIR/redirects.tmp"
echo "$TITLE" >> "$TEMPDIR/redirects.tmp"

declare -A params
declare -A lastContinue

params['format']='json'
params['action']='query'
params['utf8']='yes'
params['generator']='backlinks'
params['gblfilterredir']='redirects'
params['gblnamespace']='0'
params['gbllimit']='50'
params['gbltitle']="$utitle"
params['prop']='revisions'
params['rvprop']='content'

lastContinue['continue']=''

for i in $(seq 1 1 $MAX_API_REQUESTS); do
    if [[ -z "${lastContinue['continue']}" ]]; then
        if $debug; then echo -e "---$i---"; fi
        request_url=$(printf "${baseurl}?format=%s&action=%s&utf8=%s&generator=%s&gblfilterredir=%s&gblnamespace=%s&gbllimit=%s&gbltitle=%s&prop=%s&rvprop=%s"\
                             "${params['format']}"\
                             "${params['action']}"\
                             "${params['utf8']}"\
                             "${params['generator']}"\
                             "${params['gblfilterredir']}"\
                             "${params['gblnamespace']}"\
                             "${params['gbllimit']}"\
                             "${params['gbltitle']}"\
                             "${params['prop']}"\
                             "${params['rvprop']}")
    else
        if $debug; then echo -e "---$i---"; fi
        request_url=$(printf "${baseurl}?format=%s&action=%s&utf8=%s&generator=%s&gblfilterredir=%s&gblnamespace=%s&gbllimit=%s&gbltitle=%s&prop=%s&rvprop=%s&continue=%s&gblcontinue=%s"\
                             "${params['format']}"\
                             "${params['action']}"\
                             "${params['utf8']}"\
                             "${params['generator']}"\
                             "${params['gblfilterredir']}"\
                             "${params['gblnamespace']}"\
                             "${params['gbllimit']}"\
                             "${params['gbltitle']}"\
                             "${params['prop']}"\
                             "${params['rvprop']}"\
                             "${lastContinue['continue']}"\
                             "${lastContinue['gblcontinue']}")
    fi

    echodebug "$request_url"

    response=$(curl -q -s "$request_url")

    redirects_titles=$( echo "$response" | jq '.query.pages[].title')

    if [[ ! $redirects_titles == 'null' ]]; then
        echo "$response" \
            | jq -r '.query.pages[].title' >> "$TEMPDIR/redirects.tmp"
    else
        echo -e "Error in reading foo from bar"
        exit 1
    fi

    is_continuing=$( echo "$response" | jq '.continue')
    if [[ ! $is_continuing == 'null' ]]; then
        lastContinue['continue']=$(echo "$response" \
                                    | jq -r '.continue.continue')
        lastContinue['gblcontinue']=$(echo "$response" \
                                        | jq -r '.continue.gblcontinue')
    else
        break
    fi
    sleep 10
done

sort "$TEMPDIR/redirects.tmp" | uniq
exit 0
