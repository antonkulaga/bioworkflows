version development

# production version
import "https://raw.githubusercontent.com/antonkulaga/bioworkflows/main/quality/clean_reads.wdl" as cleaner

#local debug version (uncomment for debugging and comment production version)
#import "../quality/clean_reads.wdl" as cleaner

workflow download_run{
    input {
        String layout
        String run
        String folder
        Boolean copy_cleaned = false
        Int extract_threads = 4
        Boolean aspera_download = true
        Boolean skip_technical = true
        Boolean original_names = false
    }
    Boolean is_paired = (layout != "SINGLE")

    call download { input: sra = run, aspera_download = aspera_download }
    call extract {input: sra = download.out, is_paired = is_paired, threads = extract_threads, skip_technical = skip_technical, original_names = original_names}
    call cleaner.clean_reads as clean_reads { input: run = run, folder = folder, reads = extract.out, copy_cleaned = copy_cleaned, is_paired = is_paired}

    output {
        CleanedRun out = clean_reads.out
    }
}


task download {
    input {
        String sra
        Boolean aspera_download
    }
    #prefetch --ascp-path "/root/.aspera/connect/bin/ascp|/root/.aspera/connect/etc/asperaweb_id_dsa.openssh" --force yes -O results ~{sra}
    command {
        ~{if(aspera_download) then "download_sra_aspera.sh " else "prefetch -X 9999999999999 --force yes -O results -t http "} ~{sra}
    }

    #https://github.com/antonkulaga/biocontainers/tree/master/downloaders/sra

    runtime {
        docker: "quay.io/comp-bio-aging/download_sra:latest"
        maxRetries: 1
    }

    output {
        File? a = "results" + "/" + sra + ".sra"
        File? b = "results" + "/" + sra + "/" + sra + ".sra"
        File out = select_first([a, b])
     }
}

task extract {
    input {
        File sra
        Boolean is_paired
        Boolean skip_technical
        Int threads
        Boolean original_names = false

    }

    String name = basename(sra, ".sra")
    String folder = "extracted"
    String prefix = folder + "/" + name

    #see https://github.com/ncbi/sra-tools/wiki/HowTo:-fasterq-dump for docs

    command {
        ~{if(original_names) then "fastq-dump --origfmt " else "fasterq-dump "+ "--threads " + threads +" --progress "} --outdir ~{folder} --split-files ~{if(skip_technical) then "--skip-technical" else (if(original_names) then "" else "--include-technical")} ~{sra}
    }

    runtime {
        docker: "quay.io/comp-bio-aging/download_sra:latest"
        maxRetries: 2
    }

    output {
        Array[File] out = glob(prefix+"*")
        #Array[File] out = if(is_paired) then [prefix + "_1.fastq",  prefix + "_2.fastq"] else [prefix + ".fastq"]
     }
}