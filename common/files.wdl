version development

task copy {
    input {
        Array[File] files
        String destination
    }

    String where = sub(destination, ";", "_")

    command {
        mkdir -p ~{where}
        cp -L -R -u ~{sep=' ' files} ~{where}
        declare -a files=(~{sep=' ' files})
        for i in ~{"$"+"{files[@]}"};
        do
        value=$(basename ~{"$"}i)
        echo ~{where}/~{"$"}value
        done
    }

    output {
        Array[File] out = read_lines(stdout())
        File destination_folder = destination
    }
}


task merge {
    input {
        Array[File] files
        String output_name
    }

    command {
        cat ~{sep=' ' files} > ~{output_name}
    }

    output { File out = output_name }
}