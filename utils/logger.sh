#!/usr/bin/env bash
##############################################################################
#
# Bash logging library.
#
# Code adapted from:
# http://www.cubicrace.com/2016/03/efficient-logging-mechnism-in-shell.html
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# 
##############################################################################

function SCRIPTLOG_START() {
    CFN=''
    SCRIPT_LOG=$1
    script_name=`basename "$0"`
    _WRITE_LOG "DEBUG" "$FUNCNAME: $script_name"
}

function SCRIPTLOG_STOP() {
    script_name=`basename "$0"`
    _WRITE_LOG "DEBUG" "$FUNCNAME: $script_name"
}

function ENTRY() {
    CFN="${FUNCNAME[1]}"
    _WRITE_LOG "DEBUG" "> $CFN $FUNCNAME"
}

function RETURN() {
    _WRITE_LOG "DEBUG" "< $CFN $FUNCNAME"
    CFN=''
}

function INFO() {
    _WRITE_LOG "$FUNCNAME " "$1"
}

function DEBUG() {
    _WRITE_LOG "$FUNCNAME" "$1"
}

function ERROR() {
    _WRITE_LOG "$FUNCNAME" "$1"
}

function _WRITE_LOG() {
    local loglevel="$1"
    local msg="$2"
    local tstamp=`date`
    if [[ ! -z "$CFN" ]]; then
        echo -e "[$tstamp] [$loglevel] ($CFN) \t$msg" >> $SCRIPT_LOG
    else
        echo -e "[$tstamp] [$loglevel] (main) \t$msg" >> $SCRIPT_LOG
    fi
}
