version 1.0
task hmmerTask {
  input {
    String hmmerCommand
    File DBFile
    File sequenceFile
    String? options

    String outputFileName
    String multipleAlignmentFileName
    String tbloutFileName
    String domtbloutFileName
    String pfamtbloutFileName

    Int preemptibleTries
    Int maxRetries
    Int numCPUs
    Float memory
    Float diskSize
    String dockerImageName
 }

  # We have to use a trick to make Cromwell
  # skip substitution when using the bash ~{<variable} syntax
  # See https://gatkforums.broadinstitute.org/wdl/discussion/comment/44570#Comment_44570
  String dollar = "$"
  command <<<
      # Set the exit code of a pipeline to that of the rightmost command
      # to exit with a non-zero status, or zero if all commands of the pipeline exit
      set -o pipefail
      # cause a bash script to exit immediately when a command fails
      set -e
      # cause the bash shell to treat unset variables as an error and exit immediately
      set -u
      # echo each line of the script to stdout so we can see what is happening
      set -o xtrace
      #to turn off echo do 'set +o xtrace'

      # Check to see whether the  DB file is gzipped
      # Turn off exit on command failure so we can continue
      # when the gzip test fails for a non gzipped file
      set +o pipefail
      set +e
      gzip -t ~{DBFile} 2>/dev/null
      # If it is gzipped then unzip it; e.g. phmmer requires it be unzipped
      if [[ $? -eq 0 ]]
      then
         unzippedDBFile="unzippedDBFile"
         gunzip -c ~{DBFile} > ~{dollar}{unzippedDBFile}
      else
         unzippedDBFile="~{DBFile}"
      fi

      gzip -t ~{sequenceFile} 2>/dev/null
      # If it is gzipped then unzip it; e.g. hmmscan requires it be unzipped
      if [[ $? -eq 0 ]]
      then
         unzippedSequenceFile="unzippedSequenceFile"
         gunzip -c ~{sequenceFile} > ~{dollar}{unzippedSequenceFile}
      else
         unzippedSequenceFile="~{sequenceFile}"
      fi

      # to exit with a non-zero status, or zero if all commands of the pipeline exit
      set -o pipefail
      # cause a bash script to exit immediately when a command fails
      set -e

      alloptions="~{options}"

      SetOptionOutputFile()
      {
          commandOptions=$1
          option=$2
          fileName=$3
          # If the output file option is not in the options string
          # use the default file name or the one the user
          # placed in the named variable
          if [[ ! "~{dollar}{commandOptions}" =~ "~{dollar}{option} " ]]
          then
              # E.g. --tblout is not in the command options string
              printf "Option is not in options string"
              # test if the length of the string is non zero
              if [[ -n "~{dollar}{fileName}" ]]
              then
                  # The option output file name variable has been set by the user
                  # E.g. tbloutFileName is set
                  printf "Setting option ~{dollar}{option} file to %s in options string\n" "~{dollar}{fileName}"
                  commandOptions="~{dollar}{commandOptions} ~{dollar}{option} ~{dollar}{fileName}"
              else
                  # There is no output file set in the command options string
                  # and the user has not set the option output file variable
                  # so we must set the option output file to a default file name
                  # since WDL cannot use an optional output file variable
                  fileName="~{hmmerCommand}~{dollar}{option}OutputFile.txt"
                  printf "Setting option ~{dollar}{option} file to %s in options string\n" "~{dollar}{fileName}"
                  commandOptions="~{dollar}{commandOptions} ~{dollar}{option} ~{dollar}{fileName}"
              fi
          else
              printf "Option is in options string"
              # E.g. --tblout is in the command options string
              # test if the length of the string is non zero
              if [[ -n "~{dollar}{fileName}" ]]
              then
                  # The option output file name variable has been set by the user
                  # E.g. tbloutFileName is set
                  printf "Setting option ~{dollar}{option} file to %s in options string\n" "~{dollar}{fileName}"
                  # E.g. commandOptions="~{dollar}{commandOptions/-A .* /-A ~{multipleAlignmentFileName}}"
                  #https://stackoverflow.com/questions/13210880/replace-one-substring-for-another-string-in-shell-script
                  commandOptions="~{dollar}{commandOptions/~{dollar}{option}[[:space:]+][^[:space:]]*/~{dollar}{option} ~{dollar}{fileName}}"
              else
                  # The output file is set in the command options string
                  # and the user has not set the option output file variable
                  # Find out what the name of the output file is so we can
                  # put it in the output section
                  fileName=$(echo "~{dollar}{commandOptions}" | sed "s/.*~{dollar}{option}[[:space:]+]\([^[:space:]]*\)/\1/g")
                  #commandOptions=$(echo "~{dollar}{commandOptions}" | sed "s/-A[[:space:]+][^[:space:]]*/-A ~{multipleAlignmentFileName}/g")
              fi
          fi
          alloptions="~{dollar}{commandOptions}"
      }

      MESSAGE="If this text is present it means HMMER did not write anything"
      MESSAGE="$MESSAGE to this file; probably because ~{hmmerCommand} does not support the option that"
      MESSAGE="$MESSAGE generates this file as an output."

      # hmmscan does not have the -A option
      if [[ "~{hmmerCommand}" != "hmmscan" ]]
      then
          SetOptionOutputFile "~{dollar}{alloptions}" "-A" "~{multipleAlignmentFileName}"
      else
          echo "~{dollar}{MESSAGE}"  > "~{multipleAlignmentFileName}"
      fi

      SetOptionOutputFile "~{dollar}{alloptions}" "-o" "~{outputFileName}"
      SetOptionOutputFile "~{dollar}{alloptions}" "--tblout" "~{tbloutFileName}"
      SetOptionOutputFile "~{dollar}{alloptions}" "--domtblout" "~{domtbloutFileName}"
      SetOptionOutputFile "~{dollar}{alloptions}" "--pfamtblout" "~{pfamtbloutFileName}"

      case ~{hmmerCommand} in
        "hmmscan")
          hmmpress ~{dollar}{unzippedDBFile}
          hmmscan  ~{dollar}{alloptions} ~{dollar}{unzippedDBFile} ~{dollar}{unzippedSequenceFile}
          ;;
        "nhmmscan")
          hmmpress ~{dollar}{unzippedDBFile}
          nhmmscan  ~{dollar}{alloptions} ~{dollar}{unzippedDBFile} ~{dollar}{unzippedSequenceFile}
          ;;
        "nhmmer")
          hmmpress ~{dollar}{unzippedDBFile}
          nhmmer  ~{dollar}{alloptions} ~{dollar}{unzippedDBFile} ~{dollar}{unzippedSequenceFile}
          ;;
        "hmmsearch")
          hmmsearch  ~{dollar}{alloptions} ~{dollar}{unzippedDBFile} ~{dollar}{unzippedSequenceFile}
          ;;
        "phmmer")
          phmmer  ~{dollar}{alloptions} ~{dollar}{unzippedSequenceFile} ~{dollar}{unzippedDBFile}
          ;;
        "jackhmmer")
          jackhmmer  ~{dollar}{alloptions} ~{dollar}{unzippedSequenceFile} ~{dollar}{unzippedDBFile}
          ;;
        *)
          echo "HMMER command ~{hmmerCommand} is not known"
      esac

      # Print the output to stdout; there should be an output file containing stdout
      # TODO: somehow get Cromwell to include line feeds with line feeds
      # https://unix.stackexchange.com/questions/164508/why-do-newline-characters-get-lost-when-using-command-substitution
      cat "~{outputFileName}"

  >>>
  output {
    Array[File] allOutputFiles = glob("*.txt")

    File multipleAlignmentFile = "~{multipleAlignmentFileName}"
    File tbloutFile =  "~{tbloutFileName}"
    File outputFile = "~{outputFileName}"
    File domtbloutFile = "~{domtbloutFileName}"
    File pfamtbloutFile = "~{pfamtbloutFileName}"

    String hmmerStdout = read_string(stdout())
  }

 runtime {
    maxRetries: maxRetries
    preemptible: preemptibleTries
    memory: memory + " GB"
    cpu: numCPUs
    disks: "local-disk " + ceil(diskSize) + " HDD"
    zones: "us-central1-a us-central1-b us-east1-d us-central1-c us-central1-f us-east1-c"
    docker: dockerImageName
  }
}

