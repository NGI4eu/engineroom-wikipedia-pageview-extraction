Wikipedia pageviews extraction
------------------------------


## Worflow

1. Check if there is a page with title TITLE on Wikipedia.
   If it is a redirect use the page towards which it is redirected
2. get the redirects for a page at:
       http://dispenser.homenet.org/~dispenser/cgi-bin/rdcheck.py
   and save them in a file named ./{output}/{lang}/{title}.redirects.txt
3. quote page and redirect titles and save everything in a file called:
   ./{output}/{lang}/{title}.quoted-redirects.txt
4. get the pageview data this will save a bunch of files in
   ./{data}/part_data/part-XXXXXX.gz
5. change the permissions on files in ./data/part_data/
6. Extract the pageview data
   a. extract the pageviews only for the page named TITLE
      and save them in ./{output}/{lang}/{title}.clean.pageviews.txt.gz
   b. extract the pageviews only for the page named TITLE
      and save them in
      ./{output}/{lang}/{title}.quoted-redirects.pageviews.txt.gz
