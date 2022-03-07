version development

workflow pasta {

    input {
        File fasta #/data/samples/AIRR-Seq/OURS/S5205Nr1/translations/
    }

    call align {
        input: fasta = fasta
    }

}

    
task align {

    input {
        File fasta
        String datatype = "protein"
    }

    command {
        run_pasta.py --input ~{fasta} --datatype ~{datatype}
    }

    runtime {
        docker: "smirarab/pasta:latest"
    }

    output {

    }
}