workflow hmmer {
  input {
      String hmmerCommand
      String? options
      File DBFile
      File sequenceFile
      String dockerImageName = "quay.io/wshands/hmmer-docker:1.0.0"
      String outputFileName = "~{hmmerCommand}_output.txt"

      # If you provide the -A multiple alignment file name in
      # this variable do not also specify -A in the options variable
      String multipleAlignmentFileName = "~{hmmerCommand}_multiplealignments.txt"
      String tblOutFileName = "~{hmmerCommand}_tblout.txt"
      String domTblOutFileName = "~{hmmerCommand}_domtblout.txt"
      String pfamTblOutFileName = "~{hmmerCommand}_pfamtblout.txt"

      Int preemptibleTries = 1
      Int maxRetries = 0
      Int numCPUs = 4
      Float memory = 10

      # Some tasks need wiggle room, and we also need to add a small amount of disk to prevent getting a
      # Cromwell error from asking for 0 disk when the input is less than 1GB
      Int additionalDisk = 20
  }

  call hmmerTask { input:
                    hmmerCommand = hmmerCommand,
                    DBFile = DBFile,
                    sequenceFile = sequenceFile,

                    options = options,

                    outputFileName = outputFileName,
                    multipleAlignmentFileName = multipleAlignmentFileName,
                    tbloutFileName = tblOutFileName,
                    domtbloutFileName = domTblOutFileName,
                    pfamtbloutFileName = pfamTblOutFileName,

                    diskSize = size(DBFile, "GB") + size(sequenceFile, "GB") + additionalDisk,
                    preemptibleTries = preemptibleTries,
                    maxRetries = maxRetries,
                    numCPUs = numCPUs,
                    memory = memory,
                    dockerImageName = dockerImageName
       }

  meta {
      author : "Walt Shands"
      email : "wshands@gmail.com"
      description: "This is the workflow WDL for HMMER"
   }

  output {
    Array[File] allOutputFiles = hmmerTask.allOutputFiles

    File multipleAlignmentFile = hmmerTask.multipleAlignmentFile
    File hmmerOutput = hmmerTask.outputFile
    File tbloutFileFile = hmmerTask.tbloutFile
    File domtbloutFile = hmmerTask.domtbloutFile
    File pfamtbloutFile = hmmerTask.pfamtbloutFile

    String hmmerStdout = hmmerTask.hmmerStdout
  }
}

