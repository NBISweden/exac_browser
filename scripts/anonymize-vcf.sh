#!/bin/bash -x

# Script to remove individuals' data from a VCF file.
# The output file will be compressed and a tabix index will be created.
# The resulting file is created in the same directory as the original
# VCF file, but with the string 'anon-' prepended to its name.

# Usage:
#
#   anonymize-vcf.sh path/to/file.vcf

vcf_path="$1"

vcf_name="${vcf_path##*/}"
vcf_dir="${vcf_path%/*}"

case "${vcf_name}" in
    *.gz)   prefilter="zcat"
            outfile="anon-$vcf_name"
            ;;
    *)      prefilter="cat"
            outfile="anon-$vcf_name.gz"
            ;;
esac

$prefilter "$vcf_path" |
awk '
    BEGIN   { OFS = "\t" }
    /^##/   { print; next }
            { print $1,$2,$3,$4,$5,$6,$7,$8 }' |
bgzip >"$vcf_dir/$outfile"

tabix -p vcf "$vcf_dir/$outfile"
