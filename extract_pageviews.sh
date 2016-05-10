#!/usr/bin/env bash
eval "$(docopts -V - -h - : "$@" <<EOF
Usage: extract_pageviews.sh [options] TITLE

      -d, --debug          Enable debug mode (implies --verbose).
      -l LANGUAGE          Language code [default: en].
      -o OUTPUT_DIR        Output directory [default: output].
      -v, --verbose        Print unified diff format (more verbose).
      -h, --help           Show this help message and exits.
      --version            Print version and copyright information.
----
extract_pageviews.sh 0.1.0
copyright (c) 2016 Cristian Consonni
MIT License
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
EOF
)"

##############################################################################
# WORKFLOW 
#
# 1. check if page is there on Wikipedia, if it is a redirect use the page
#    towards which it is redirected
#
# 2. get the redirects for a page at:
#        http://dispenser.homenet.org/~dispenser/cgi-bin/rdcheck.py
#    and save them in a file named ./output/{lang}/{title}.redirects.txt
#
# 2. quote them with the following command:
#        cat ./output/{lang}/{title}.redirects.txt | \
#            parallel ./scripts/quote_pagetitle.sh {} | sort | \
#            uniq > ./output/{lang}/{title}.quoted-redirects.txt
#    the results will be saved in a file called:
#    ./output/{lang}/{title}.quoted-redirects.txt
#
# 3. get the pageview data for the single page with the following command:
#        cat ./output/{lang}/{title}.quoted-redirects.txt | \
#            parallel ./scripts/select_pageviews.sh -l {lang} "{}" | \
#            sort | uniq  | \
#            parallel cp /mnt/nxdata/datasets/pagecounts-2014.csv/{} ./data/
#
#        ./scripts/select_pageviews.sh -l {lang} "{quoted_title}" | \
#            sort | uniq | \
#            parallel cp /mnt/nxdata/datasets/pagecounts-2014.csv/{} ./data/
#    this will save a bunch of files in ./data/ named part-XXXXXX.gz
#
# 4. change the permissions on files in data 
#        chmod a-x part-*.gz
#        chmod u+w part-*.gz
# 5. Extract the pageview data with the following command:
#        zgrep -E " {quoted_title} " ./data/part* | \
#            gzip > ./output/{lang}/{title}.clean.pageviews.txt.gz
#
#        zgrep -E -f ./output/it/{title}.quoted-redirects.txt ./data/part* | \
#            gzip > ./output/it/{title}.quoted-redirects.pageviews.txt.gz
##############################################################################

# 1. get redirects
# get_redirects -l LANG -o OUTPUT_DIR TITLE
#    and save them in a file named ./output/{lang}/{title}.redirects.txt
#
#./script/get_redirects.sh > ./{OUTPUT_DIR}/{LANG}/{TITLE}.redirects.txt

# 2. quote them with the following command:
#        cat ./output/{lang}/{title}.redirects.txt | \
#            parallel ./scripts/quote_pagetitle.sh {} | sort | \
#            uniq > ./output/{lang}/{title}.quoted-redirects.txt
#    the results will be saved in a file called:
#    ./output/{lang}/{title}.quoted-redirects.txt

# cat ./{OUTPUT_DIR}/{LANG}/{TITLE}.redirects.txt | \
#     parallel ./scripts/quote_pagetitle.sh {} | \
#     sort | \
#     uniq > ./{OUTPUT_DIR}/{LANG}/{TITLE}.quoted-redirects.txt
