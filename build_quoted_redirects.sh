#!/usr/bin/env bash

find "$1" -maxdepth 3 -type f -name '*.redirects.txt' | \
  while read -r filename; do
    base_name=$(basename "$filename") 
    pagename="${base_name%.*}"
    radix="${pagename%.*}"

    echo "processing: ${base_name} - radix: ${radix}"

    # shellcheck disable=SC2002
    cat "$filename" | \
      parallel ./quote_pagetitle.sh {} | \
        sort | \
        uniq > ./output/en/"${radix}.quoted-redirects.txt"
done
