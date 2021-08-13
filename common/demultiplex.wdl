version development

import "https://raw.githubusercontent.com/antonkulaga/bioworkflows/main/common/files.wdl" as files


workflow demultiplex {
    input {
        File barcodes
        Array[File] reads
        String destination
    }

    call cutadapt {
        input:
            barcodes = barcodes,
            reads = reads
    }

    call files.copy as copy {
        input:
            destination = destination,
            files = cutadapt.out
    }

    output {
        Array[File] out = copy.out
    }

}

task cutadapt{
    input {
        File barcodes
        Array[File] reads
    }

    command <<<
        cutadapt -e 0.15 --no-indels -g file:~{barcodes} -o trimmed-{name}_1.fastq -p trimmed-{name}_2.fastq ~{sep=" " reads}
    >>>

    runtime {
        docker: "quay.io/biocontainers/cutadapt:3.4--py39h38f01e4_1"
    }

    output {
        Array[File] out = glob("*.fastq")
    }
}