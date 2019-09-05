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
    String dfamtbloutFileName
    String pfamtbloutFileName
    String aliscoresoutFileName
    String chkhmmFileName
    String chkaliFileName
    String hmmoutFileName

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
              printf "Option is not in options string yet\n"
              # test if the length of the string is non zero
              if [[ -n "~{dollar}{fileName}" ]]
              then
                  # The option output file name has been provided as an individual input
                  # (It could be the default name or one input by the user)
                  # E.g. tbloutFileName is set
                  printf "Setting option ~{dollar}{option} file to ~{dollar}{fileName} in options string\n"
                  commandOptions="~{dollar}{commandOptions} ~{dollar}{option} ~{dollar}{fileName}"
              else
                  # We should never get here because we provide a default option file output name!!!
                  printf "WARNING: Default file name for option ~{dollar}{option} not in options string not provided\n"
              fi
          else
              printf "Option is in options string"
              # E.g. --tblout is in the command options string
              # test if the length of the string is non zero
              if [[ -n "~{dollar}{fileName}" ]]
              then
                  # The option output file name variable has been set by the user
                  # E.g. tbloutFileName is set
                  # so extract that name and use it as the name of the output file
                  # the WDL code will try to find
                  printf "Setting option ~{dollar}{option} file to ~{dollar}{fileName} in options string\n"
                  #https://stackoverflow.com/questions/14194702/replace-substring-with-sed
                  commandOptions=$(echo "~{dollar}{commandOptions}" | sed "s/~{dollar}{option}[[:space:]+][^[:space:]]*/~{dollar}{option} ~{dollar}{fileName}/g")
              else
                  # We should never get here because we provide a default option file output name!!!$
                  printf "WARNING: Default file name for option ~{dollar}{option} in options string not provided\n"
              fi
          fi
          alloptions="~{dollar}{commandOptions}"
      }

      MESSAGE="If this text is present it means HMMER did not write anything"
      MESSAGE="$MESSAGE to this file; probably because ~{hmmerCommand} does not support the option that"
      MESSAGE="$MESSAGE generates this file as an output."
          echo "~{dollar}{MESSAGE}"  > "~{multipleAlignmentFileName}"

      SetOptionOutputFile "~{dollar}{alloptions}" "-o" "~{outputFileName}"

      # Initialize output files
      echo "~{dollar}{MESSAGE}"  > "~{multipleAlignmentFileName}"
      echo "~{dollar}{MESSAGE}"  > "~{tbloutFileName}"
      echo "~{dollar}{MESSAGE}"  > "~{domtbloutFileName}"
      echo "~{dollar}{MESSAGE}"  > "~{dfamtbloutFileName}"
      echo "~{dollar}{MESSAGE}"  > "~{pfamtbloutFileName}"
      echo "~{dollar}{MESSAGE}"  > "~{aliscoresoutFileName}"
      echo "~{dollar}{MESSAGE}"  > "~{chkhmmFileName}"
      echo "~{dollar}{MESSAGE}"  > "~{chkaliFileName}"
      echo "~{dollar}{MESSAGE}"  > "~{hmmoutFileName}"

      case ~{hmmerCommand} in
        "hmmscan")
          SetOptionOutputFile "~{dollar}{alloptions}" "--tblout" "~{tbloutFileName}"
          SetOptionOutputFile "~{dollar}{alloptions}" "--domtblout" "~{domtbloutFileName}"
          SetOptionOutputFile "~{dollar}{alloptions}" "--pfamtblout" "~{pfamtbloutFileName}"
          hmmpress ~{dollar}{unzippedDBFile}
          hmmscan  ~{dollar}{alloptions} ~{dollar}{unzippedDBFile} ~{dollar}{unzippedSequenceFile}
          ;;
        "nhmmscan")
          SetOptionOutputFile "~{dollar}{alloptions}" "--tblout" "~{tbloutFileName}"
          SetOptionOutputFile "~{dollar}{alloptions}" "--dfamtblout" "~{dfamtbloutFileName}"
          SetOptionOutputFile "~{dollar}{alloptions}" "--aliscoresout" "~{aliscoresoutFileName}"
          hmmpress ~{dollar}{unzippedDBFile}
          nhmmscan  ~{dollar}{alloptions} ~{dollar}{unzippedDBFile} ~{dollar}{unzippedSequenceFile}
          ;;
        "nhmmer")
          SetOptionOutputFile "~{dollar}{alloptions}" "-A" "~{multipleAlignmentFileName}"
          SetOptionOutputFile "~{dollar}{alloptions}" "--tblout" "~{tbloutFileName}"
          SetOptionOutputFile "~{dollar}{alloptions}" "--dfamtblout" "~{dfamtbloutFileName}"
          SetOptionOutputFile "~{dollar}{alloptions}" "--aliscoresout" "~{aliscoresoutFileName}"
          SetOptionOutputFile "~{dollar}{alloptions}" "--hmmout" "~{hmmoutFileName}"
          hmmpress ~{dollar}{unzippedDBFile}
          nhmmer  ~{dollar}{alloptions} ~{dollar}{unzippedDBFile} ~{dollar}{unzippedSequenceFile}
          ;;
        "hmmsearch")
          SetOptionOutputFile "~{dollar}{alloptions}" "-A" "~{multipleAlignmentFileName}"
          SetOptionOutputFile "~{dollar}{alloptions}" "--tblout" "~{tbloutFileName}"
          SetOptionOutputFile "~{dollar}{alloptions}" "--domtblout" "~{domtbloutFileName}"
          SetOptionOutputFile "~{dollar}{alloptions}" "--pfamtblout" "~{pfamtbloutFileName}"
          hmmsearch  ~{dollar}{alloptions} ~{dollar}{unzippedDBFile} ~{dollar}{unzippedSequenceFile}
          ;;
        "phmmer")
          SetOptionOutputFile "~{dollar}{alloptions}" "-A" "~{multipleAlignmentFileName}"
          SetOptionOutputFile "~{dollar}{alloptions}" "--tblout" "~{tbloutFileName}"
          SetOptionOutputFile "~{dollar}{alloptions}" "--domtblout" "~{domtbloutFileName}"
          SetOptionOutputFile "~{dollar}{alloptions}" "--pfamtblout" "~{pfamtbloutFileName}"
          phmmer  ~{dollar}{alloptions} ~{dollar}{unzippedSequenceFile} ~{dollar}{unzippedDBFile}
          ;;
        "jackhmmer")
          SetOptionOutputFile "~{dollar}{alloptions}" "-A" "~{multipleAlignmentFileName}"
          SetOptionOutputFile "~{dollar}{alloptions}" "--tblout" "~{tbloutFileName}"
          SetOptionOutputFile "~{dollar}{alloptions}" "--domtblout" "~{domtbloutFileName}"
          SetOptionOutputFile "~{dollar}{alloptions}" "--chkhmm" "~{chkhmmFileName}"
          SetOptionOutputFile "~{dollar}{alloptions}" "--chkali" "~{chkaliFileName}"
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

    File outputFile = "~{outputFileName}"
    File multipleAlignmentFile = "~{multipleAlignmentFileName}"
    File tbloutFile =  "~{tbloutFileName}"
    File domtbloutFile = "~{domtbloutFileName}"
    File dfamtbloutFile = "~{dfamtbloutFileName}"
    File pfamtbloutFile = "~{pfamtbloutFileName}"
    File aliscoresoutFile = "~{aliscoresoutFileName}"
    File chkhmmFile = "~{chkhmmFileName}"
    File chkaliFile = "~{chkaliFileName}"
    File hmmoutFile = "~{hmmoutFileName}"

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
      String dfamTblOutFileName = "~{hmmerCommand}_dfamtblout.txt"
      String pfamTblOutFileName = "~{hmmerCommand}_pfamtblout.txt"
      String aliscoresoutFileName = "~{hmmerCommand}_aliscoresout.txt"
      String chkhmmFileName = "~{hmmerCommand}_chkhmm.txt"
      String chkaliFileName = "~{hmmerCommand}_chkali.txt"
      String hmmoutFileName = "~{hmmerCommand}_hmmout.txt"

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
                    dfamtbloutFileName = dfamTblOutFileName,
                    pfamtbloutFileName = pfamTblOutFileName,
                    aliscoresoutFileName = aliscoresoutFileName,
                    chkhmmFileName = chkhmmFileName,
                    chkaliFileName = chkaliFileName,
                    hmmoutFileName = hmmoutFileName,

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

    File hmmerOutput = hmmerTask.outputFile
    File multipleAlignmentFile = hmmerTask.multipleAlignmentFile
    File tbloutFileFile = hmmerTask.tbloutFile
    File domtbloutFile = hmmerTask.domtbloutFile
    File dfamtbloutFile = hmmerTask.dfamtbloutFile
    File pfamtbloutFile = hmmerTask.pfamtbloutFile
    File aliscoresoutFile = hmmerTask.aliscoresoutFile
    File chkhmmFile = hmmerTask.chkhmmFile
    File chkaliFile = hmmerTask.chkaliFile
    File hmmoutFile = hmmerTask.hmmoutFile

    String hmmerStdout = hmmerTask.hmmerStdout
  }
}

