version development

# production version
import "https://raw.githubusercontent.com/antonkulaga/bioworkflows/main/common/files.wdl" as files

#local debug version (uncomment for debugging and comment the production version)
#import "../common/files.wdl" as files


workflow bwa_mem2_index {
    input {
        File reference
        String? prefix
        String destination
    }

    call make_index {
        input: reference = reference, prefix = prefix
    }
    call files.copy as copy{
        input: files = make_index.out, destination = destination
    }

    output {
        Array[File] out = copy.out
    }

}

    task make_index {
        input {
            File reference
            String? prefix
        }

        String name = basename(reference)

        command {
            ln -s ~{reference} ~{name}
            bwa-mem2 index ~{"-p " + prefix} ~{name}
        }

        runtime {
            docker: "quay.io/comp-bio-aging/bwa-mem2:latest"
        }

        output {
            Array[File] out = glob(name+"*")
        }
    }