#!/bin/sh

eval "$(opam config env)"

SCRIPT_DIR=$(readlink -f $0 | xargs dirname)

MAKE=$(which gmake 2>/dev/null)
if [ $? -ne 0 ]; then
    MAKE=$(which make)
fi

(cd $SCRIPT_DIR && git fetch && git checkout origin/master 2>&1)
$MAKE -C "$SCRIPT_DIR/.." fresh generate upload ENV=prod
