version development

import "https://raw.githubusercontent.com/antonkulaga/bioworkflows/main/common/files.wdl" as files


workflow Diamond_Index {
    input {
        File db
        String name
        String results_folder
    }

  call diamond_index {
    input:
      fasta = db,
      name = name
  }

  call files.copy as copy_results {
    input:
        files = [diamond_index.out],
        destination = results_folder
  }

  output {
    Array[File] results = copy_results.out
  }

}

task diamond_index {

    input {
        File fasta
        String name
    }

    command {
        diamond makedb --in ${fasta} -d ${name}
     }

  runtime {
    docker: "quay.io/comp-bio-aging/diamond:latest"
  }

  output {
       File out = name + ".dmnd"
       String db_name = name
  }

}