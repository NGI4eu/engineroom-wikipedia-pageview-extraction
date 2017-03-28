#!/usr/bin/env bash
debug=false
output_length=0
i=''
l=''
n=''
declare -a WORD
eval "$(docopts -V - -h - : "$@" <<EOF
Usage:
  select_pageviews.sh [options] -l LANGUAGE WORD ...

  Options:
    -d, --debug          Enable debug mode (implies --verbose).
    -i INDEX             Index file [default: index]
    -l LANGUAGE          Language code to search.
    -n NCHAR             Use as substring of lenght NCHAR for matching.
                         [default: 2]
    --output-length N    Filename number field length [default: 10]
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

#################### Utils
if $debug; then
  echodebug() {
    echo -en "[$(date '+%F_%k:%M:%S')][debug]\t"
    echo "$@" 1>&2
  }
else
  echodebug() { true; }
fi

if $verbose; then
  echoverbose() {
    echo -en "[$(date '+%F_%k:%M:%S')][info]\t"
    echo "$@" 1>&2;
  }
else
  echoverbose() { true; }
fi

####################
# Trim whitespace from a Bash variable
# See:
#   http://stackoverflow.com/questions/369758
trim () {
  local var
  var="$1"

  # remove leading whitespace characters
  var="${var#\"${var%%[![:space:]]*}\"}"

  # remove trailing whitespace characters
  var="${var%\"${var##*[![:space:]]}\"}"

  echo -n "$var"
}

# Bash script to get ASCII values for alphabet
# See:
#   http://unix.stackexchange.com/questions/92447
chr() {
  local var
  [ "$1" -lt 256 ] || exit 1
  var=$(printf "\\$(printf '%03o' "$1")")
  var=$(trim "$var")

  echo -n "$var"
}

ord() {
  LC_CTYPE=C printf '%d' "'$1"
}

compute_upper_limit () {
    local word=$1

    local upper_limit
    upper_limit=$(echo "${word:0:$NCHAR}" | perl -nle 'print ++$_')

    local upper_isvalid
    upper_isvalid=$(echo true | \
                      awk "\"$word\" < \"$upper_limit\" {print \$0}")

    [[ -z $upper_isvalid ]] && upper_isvalid=false

    local nchar=$((10#$NCHAR))
    while ! $upper_isvalid; do
      nchar=$((nchar - 1))
      upper_limit=$(echo "${word:0:$nchar}" | perl -nle 'print ++$_')

      upper_isvalid=$(echo true | \
                      awk "\"$word\" < \"$upper_limit\" {print \$0}")
      [[ -z $upper_isvalid ]] && upper_isvalid=false
    done

    echo "$upper_limit"
}

compute_lower_limit () {
    local word=$1


    local lower_limit
    local lower_ord

    lower_ord=$(ord "${word:0:$NCHAR}")
    lower_ord=$((lower_ord-1))
    lower_limit=$(chr "$lower_ord" )
    # (>&2 echo "lower_limit: $lower_limit")

    local lower_isvalid
    lower_isvalid=$(echo true | \
                      awk "\"$word\" > \"$lower_limit\" {print \$0}")

    [[ -z $lower_isvalid ]] && lower_isvalid=false

    local nchar=$((10#$NCHAR))
    while ! $lower_isvalid; do
      nchar=$((nchar - 1))
      lower_ord=$(ord "${word:0:$NCHAR}")
      lower_ord=$((lower_ord-1))
      lower_limit=$(chr "$lower_ord" )

      lower_isvalid=$(echo true | \
                      awk "\"$word\" < \"$lower_limit\" {print \$0}")
      [[ -z $lower_isvalid ]] && lower_isvalid=false
    done

    echo "$lower_limit"
}

INDEX="$i"
LANGUAGE="$l"
NCHAR="$n"

if $debug; then
    echodebug "--- ARGUMENTS ---"
    echodebug "WORDS: "
    for word in "${WORD[@]}"; do
        echodebug "  * $word"
    done
    echodebug
    echodebug "debug (-d): $debug"
    echodebug "INDEX (-i): $INDEX"
    echodebug "LANGUAGE (-l): $LANGUAGE"
    echodebug "NCHAR (-n): $NCHAR"
    echodebug "output_length: $output_length"
    echodebug "verbose (-v): $verbose"
    echodebug "---"
fi

# https://stackoverflow.com/questions/12487424/
#     uppercase-first-character-in-a-variable-with-bash

# echo "$a" | tr '[:upper:]' '[:lower:]'
# echo "Eb" | perl -nle 'print --$_
for word in "${WORD[@]}"; do
  echoverbose "--- $word ---"

  upper=$(compute_upper_limit "$word")
  lower=$(compute_lower_limit "$word")
  echodebug "  * upper_limit: $upper"
  echodebug "  * lower_limit: $lower"

  first_result=$(grep -i "\.gz $LANGUAGE " "$INDEX" | \
                 awk "\$3 >= \"$lower\" && \$3 <= \"$upper\" {print \$0}" | \
                 sort | \
                 head -n1) || true
  echodebug "  * first_result: $first_result"

  fno=$(echo "$first_result" | \
        awk '{print $1}' | \
        awk -F'-' '{print $2}' | \
        tr -d '.gz' | \
        awk '{printf "%d\n",$0;}')
  echodebug "  * fno: $fno"

  fileno=$((10#$fno))
  echodebug "  * fileno: $fileno"

  # print results
  if (( "$fileno" >= 1 )); then
      printf "part-%0${output_length}d.gz\n" $((fileno - 1))
  fi

  grep -i ".gz $LANGUAGE " $INDEX | \
    awk "\$3 >= \"$lower\" && \$3 <= \"$upper\" {print \$1}"

  echoverbose '---'
done
