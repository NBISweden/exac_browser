This is just a table of where what data is stored.  We (NBIS) will
stored "shared data" in a single MongoDB collection while the
"non-shared data" is stored in a collection specific dataset.  This is
to allow multiple browser instances running space-efficiently off one
single MongoDB instance.


        N A M E         C O L L E C T I O N             C O N F I G

SHARED DATA:
get_db(True)

        Gene Models     db.{genes,transcripts,exons}    CANONICAL_TRANSCRIPT_FILE
        Gene Models     db.{genes,transcripts,exons}    OMIM_FILE
        Gene Models     db.{genes,transcripts,exons}    DBNSFP_FILE
        Gene Models     db.{genes,transcripts,exons}    GENCODE_GTF
        DBSNP           db.dbsnp                        DBSNP_FILE

NON-SHARED DATA:
get_db(False)

        Base Coverage   db.base_coverage                BASE_COVERAGE_FILES
        Variants        db.variants                     SITES_VCFS
        Constraints     db.constraints                  CONSTRAINTS_FILE
        MNPs            db.variants                     MNP_FILE
        CNV Models      db.cnvs                         CNV_FILE
        CNV Genes       db.cnvgenes                     CNV_GENE_FILE
        Metrics         db.metrics                      (calculated)
