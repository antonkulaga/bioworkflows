version development

# production version
import "https://raw.githubusercontent.com/antonkulaga/bioworkflows/main/common/files.wdl" as files
import  "https://raw.githubusercontent.com/antonkulaga/bioworkflows/main/download/download_runs.wdl" as downloader

#local debug version (uncomment for debugging and comment the production version)
#import "../common/files.wdl" as files
#import  "download_runs.wdl" as downloader


workflow download_samples
{
    input {
        Array[String] experiments
        String samples_folder
        String key = "0a1d74f32382b8a154acacc3a024bdce3709"
        Int extract_threads = 4
        Boolean copy_extracted = false
        Boolean copy_cleaned = true
        Boolean experiment_package = false
        String title = ""
        Boolean aspera_download = true
        Boolean skip_technical = true
        Boolean original_names = false
}
    scatter(experiment in experiments) {
        String experiment_title = if(title=="") then "" else  experiment + " - " + title
        call get_experiment_metadata{
            input: experiment = experiment, key = key, experiment_package = experiment_package
        }
        Array[Array[String]] run_data = get_experiment_metadata.runs

        String series = sub(get_experiment_metadata.runs[0][1], ";", "_")
        String series_folder = samples_folder + "/" + series
        String experiment_folder = series_folder + "/" + experiment

        call files.copy as copy_metadata{
            input:
                destination = experiment_folder,
                files = [get_experiment_metadata.experiment_json, get_experiment_metadata.runs_tsv]
        }


        scatter(row in run_data){
            String sras = row[2]
        }

        call downloader.download_runs{
            input:
                title = title,
                runs = sras,
                experiment_folder = experiment_folder,
                key = key,
                extract_threads = extract_threads,
                copy_cleaned = copy_cleaned,
                aspera_download = aspera_download,
                skip_technical = skip_technical,
                original_names = original_names

        }
    }

}

task get_experiment_metadata {

    input {
        String experiment
        String key
        Boolean experiment_package = false
    }

    String runs_path = experiment +"_runs.tsv"
    String runs_tail_path = experiment +"_runs_tail.tsv"
    String runs_head_path = experiment +"_runs_head.tsv"


    command {
        /opt/docker/bin/geo-fetch ~{if(experiment_package) then "bioproject " + experiment + " " else "gsm"} --key ~{key} -e --output ~{experiment}.json --runs ~{runs_path}  ~{experiment}
        head -n 1 ~{runs_path} > ~{runs_head_path}
        tail -n +2 ~{runs_path} > ~{runs_tail_path}
    }

    runtime {
        docker: "quay.io/comp-bio-aging/geo-fetch:0.1.1"
        maxRetries: 6
    }

    output {
        File runs_tsv = runs_path
        File experiment_json = experiment + ".json"
        Array[String] headers = read_tsv(runs_head_path)[0]
        Array[Array[String]] runs = read_tsv(runs_tail_path)
    }
}