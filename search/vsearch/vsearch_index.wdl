version development

import "https://raw.githubusercontent.com/antonkulaga/bioworkflows/main/common/files.wdl" as files


workflow vsearch_index {
input{

  File db
  String name
  String indexes_folder = "/data/indexes/vsearch"
}

  call vsearch_make_index {
    input:
      fasta = db,
      name = name
  }

  call files.copy as copy_results {
    input:
        files = [vsearch_make_index.out],
        destination = indexes_folder
  }

  output {
    Array[File] results = copy_results.out
  }

}

task vsearch_make_index {
    input{
      File fasta
      String name
    }

    command {
        vsearch --makeudb_usearch ~{fasta} --output ~{name}.udb
        chmod -R o+rwx ~{name}.udb
     }

  runtime {
    docker: "quay.io/comp-bio-aging/vsearch:latest"
  }

  output {
       File out = name + ".udb"
       String db_name = name
  }

}