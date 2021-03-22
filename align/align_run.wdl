version development

import "https://raw.githubusercontent.com/antonkulaga/bioworkflows/main/download/extract_run.wdl" as extractor

workflow align_run {

    input {
        Array[File] reads
        File reference
        String name
        Int max_memory_gb = 42
        Int align_threads = 12
        Int sort_threads = 12
        String destination
    }

    call minimap2 {
        input:
            reads = reads,
            reference = reference,
            name = name,
            threads = align_threads,
            max_memory = max_memory_gb
    }

    call sambamba_sort {
        input:
            bam = minimap2.bam,
            threads = sort_threads
    }

    call extractor.copy as copy_sorted_bam{
        input:
            destination = destination,
            files = [sambamba_sort.out, sambamba_sort.bai]
    }
}

task minimap2 {
    input {
        Array[File] reads
        File reference
        String name
        Int threads
        Int max_memory
    }

    #TODO for readgroups investigate https://angus.readthedocs.io/en/2017/Read_group_info.html

    command {
        minimap2 -R '@RG\tID:~{name}' -ax sr  -t ~{threads} -2 ~{reference} ~{sep=' ' reads} | samtools view -bS - > ~{name}.bam
    }

    runtime {
        docker_memory: "~{max_memory}G"
        docker_cpu: "~{threads+1}"
        docker: "quay.io/comp-bio-aging/minimap2:latest"
        maxRetries: 2
    }

    output {
        File bam = name + ".bam"
    }
}

task sambamba_sort{
    input {
        File bam
        Int threads
        Int gb_per_thread = 3
    }

    String name = basename(bam, ".bam")

    command {
        ln -s ~{bam} ~{basename(bam)}
        sambamba sort -m ~{gb_per_thread}G -t ~{threads} -p ~{basename(bam)}
    }

    runtime {
        docker: "quay.io/biocontainers/sambamba:0.8.0--h984e79f_0"
        maxRetries: 1
        docker_memory: "~{gb_per_thread * (threads+1)}G"
        docker_cpu: "~{threads+1}"
        docker_swap: "~{gb_per_thread * (threads+1) * 2}G"
    }

    output {
        File out = name + ".sorted.bam"
        File bai = name + ".sorted.bam.bai"
    }
}