#!/bin/bash

# We get the coverage data in 483 files (for the initial release).
# Re-make these so that we have only one file per chromosome.  Then
# compress and tabix index each file.

coverage_dir="$1"

if [[ ! -d "$coverage_dir" ]]; then
    printf "No such directory: '%s'\n" "$coverage_dir"
    exit
fi

new_coverage_dir="new-$coverage_dir"

printf "Will create '%s'\n" "$new_coverage_dir"

if ! mkdir "$new_coverage_dir"; then
    echo "Failed"
    exit 1
fi

printf "Reading from '%s'\n..." "$coverage_dir"

for f in "$coverage_dir"/Panel.*.gz; do
    printf "Parsing '%s'...\n" "$f"
    zcat "$f" |
    awk -v dir="$new_coverage_dir" '
        /^#/        { next }
        $1 != chr   {
                        chr  = $1;
                        file = sprintf("%s/Panel.%s.coverage", dir, chr);
                        printf("Outputting to '%s'\n", file);
                    }
                    { print $0 >> file }'
done

echo "Compressing files (bgzip) and creating indexes (tabix)..."
for f in "$new_coverage_dir"/Panel.*.coverage; do
    printf "Compressing '%s'...\n" "$f"
    bgzip "$f"
    printf "Indexing '%s'...\n" "$f"
    tabix -b 2 -e 2 "$f"
done
