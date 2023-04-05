version development

import "https://raw.githubusercontent.com/antonkulaga/bioworkflows/main/common/files.wdl" as files


workflow vsearch {
input{
  Int threads = 0
  File db
  File query
  String result_name
  String results_folder
  Float identity = 0.45
}

  call global_search {
      input:
        threads = threads,
        database = db,
        name = result_name,
        query = query,
        identity = identity
    }

  call files.copy as copy_results {
    input:
        files = [global_search.out],
        destination = results_folder
  }

  output {
       File out = copy_results.out[0]
  }

}

task global_search {
input{
    File query
    File database
    String name
    Int threads
    Float identity
}

    command {
     vsearch --usearch_global ~{query} --db ~{database} --blast6out ~{name}.blast6  --threads ~{threads} --id ~{identity}
    }
     #vsearch --usearch_global ${query} --db ${database} --threads ${threads} --id ${identity} --alnout alnout.txt


  runtime {
    docker: "quay.io/comp-bio-aging/vsearch:latest"
  }

  output {
       File out = name + ".blast6"
  }

}