SHELL:=/bin/bash
UNAME:=$(shell uname)

export NXF_VER:=19.01.0
./nextflow:
	curl -fsSL get.nextflow.io | bash

PATH:=$(CURDIR)/conda/bin:$(PATH)
unexport PYTHONPATH
unexport PYTHONHOME
ifeq ($(UNAME), Darwin)
CONDASH:=Miniconda3-4.5.4-MacOSX-x86_64.sh
endif
ifeq ($(UNAME), Linux)
CONDASH:=Miniconda3-4.5.4-Linux-x86_64.sh
endif
CONDAURL:=https://repo.continuum.io/miniconda/$(CONDASH)
conda:
	@echo ">>> Setting up conda..."
	@wget "$(CONDAURL)" && \
	bash "$(CONDASH)" -b -p conda && \
	rm -f "$(CONDASH)"

conda-install: conda
	conda install -y -c bioconda -c anaconda \
	conda=4.5.4 \
	pysam=0.15.2 \
	biopython=1.70

install: conda-install ./nextflow

test:
	which conda
	which pip
	which python
	python --version
	python -c 'import pysam; import Bio;'
	which samtools

run: conda ./nextflow
	./nextflow run main.nf -resume





# ~~~~~ CLEANUP ~~~~~ #
# commands to clean out items in the current directory after running the pipeline

clean-output:
	[ -d output ] && mv output oldoutput && rm -rf oldoutput &

clean-work:
	[ -d work ] && mv work oldwork && rm -rf oldwork &

# clean all files produced by previous pipeline runs
clean:
	rm -f .nextflow.log.*
	rm -f trace*.txt.*
	rm -f *.html.*
	rm -f *.dot.*

# clean all files produced by all pipeline runs
clean-all: clean clean-output clean-work
	[ -d .nextflow ] && mv .nextflow .nextflowold && rm -rf .nextflowold &
	rm -f .nextflow.log
	rm -f *.png
	rm -f trace*.txt*
	rm -f *.html*
	rm -f flowchart*.dot
	rm -f nextflow.*.stdout.log
