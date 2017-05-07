#!/usr/bin/env python
"""Naval Fate.

Usage:
  simplify_regexes.py INFILE
  simplify_regexes.py (-h | --help)
  simplify_regexes.py --version

Options:
  -h --help     Show this screen.
  --version     Show version.
"""

from docopt import docopt
import regex

if __name__ == '__main__':
    arguments = docopt(__doc__, version='simplify_regexes.py 0.1.0')
    print(arguments)


    with open(arguments['INFILE'], 'r') as infile:
        lines = infile.readlines()
        lines = [line.strip() for line in lines]

        # for line in lines:
        #     print("line: {}".format(line))

    regexes = set(lines)
