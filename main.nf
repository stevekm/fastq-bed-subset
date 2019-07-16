params.samplesheet = "samplesheet.tsv"
params.targets = "targets.bed"
params.maxReads = "5000"
// def maxReads = params.maxReads.toInteger()

Channel.fromPath( params.samplesheet )
        .splitCsv(header: true, sep: '\t')
        .map{row ->
            def sampleID = row['Sample']
            def reads1 = row['R1'].tokenize( ',' ).collect { file(it) } // comma-sep string into list of files
            def reads2 = row['R2'].tokenize( ',' ).collect { file(it) }
            def bam = file(row['Bam'])
            return [ sampleID, reads1, reads2, bam ]
        }
        .tap { samples_R1_R2 }

Channel.fromPath( params.targets )
    .splitCsv(header: false, sep: '\t')
    .map { row ->
        def chrom = row[0]
        def start = row[1]
        def stop = row[2]
        def numReads
        if ( row.size() >= 4 ) {
            numReads = row[3]
        } else {
            numReads = "${params.maxReads}"
        }

        return([ chrom, start, stop, numReads])
    }.set{ targets }

process fastq_merge_bam_index {
    // merge multiple R1 and R2 fastq files (e.g. split by lane) into a single fastq each
    input:
    set val(sampleID), file(fastq_r1: "*"), file(fastq_r2: "*"), file(bam) from samples_R1_R2

    output:
    set val(sampleID), file("${merged_fastq_R1}"), file("${merged_fastq_R2}"), file(bam), file("${bai}") into samples_fastq_merged

    script:
    prefix = "${sampleID}"
    merged_fastq_R1 = "${prefix}_R1.fastq.gz"
    merged_fastq_R2 = "${prefix}_R2.fastq.gz"
    bai = "${bam}.bai"
    """
    cat ${fastq_r1} > "${merged_fastq_R1}"
    cat ${fastq_r2} > "${merged_fastq_R2}"
    samtools index "${bam}"
    """
}

samples_fastq_merged.combine(targets).set{ samples_fastq_merged_targets }
// .subscribe { println "${it}" }

process get_qnames {
    input:
    set val(sampleID), file(fastq_R1), file(fastq_R2), file(bam), file(bai), val(chrom), val(start), val(stop), val(numReads) from samples_fastq_merged_targets

    output:
    set val(sampleID), file(fastq_R1), file(fastq_R2), val(chrom), val(start), val(stop), val(numReads), file("${output_file}") into samples_qnames

    script:
    prefix = "${sampleID}.${chrom}.${start}.${stop}"
    output_file = "${prefix}.qnames.txt"
    """
    get_qnames.py \
    "${bam}" \
    "${chrom}" \
    "${start}" \
    "${stop}" \
    "${numReads}" \
    "${output_file}"
    """
}

samples_qnames.map { sampleID, fastq_R1, fastq_R2, chrom, start, stop, numReads, qnames_txt ->
    // group fastq R1 and R2 with labels to process them individually
    return([ sampleID, chrom, start, stop, numReads, qnames_txt, [ ['R1', fastq_R1], ['R2', fastq_R2] ] ])
    }
    .transpose()
    .map { sampleID, chrom, start, stop, numReads, qnames_txt, fastq_list ->
        def fastq_label = fastq_list[0]
        def fastq = fastq_list[1]
        return([ sampleID, chrom, start, stop, numReads, qnames_txt, fastq_label, fastq ])
    }
    .set { samples_qnames_per_fastq }

process subset_fastq {
    input:
    set val(sampleID), val(chrom), val(start), val(stop), val(numReads), file(qnames_txt), val(fastq_label), file(fastq) from samples_qnames_per_fastq

    script:
    prefix = "${sampleID}.${chrom}.${start}.${stop}.${fastq_label}"
    output_file = "${prefix}.fastq.gz"
    """
    subset_fastq.py \
    "${fastq}" \
    "${qnames_txt}" \
    "${output_file}"
    """
}
