version development

# production configuration
import "https://raw.githubusercontent.com/antonkulaga/bioworkflows/main/common/files.wdl" as files

# debug local configuration (uncomment for debugging)
#import "../common/files.wdl" as files


struct CleanedRun {
    String run
    String folder
    Boolean is_paired
    Array[File] cleaned_reads
    Array[File] report
}

workflow clean_reads {
    input {
        Array[File] reads
        Boolean is_paired
        String folder
        Boolean copy_cleaned
        String run = "" #sequencing run id (optional)
    }

    call fastp { input: reads = reads, is_paired = is_paired }
    call files.copy as copy_report {
        input:
            destination = folder + "/report",
            files = [fastp.report_json, fastp.report_html]
    }
    if(copy_cleaned)
    {
        call files.copy as copy_cleaned_reads {
            input:
                destination = folder + "/reads",
                files = fastp.reads_cleaned
        }
    }

    output {
        CleanedRun out = object {run: run, folder: folder, is_paired: is_paired, cleaned_reads: fastp.reads_cleaned, report: copy_report.out}
    }
}

task fastp {
    input {
        Array[File] reads
        Boolean is_paired
    }

    command {
        fastp --cut_front --cut_tail --cut_right --trim_poly_g --trim_poly_x --overrepresentation_analysis \
        -i ~{reads[0]} -o ~{basename(reads[0], ".fastq.gz")}_cleaned.fastq.gz \
        ~{if( is_paired ) then "--detect_adapter_for_pe " + "--correction -I "+reads[1]+" -O " + basename(reads[1], ".fastq.gz") +"_cleaned.fastq.gz" else ""}
    }

    runtime {
        docker: "quay.io/biocontainers/fastp:0.22.0--h2e03b76_0"
    }

    output {
        File report_json = "fastp.json"
        File report_html = "fastp.html"
        Array[File] reads_cleaned = if( is_paired )
                                    then [basename(reads[0], ".fastq.gz") + "_cleaned.fastq.gz", basename(reads[1], ".fastq.gz") + "_cleaned.fastq.gz"]
                                    else [basename(reads[0], ".fastq.gz") + "_cleaned.fastq.gz"]
    }
}