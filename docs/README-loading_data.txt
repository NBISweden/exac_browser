Old documentation:


Additional index needs to be added for the Beacon to work smoothly:

    db.variants.createIndex({'chrom':1, 'pos': 1})


New documentation:


================================================================================
Preparing and loading data:

Some of this document echoes the ExAC browser's README.md, but has
local modifications.  The README.md document also assumes only a single
dataset (ExAC), which does not reflect our current use of this browser
code.

The data will be loaded into MongoDB instance in the LXD container
specified in the "settings.conf" file.  Loading of datasets happens
manually from the command line.  The process is not automated due to its
tendency to sometimes die half-way.


--------------------------------------------------------------------------------
Reference data and dataset-specific data:

Reference data refers to data not provided by a variation dataset
provider.  This is data on a reference genome such as gene and
transcripts.

Dataset-specific data refers to the variations provided by a dataset
provider.


--------------------------------------------------------------------------------
Support for multiple datasets in SweFreq:

Each dataset uses a different collection in the MongoDB database for
storing its dataset-specific data. The collection used is determined by
two things:

1.  The FLASK_PORT environment variable. This is an environment variable
    that needs to be set before the browser is started or before the
    data is loaded.  It should be set to a port number greater than
    or equal to 5000 (an arbitrarily picked number).  Whenever we
    re-import the *SweGen* dataset, that dataset should be loaded with
    FLASK_PORT=8000.  Not setting this environment variable will cause
    the browser (or data loading script) to fail immediately.

