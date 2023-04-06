version development

import "https://raw.githubusercontent.com/antonkulaga/bioworkflows/main/common/files.wdl" as files
#NOT YET WORKING!!!
workflow consensus
{
    input {
        File reference_fasta
        File bam
        String destination
    }

    call make_consensus {
        input:
    }

    call files.copy as copy_consensus {
        input:
            destination = destination,
            files = [samtools_fastq.out, fastq_2_fasta.out]
    }

    output {
        File fastq =  copy_consensus.out[0]
        File fasta =  copy_consensus.out[1]
    }

}

task samtools_fastq {
    input {
        File reference_fasta
        File bam
        String name
    }

    command {
        samtools mpileup -f ~{reference_fasta} ~{bam} | bcftools view -cg - | vcfutils.pl vcf2fq > ~{name}.fastq
    }

    runtime {
        docker: "pegi3s/samtools_bcftools:latest"
    }

    output {
        File out = name + ".fastq"
    }
}

task fastq_2_fasta {
    input {
        File fastq
    }

    command {
        seqtk seq -aQ64 -q20 -n N ~{fastq} > ~{basename(fastq, ".fastq")}.fasta
    }

    runtime {
        docker: "quay.io/biocontainers/seqtk:1.3--h7132678_4"
    }

    output {
        File out = basename(fastq, ".fastq")
    }
}