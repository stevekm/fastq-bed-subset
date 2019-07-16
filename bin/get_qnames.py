#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Outputs a file containing all the qnames of the reads in the provided .bam file
that fall into the provided genomic region
"""
import sys
import pysam

def main():
    args = sys.argv[1:]
    input_bam = args[0]
    chrom = args[1]
    start = int(args[2])
    stop = int(args[3])
    numReads = int(args[4])
    output_txt = args[5]

    qnames = []
    bam = pysam.AlignmentFile(input_bam, "rb")
    for read in bam.fetch(chrom, start, stop):
        if len(qnames) < numReads:
            qnames.append(read.qname)
        else:
            break
    bam.close()

    with open(output_txt, "w") as fout:
        for qname in qnames:
            fout.write(qname + '\n')

if __name__ == '__main__':
    main()
