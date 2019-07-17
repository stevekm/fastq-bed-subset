SHELL:=/bin/bash
UNAME:=$(shell uname)
DIRNAME:=$(shell python -c 'import os; print(os.path.basename(os.path.realpath(".")))')
ABSDIR:=$(shell python -c 'import os; print(os.path.realpath("."))')

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

list:
	conda list

EP:=
run: conda ./nextflow
	./nextflow run main.nf -resume $(EP)

# submit the parent Nextflow script as a SLURM job
LOG_DIR:=logs
LOG_DIR_ABS:=$(shell python -c 'import os; print(os.path.realpath("$(LOG_DIR)"))')
SUBJOBNAME:=fastq-subset
SUBLOG:=$(LOG_DIR_ABS)/slurm-%j.out
SUBQ:=cpu_long
SUBTIME:=--time=5-00:00:00
SUBTHREADS:=4
SUBMEM:=8G
NXF_NODEFILE:=.nextflow.node
NXF_JOBFILE:=.nextflow.jobid
NXF_PIDFILE:=.nextflow.pid
NXF_SUBMIT:=.nextflow.submitted
NXF_SUBMITLOG:=.nextflow.submitted.log

submit:
	printf '#!/bin/bash \n\
	set -x \n\
	echo $$SLURMD_NODENAME > "$(NXF_NODEFILE)" \n\
	pid="" \n\
	kill_func(){ \n\
	echo TRAP; kill $$pid ; wait $$pid \n\
	} \n\
	trap kill_func INT \n\
	trap kill_func EXIT \n\
	./nextflow run main.nf -resume & pid=$$! ; echo "waiting for $${pid}" ; wait $$pid \n\
	' | \
	sbatch -D "$(ABSDIR)" -o "$(SUBLOG)" -J "$(SUBJOBNAME)" -p "$(SUBQ)" $(SUBTIME) --ntasks-per-node=1 -c "$(SUBTHREADS)" --mem "$(SUBMEM)" /dev/stdin | tee >(sed 's|[^[:digit:]]*\([[:digit:]]*\).*|\1|' > '$(NXF_JOBFILE)')

# issue an interupt signal to a process running on a remote server
# e.g. Nextflow running in a qsub job on a compute node
kill: NXF_JOB:=$(shell head -1 $(NXF_JOBFILE))
kill: $(NXF_JOBFILE)
	scancel "$(NXF_JOB)"


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
