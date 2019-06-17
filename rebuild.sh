#!/bin/sh

# ensure we've loaded the ocaml environment
. ~/.profile

SCRIPT_DIR=$(readlink -f $0 | xargs dirname)

MAKE=$(which gmake 2>/dev/null)
if [ $? -ne 0 ]; then
    MAKE=$(which make)
fi

(cd $SCRIPT_DIR && git pull 2>&1)
$MAKE -C $SCRIPT_DIR fresh generate