2.  The "settings.json" file has entries like

    "mongoHost": "swefreq-db",

    which specifies what LXD container to use for the MongoDB database
    that the SweFreq browser uses ("swefreq-db" is the "live database
    container"), and

    "mongoDb-8000": {
        "db": "exac-swegen-GRChg37",
        "refdb": "exac-common-GRChg37" },

    The number in the key corresponds to the value of the FLASK_PORT
    environment variable, the "db" value refers to the MongoDB
    collection that contains the variation and coverage data for the
    browser instance (the data specific to a dataset), and the "refdb"
    value refers to the MongoDB collection holding the genes etc. for
    the reference dataset used.  Several dataset may share the same
    "refdb" setting.


--------------------------------------------------------------------------------
Preparing a dataset:

For information about fetching and loading a reference dataset, see next
section.

A dataset consists of

1.  a VCF file ("variations.vcf.gz"),

2.  its associated Tabix index ("variations.vcf.gz.tbi"),

3.  a subdirectory ("coverage") of coverage files
    ("Panel.*.coverage.txt.gz"), and

4.  Tabix index files for each individual coverage file
    ("coverage/Panel.*.coverage.txt.gz.tbi").

The filenames mentioned are the ones that the data loading script
expects to find in the "exac_data" directory under the main
"swefreq-browser" directory.

The Tabix index for the main VCF file is created (unless already
provided) using

    tabix -p vcf variations.vcf.gz

This requires that the VCF file was compressed using bgzip, not gzip.

The Tabix index for the individual coverage data files may be created
using

    for name in coverage/Panel.*.coverage.txt.gz; do
        tabix -s 1 -b 2 -e 2 "$name"
    done

The coverage files, like the VCF file, must have been compressed using
bgzip.

These files should be placed in the directory "exac_data" beneath
the "swefreq-browser" directory (the directory which is a clone of
the "swefreq-browser" GitHub repository and that has previously been
properly set up to include the needed software).  The "exac_data"
directory, or the files and directories in that directory may also be
provided using symbolic links, if that helps organising data files.


--------------------------------------------------------------------------------
Loading a dataset:

Assuming that the "swefreq-browser" directory has been properly set up
with regards to the Python virtual environment (see "README.md"), the
following steps will finally load the dataset into the proper MongoDB
collection:

1.  source exac_venv/bin/activate

    This activates the Python virtual environment.

2.  FLASK_PORT=<number> python manage.py load_variants_file | tee out.log

    Do update the port number (e.g. "FLASK_PORT=9876") to
    the appropriate number.  This should correspond to the
    "mongodb-<number>.db" collection name in "settings.conf".

    FAILING TO SPECIFY THE CORRECT NUMBER IS FATAL
    (it will delete data if an existing collection exists).

    This loads the VCF file into the collection associated with the
    "mongodb-<number>.db" setting in the "settings.conf" file.  The
    output is logged to the terminal as well as to the file "out.log".
    Consult this log file to make sure the loading finished without
    errors before proceeding (there should be one line saying "Finished"
    for each loading thread, this goes for all data loading steps).  If
    there were errors, they may be transient, and retrying will drop the
    previously loaded data and load it again.

3.  FLASK_PORT=<number> python manage.py load_base_coverage | tee out.log

    This loads the base coverage files.  The log file "out.log" will
    be overwritten.

The dataset is now loaded.


--------------------------------------------------------------------------------
Preparing and loading a reference dataset:

By "reference dataset" is meant the genes, transcripts, etc. that are
not part of a specific SweFreq dataset but annotated on the relevant
reference assembly and that may be shared between datasets. dbSNP and
similar datasets also belong in this category.

The reference datasets are:

1.  GENCODE
    Filename: gencode.gtf.gz

2.  dbSNP
    Filename: dbSNP.txt.bgz and dbSNP.txt.bgz.tbi

3.  dbNSFP
    Filename: dbNSFP_gene.gz

4.  Ensembl canonical transcripts
    Filename: canonical_transcripts.txt.gz

5.  OMIM
    Filename: omim_info.txt.gz

The filenames mentioned above are the ones that the data loading script
expects to find in the "exac_data" directory under "swegen-browser".
These may be supplied by symbolic links if that makes data management
easier.

We currently have a GRChg37 and a GRChg38 verison of each set of data
in the two collections,"exac-common-GRChg37" and "exac-common-GRChg38"
respectively, in the "swefreq-db" container.

When fetching datasets, it may be a good idea to work in an empty
directory which you then fill up with data for a particular human
reference genome, just so that data files for different assemblies are
not accidentally mixed up.

Each dataset will need its own particular handling and I will mention
each in order, first for the GRChg37 genome, and then for GRChg38
immediately following that.  The reference datasets for one assimbly
should be picked to be on as similar versions of the assembly as
possible.


Fetching and preparing GENCODE (GENCODE v19, GRChg37.p13):

    curl -o gencode-orig.gtf.gz \
        ftp://ftp.sanger.ac.uk/pub/gencode/Gencode_human/release_19/gencode.v19.annotation.gtf.gz

    Remove all lines that does not start with "#" (comments) or "chr".
    This gets rid of the "GL" chromosome data which otherwise causes
    issues when loading.

    zgrep -E '^(#|chr)' gencode-orig.gtf.gz |
    gzip -c >gencode.gtf.gz


Fetching and preparing GENCODE (GENCODE v27, GRChg38.p10):

    curl -o gencode-orig.gtf.gz \
        ftp://ftp.sanger.ac.uk/pub/gencode/Gencode_human/release_27/gencode.v27.annotation.gtf.gz

    I have not made any notes about filtering this dataset in the same
    way as the GRChg37 dataset (above).  It is possibly not needed, or
    if it is, it is done in the identical way as for GRChg37.

    ln -s gencode-orig.gtf.gz gencode.gtf.gz


Fetching and preparing dbSNP (dbSNP b150, GRCh37.p13):

    curl -o dbSNP-orig.txt.gz \
        ftp://ftp.ncbi.nlm.nih.gov/snp/organisms/human_9606_b150_GRCh37p13/database/data/organism_data/b150_SNPChrPosOnRef_105.bcp.gz

    zcat dbSNP-orig.txt.gz | mawk 'length($3) > 0 { gsub(/ +/, "\t"); print }' |
    sort --parallel=8 -S 256M -k2,2 -k3,3n | bgzip -c >dbSNP.txt.bgz

    tabix -s 2 -b 3 -e 3 dbSNP.txt.bgz


Fetching and preparing dbSNP (dbSNP b150, GRCh38.p7)

    curl -o dbSNP-orig.txt.gz \
        ftp://ftp.ncbi.nlm.nih.gov/snp/organisms/human_9606_b150_GRCh38p7/database/data/organism_data/b150_SNPChrPosOnRef_108.bcp.gz

    zcat dbSNP-orig.txt.gz | mawk 'length($3) > 0 { gsub(/ +/, "\t"); print }' |
    sort --parallel=8 -S 256M -k2,2 -k3,3n | bgzip -c >dbSNP.txt.bgz

    tabix -s 2 -b 3 -e 3 dbSNP.txt.bgz


Fetching and preparing dbNSFP (dbNSFP v2.9.3, GRCh37):

    This is a 13.4 GB Zip-file that is really slow to download. Out of
    it, we need to get a single 26MB file (sigh).

    curl -o dbNSFP-orig.zip \
        ftp://dbnsfp:dbnsfp@dbnsfp.softgenetics.com/dbNSFPv2.9.3.zip

    unzip dbNSFP-orig.zip dbNSFP2.9_gene
    gzip -9 dbNSFP2.9_gene
    mv dbNSFP2.9_gene.gz dbNSFP_gene.gz


Fetching and preparing dbNSFP (dbNSFP v3.5a, GRCh38(.p2?)):

    Again, this is a 16.1 GB Zip-file that is really slow to download.

    curl -o dbNSFP-orig.zip \
        ftp://dbnsfp:dbnsfp@dbnsfp.softgenetics.com/dbNSFPv3.5a.zip

    unzip dbNSFP-orig.zip dbNSFP3.5_gene
    gzip -9 dbNSFP3.5_gene
    mv dbNSFP3.5_gene.gz dbNSFP_gene.gz


Fetching and preparing Ensembl canonical transcripts (Ensembl 75, GRCh37.p13):

    mysql -BN -h ensembldb.ensembl.org -u anonymous -D homo_sapiens_core_75_37 \
        -e 'SELECT g.stable_id, t.stable_id FROM gene g JOIN transcript t
            ON (g.canonical_transcript_id = t.transcript_id)' |
    sort | gzip -9c >canonical_transcripts.txt.gz


Fetching and preparing Ensembl canonical transcripts (Ensembl 90, GRCh38.p10):

    mysql -BN -h ensembldb.ensembl.org -u anonymous -D homo_sapiens_core_90_38 \
        -e 'SELECT g.stable_id, t.stable_id FROM gene g JOIN transcript t
            ON (g.canonical_transcript_id = t.transcript_id)' |
    sort | gzip -9c >canonical_transcripts.txt.gz


Regarding OMIM:

    Using old dataset (still GRChg37?).  Update seems to require
    registration.
