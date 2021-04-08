version development

# production version
import "https://raw.githubusercontent.com/antonkulaga/bioworkflows/main/common/files.wdl" as files

#local debug version (uncomment for debugging and comment the production version)
#import "../common/files.wdl" as files

struct AlignedRun {
    String run
    String folder
    File bam
    File bai
    File flagstat
    String aligner
}

workflow align_reads {

    input {
        Array[File] reads
        File reference
        String run
        Int max_memory_gb = 42
        Int align_threads = 12
        Int sort_threads = 12
        Int gb_per_thread = 3
        Boolean markdup = false
        String destination
        String aligner = "minimap2"
        Boolean markdup = false
        Int compression = 9
    }

    call minimap2 {
        input:
            reads = reads,
            reference = reference,
            name = run,
            threads = align_threads,
            max_memory = max_memory_gb
    }

    call sambamba_sort {
        input:
            unsorted_bam = minimap2.bam,
            threads = sort_threads,
            gb_per_thread = gb_per_thread,
            markdup = markdup,
            compression = compression
    }

    call files.copy as copy_sorted_bam{
        input:
            destination = destination,
            files = [sambamba_sort.sorted_bam, sambamba_sort.sorted_bai, sambamba_sort.flagstat]
    }

    output {
       AlignedRun out = object {run: run, folder: destination, bam: copy_sorted_bam.out[0], bai: copy_sorted_bam.out[1], flagstat: copy_sorted_bam.out[2], aligner: aligner}
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

task sambamba_sort {
    input {
        File unsorted_bam
        Int threads
        Int gb_per_thread = 3
        Int compression = 9
        Boolean markdup = false
    }

    String name = basename(unsorted_bam, ".bam")
    String suffix = if(markdup) then ".sorted_markdup.bam" else ".sorted.bam"

    command {
        ln -s ~{unsorted_bam} ~{basename(unsorted_bam)}
        sambamba sort -l ~{compression} -m ~{gb_per_thread}G -t ~{threads} -p ~{basename(unsorted_bam)}
        ~{if(markdup) then "sambamba markdup -t " + threads + " -l " + compression +" -p " + name + ".sorted.bam " + name + suffix else ""}
        sambamba flagstat -t ~{threads} -p ~{name + suffix} > ~{name + suffix + ".flagstat"}
    }

    runtime {
        docker: "quay.io/biocontainers/sambamba:0.8.0--h984e79f_0"
        maxRetries: 1
        docker_memory: "~{gb_per_thread * (threads+1)}G"
        docker_cpu: "~{threads+1}"
        docker_swap: "~{gb_per_thread * (threads+1) * 2}G"
    }

    output {
        File sorted_bam = name + suffix
        File sorted_bai = name + suffix + ".bai"
        File flagstat = name + suffix + ".flagstat"
    }
}