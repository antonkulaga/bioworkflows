version development

# production configuration
import "https://raw.githubusercontent.com/antonkulaga/bioworkflows/main/common/files.wdl" as files
import "https://raw.githubusercontent.com/antonkulaga/bioworkflows/main/download/download_samples.wdl" as samples_downloader
import "https://raw.githubusercontent.com/antonkulaga/bioworkflows/main/align/align_runs.wdl" as runs_aligner

# debug local configuration (uncomment for debugging)
#import  "../common/files.wdl" as files
#import  "../download/download_samples.wdl" as samples_downloader
#import "align_runs.wdl" as runs_aligner

workflow align_samples {
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
        Boolean deep_folder_structure = false

        File reference
        File? reference_index
        Int max_memory_gb = 42
        Int align_threads = 12
        Int sort_threads = 12
        String sequence_aligner = "minimap2"
        Boolean markdup = false
        Int compression = 9

}
    scatter(experiment in experiments) {
        String experiment_title = if(title=="") then "" else  experiment + " - " + title
        call samples_downloader.get_experiment_metadata{
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

        call runs_aligner.align_runs as align_runs{
            input:
                title = title,
                runs = sras,
                experiment_folder = experiment_folder,
                reference = reference,
                reference_index = reference_index,
                key = key,
                extract_threads = extract_threads,
                max_memory_gb = max_memory_gb,
                align_threads = align_threads,
                sort_threads = sort_threads,
                copy_cleaned = copy_cleaned,
                copy_extracted = copy_extracted,
                aspera_download = aspera_download,
                skip_technical = skip_technical,
                original_names = original_names,
                sequence_aligner = sequence_aligner,
                markdup = markdup,
                compression = compression
        }
    }

    output {
        Array[AlignedRun] out = flatten(align_runs.out)
    }

}