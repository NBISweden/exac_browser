#!/bin/bash

# This script is to be run in the exac_data directory.  It will read
# the coverage data in the coverage subdirectory, and write a filtered
# version of the data to files in a new coverage-thinned directory,
# together with the appropriate Tabix indexes.  The new directory must
# not already exist.
#
# The new coverage data consists of only those bases that occur on a
# coordinate which is a multiple of 10.

set -e

if [[ ! -d "coverage" ]]; then
    echo "Can not find directory 'coverage' here" >&2
    exit 1
fi

mkdir coverage-thinned
echo "Directory 'coverage-thinned' created" >&2

for cov in coverage/Panel*.gz; do
    printf 'Processing "%s"... ' "$cov" >&2

    printf 'unzip... ' >&2
    tmpcov="$( mktemp -p . )"
    gzip -d -c "$cov" >"$tmpcov"

    printf 'filter... ' >&2
    head -n 1 "$tmpcov" >"$tmpcov".head
    sed '1d' "$tmpcov" | awk '$2 % 10 == 0 { print }' >"$tmpcov".data

    printf 'compress... ' >&2
    cat "$tmpcov".head "$tmpcov".data | bgzip >coverage-thinned/"${cov##*/}"

    printf 'index... ' >&2
    tabix -f -s 1 -b 2 -e 2 coverage-thinned/"${cov##*/}"

    printf 'done.\n' >&2
    rm -f "$tmpcov" "$tmpcov".head "$tmpcov".data
done
