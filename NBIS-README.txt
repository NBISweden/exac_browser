Additional index needs to be added for the Beacon to work smoothly:

	db.variants.createIndex({'chrom':1, 'pos': 1})


================================================================================
Preparing and loading data:

Some of this document echoes the ExAC browser's README.md, but has local
modifications.

The data will be loaded into MongoDB instance on swefreq-db from the
command line.  The process is not automated due to its tendency to
sometimes die half-way.


--------------------------------------------------------------------------------
Support for multiple datasets in SweFreq:

Each dataset uses a different collection in the MongoDB database. The
collection used is determined by two things:

1.	The FLASK_PORT environment variable. This is an environment
	variable that needs to be set before the browser is started or
	before the data is loaded.  It should be set to a port number
	greater than or equal to 5000 (an arbitrarily picked number).
	Whenever we re-import the *SweGen* dataset, that dataset should
	be loaded with FLASK_PORT=8000.  Not setting this environment
	variable will cause the browser (or data loading script) to fail
	immediately.

2.	The settings.json file has entries like

	"mongoDb-8000": {
		"db": "exac-swegen-GRChg37",
		"refdb": "exac-common-GRChg37" },

	The number in the key corresponds to the value of the FLASK_PORT
	environment variable, the "db" value refers to the MongoDB
	collection that contains the variation and coverage data for
	the browesr instance (the data specific to a dataset), and the
	"refdb" value refers to the MongDB collection holding the genes
	etc. for the reference dataset used.  Several dataset may share
	the same "refdb" setting.


--------------------------------------------------------------------------------
Preparing and loading a dataset:

For information about fetching and loading a reference dataset, see next
section.

A dataset consists of

1.	a VCF file ("variations.vcf.gz"),

2.	its associated Tabix index ("variations.vcf.gz.tbi"),

3.	a subdirectory ("coverage") of coverage files
	("Panel.*.coverage.txt.gz"), and

4.	Tabix index files for each individual coverage file
	("coverage/Panel.*.coverage.txt.gz.tbi").

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

These files should be placed in the directory "exac_data" beneath the
"swefreq-browser" directory (the directory which is a clone of the
"swefreq-browser" GitHub repository).  The "exac_data" directory, or
the files and directories in that directory may also be provided using
symbolic links, if that helps organising data files.

Assuming that the "swefreq-browser" directory has been properly set up
with regards to the Python virtual environment (see "README.md"), the
following steps will finally load the dataset into the proper MongoDB
collection:

1.	source exac_venv/bin/activate

	This activates the Python vitual environment.

2.	FLASK_PORT=8000 python manage.py load_variants_file | tee out.log

	This loads the VCF file into the collection associated with
	the "mongodb-8000.db" container in the "settings.conf" file.
	The output is logged to the terminal as well as to the file
	"out.log".  Consult this log file to make sure the loading
	finished without errors before proceeding (there should be
	one line saying "Finished" for each loading thread, this goes
	for all data loading steps).  If errors occured, they may be
	transient, and retrying will drop the previously loaded data and
	load it again.

3.	FLASK_PORT=8000 python manage.py load_base_coverage | tee out.log

	This loads the base coverage files.

The dataset is now loaded.


