version development


# production configuration
import "https://raw.githubusercontent.com/antonkulaga/bioworkflows/main/download/download_run.wdl" as downloader

# debug local configuration (uncomment for debugging)
#import "download_run.wdl" as downloader

workflow download_runs{
    input {
        String title = ""
        Array[String] runs
        String experiment_folder
        String key = "0a1d74f32382b8a154acacc3a024bdce3709"
        Int extract_threads = 12
        Boolean copy_extracted = true
        Boolean copy_cleaned = true
        Boolean aspera_download = true
        Boolean skip_technical = true
        Boolean original_names = false
        Boolean deep_folder_structure = true
    }

    scatter(run in runs) {

        call get_meta{
            input:
                sra = run,
                key = key
        }
        Array[File] metas = get_meta.info

        scatter(json in metas) {

            Map[String, String] info = read_json(json)

            String layout = info["LibraryLayout"]
            Boolean is_paired = (layout != "SINGLE")
            String bioproject = info["BioProject"]
            String experiment = info["Experiment"]
            String organism = info["ScientificName"]

            String sra_folder = if(deep_folder_structure) then experiment_folder + "/" + bioproject + "/" + experiment + "/" + run else run


            call downloader.download_run as download_run{
                input:
                    layout = layout,
                    run =  run,
                    folder = sra_folder,
                    copy_cleaned = copy_cleaned,
                    extract_threads = extract_threads,
                    aspera_download = aspera_download,
                    skip_technical = skip_technical,
                    original_names = original_names,
                    copy_extracted = copy_extracted
            }
        }


    }


    output {
        Array[CleanedRun] out = flatten(download_run.out)
    }


}

task get_meta {
    input{
        String sra
        String key
    }

    command {
        set -e
        /opt/docker/bin/geo-fetch sra ~{sra} --key ~{key} --output ~{sra}.flat.json
    }

    runtime {
        docker: "quay.io/comp-bio-aging/geo-fetch:0.1.1"
        maxRetries: 1
    }

    output {
        Array[File] info = glob("*.json")
    }
}