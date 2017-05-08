#!/usr/bin/env python
"""Naval Fate.

Usage:
  simplify_regexes.py [options] INFILE
  simplify_regexes.py (-h | --help)
  simplify_regexes.py --version

Options:
  -d, --debug       Set debug mode (implies --verbose).
  -v, --verbose     Set verbose mode.
  -h --help         Show this screen.
  --version         Show version.
"""

import os
import sys
import logging
import itertools
from docopt import docopt

if __name__ == '__main__':
    arguments = docopt(__doc__, version='simplify_regexes.py 0.1.0')

    loglevel = logging.WARNING
    if arguments['--debug']:
        loglevel = logging.DEBUG
    if arguments['--verbose']:
        loglevel = logging.INFO

    if arguments['--debug']:
        arguments['--verbose'] = True

    ### logging setup
    # root logger
    rootlogger = logging.getLogger(__name__)
    rootlogger.setLevel(logging.DEBUG)

    # main logger for this module
    logger = rootlogger.getChild('main')
    logger.setLevel(loglevel)

    # create handler and set its level
    ch = logging.StreamHandler()
    ch.setLevel(loglevel)

    # create formatter and add it to the handlers
    formatter = logging.Formatter('[%(asctime)s](%(name)s)[%(levelname)s]: %(message)s')
    ch.setFormatter(formatter)

    # add handler to the logger
    logger.addHandler(ch)

    logger.debug('loglevel: {}'.format(loglevel))
    ### END logging setup

    logger.debug(arguments)

    with open(arguments['INFILE'], 'r') as infile:
        lines = infile.readlines()
        lines = [line.strip() for line in lines]

        # for line in lines:
        #     print("line: {}".format(line))

    regexes = set(lines)
    to_remove = set()

    for first, second in itertools.combinations(regexes, r=2):

        mfs = first.find(second)
        msf = second.find(first)

        logger.debug('first: {}'.format(first))
        logger.debug('second: {}'.format(second))
        logger.debug('mfs: {}\t- msf: {}'.format(mfs, msf))

        if (mfs == -1) and (msf == -1):
            # None of regexes contain each other, do nothing
            pass
        elif (mfs != -1) and (msf == -1):
            # the first regex is contained in the second, remove the first
            to_remove.add(first)

        elif (mfs == -1) and (msf != -1):
            # the second regex is contained in the first, remove the second
            to_remove.add(second)
        else:
            # this should not happen, print an error
            print('mfs is not None and msf is not None',file=sys.stderr)
            import ipdb
            ipdb.set_trace()
    logger.debug('---')

    dirname = os.path.dirname(arguments['INFILE'])
    radix, ext = os.path.splitext(os.path.basename(arguments['INFILE']))
    radix = radix.split('.')[0]
    logger.debug('radix: {} - ext: {}'.format(radix, ext))

    outfilename = '{}.simplified-quoted-redirects.txt'.format(radix)
    outfile = os.path.join(dirname, outfilename)
    logger.debug('outfile: {}'.format(outfile))

    simple = regexes - to_remove

    with open(outfile, 'w') as outf:
        for el in sorted(simple):
            outf.write(el)
            outf.write('\n')
