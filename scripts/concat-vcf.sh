#!/bin/bash -x

# Script to concatenate two or more VCF files.
# Will create "swegen.vcf.gz" and a corresponding Tabix index in the
# current directory.

# Usage:
#
#   concat-vcf.sh path/to/file1.vcf path/to/file2.vcf

# We use bcftools from a GitHub checkout since the Ubuntu version is too old.
bcftools_path="/home/andkaha/bcftools"

"$bcftools_path"/bcftools concat -Oz -a "$@" >swegen.vcf.gz

tabix -f -p vcf swegen.vcf.gz
