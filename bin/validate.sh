#!/bin/bash

set -o nounset -o pipefail -o errexit

INPUT=$1

echo >&2 "validating: $INPUT"
exec tidy -quiet -errors --doctype=html5 "$INPUT"
