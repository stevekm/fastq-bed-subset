# fastq-bed-subset

__Filter fastq file based on bed regions__

A workflow for subsetting .fastq.gz files based on selected genomic coordinates.

This workflow will search the .bam file for the read identifiers that match the desired coordinates, then extract those reads from the original fastq files. This way, you can subset your fastq files down to only the reads that match the desired regions.

# Input Data

Required data:

- input fastq.gz files to be subset (designed for use with paired-end reads)

- .bam alignments for the fastq files

- .bed file (`targets.bed`) with genomic coordinates to select reads, in the format:

```
chr start   stop    numReads
```

example:

```
chr7	140453135	140453137	950
```

The fourth field in the .bed file is optional; if not present, the value of `params.maxReads` from the main pipeline script will be used.

# Usage

First, clone this repo:

```
git clone https://github.com/stevekm/fastq-bed-subset.git
cd fastq-bed-subset
```

The software required to run the pipeline can be downloaded and set up using the included Makefile recipe:

```
make install
```

This will install `conda` and Nextflow in the current directory, and install the needed dependencies into the `conda` installation.

You can test that the installation worked with `make test`.

Set your desired genomic regions in the file `targets.bed`; an example file is provided.

Set the input files for your samples in the `samplesheet.tsv` file in the format:

```
Sample  R1  R2  Bam
```

For the sample ID, fastq read 1, fastq read 2, and .bam file, respectively. The fields `R1` and `R2` can be comma-delimited lists of multiple input files, in case your reads were split by lane during demultiplexing, etc.; they will be combined into a single R1 and R2 fastq file each before processing.

Run the Nextflow pipeline in the current session:

```
make run
```

- NOTE: The included execution configuration has been customized for usage on NYULMC Big Purple HPC using SLURM; you can adjust this to match your execution platform in the `nextflow.config` file.

If you want to submit the parent Nextflow process to the SLURM HPC cluster for execution, you can use `make submit` instead.

# Software

- Nextflow (installation included)

- Python (installation included with `conda`)

  - `pysam`, `biopython`

- GNU `make` and `bash` to run the wrapper scripts in the Makefile
