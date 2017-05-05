#!/usr/bin/env bash
SOURCED=false && [ "$0" = "$BASH_SOURCE" ] || SOURCED=true

# Bash strict mode
# See:
# https://balist.es/blog/2017/03/21/
#     enhancing-the-unofficial-bash-strict-mode/ 
if ! $SOURCED; then
  set -euo pipefail
  IFS=$'\n\t'
fi

# How to trim whitespace from a Bash variable?
# http://stackoverflow.com/questions/369758
trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"   
    echo -n "$var"
}

while IFS='' read -r line || [[ -n "$line" ]]; do
    datafile=$(echo "$line" | awk -F':' '{print $1}' )
    lang=$(trim "$(echo "$line" | awk -F':' '{$1=""; print $0}')" | \
    	   awk '{print $1}')
    ts=$(trim "$(echo "$line" | awk '{print $(NF-2)}')")
    visit=$(trim "$(echo "$line" | awk '{print $(NF-1)}')")
    bytes=$(trim "$(echo "$line" | awk '{print $NF}')")

    page=$(trim "$(echo "$line" | awk '{$1="";$NF="";$(NF-1)="";$(NF-2)="";print $0}')")

    # echo "datafile: $datafile"
    # echo "lang: $lang"
    # echo "page: $page"
    # echo "ts: $ts"
    # echo "visit: $visit"
    # echo "bytes: $bytes"
    echo "$datafile;$lang;$page;$ts;$visit;$bytes"
done < "$1"