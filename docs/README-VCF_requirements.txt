========================================================================
Requirements on VCF file for loading as a SweFreq dataset, and
information about what is parsed from it.


The VCF file should be a valid VCF 4.0, 4.1 or 4.2 file and the
body of the VCF file should contain all eight mandatory tab-delimited
fields that is required by VCF 4.0, 4.1 or 4.2.  These are

1. #CHROM
2. POS
3. ID
4. REF
5. ALT
6. QUAL
7. FILTER
8. INFO

See e.g. http://samtools.github.io/hts-specs/VCFv4.2.pdf

Files in the Ensembl format similar to VCF (six columns) are not
supported, neither are files in any other format.


It is required that the dataset has been annotated with the Ensembl
Variant Effect Predictor (VEP) tool.  This annotation pipeline is
avaliable for local installation from
https://www.ensembl.org/info/docs/tools/vep
