# Extracts the VCF headers and all variants with an allele frequency (AF
# field) larger than the value given on the command line.  The uncompressed
# VCF data is read from standard input, and the result is and written to
# standard output.

# Example usage (extracts variants with AF > 0.01):
#
#     zcat file.vcf.gz | awk -f extract-variants.awk f=0.01 | bgzip -c >filtered.vcf.gz
#
# ... where "extract-variants.awk" is this script.

# Input field separator is a tab
BEGIN   { FS = "\t" }

# Extract VCF header lines
/^#/    { print; next }

{
        found = 0

        # Split the info field (column 8) on semicolons
        n = split($8, a, ";")

        for (i = 1; i <= n && !found; ++i)
                # Split each sub-field on equal signs, and check whether
                # the left hand side of the equal sign is "AF"
                if (split(a[i], b, "=") == 2 && b[1] == "AF") {
                        # The AF field may contain a comma-delimited
                        # list of values.  We will extract this variant if
                        # any of these values are greater than the given
                        # threshold value (given to us in "f").
                        nn = split(b[2], c, ",")
                        for (j = 1; j <= nn && !found; ++j)
                                if (c[j] > f) found = 1
                }

        # Print the line if we found an AF value greater than f.
        if (found) print
}
