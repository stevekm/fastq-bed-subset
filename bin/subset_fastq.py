#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Subsets a .fastq.gz file to extract only the reads with the matching qnames
"""
import sys
import gzip
from Bio import SeqIO

def main():
    args = sys.argv[1:]
    input_fastq = args[0]
    qnames_txt = args[1]
    output_fastq = args[2]

    qnames = []
    with open(qnames_txt) as fin:
        for line in fin:
            qnames.append(line.strip())

    with gzip.open(input_fastq) as gz_in, gzip.open(output_fastq, 'wb') as gz_out:
        input_seq_iterator = SeqIO.parse(gz_in, "fastq")
        seq_iterator = (record for record in input_seq_iterator if record.id in qnames)
        SeqIO.write(seq_iterator, gz_out, "fastq")

if __name__ == '__main__':
    main()
