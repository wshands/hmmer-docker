task hmmerTask {
  String hmmerCommand
  File DBFile
  File sequenceFile
  String outputFileName
  String? options
  Int preemptibleTries
  Int maxRetries
  Int numCPUs
  Float memory
  Float diskSize
  String dockerImageName

  command {
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

      case ${hmmerCommand} in
        "hmmscan")
          hmmpress ${DBFile}
          hmmscan ${options} ${DBFile} ${sequenceFile} > ${outputFileName}
          ;;
        "hmmsearch")
          hmmsearch ${options} ${DBFile} ${sequenceFile} > ${outputFileName}
          ;;
        "phmmer")
          phmmer ${options} ${sequenceFile} ${DBFile} > ${outputFileName}
          ;;
        *)
          echo "HMMER command ${hmmerCommand} is not known"
      esac
  }
  output {
    File outputFile = "${outputFileName}"
}

 runtime {
    maxRetries: maxRetries
    preemptible: preemptibleTries
    memory: sub(memory, "\\..*", "") + " GB"
    cpu: sub(numCPUs, "\\..*", "")
    disks: "local-disk " + sub(diskSize, "\\..*", "") + " HDD"
    zones: "us-central1-a us-central1-b us-east1-d us-central1-c us-central1-f us-east1-c"
    docker: dockerImageName
  }
}

workflow hmmer {
  String hmmerCommand
  String? options
  File DBFile
  File sequenceFile
  String? dockerImageName
  String? outputFileName

  Int? preemptibleTries
  Int preemptibleTriesDefault = select_first([preemptibleTries, 3])
  Int? maxRetries
  Int maxRetriesDefault = select_first([maxRetries, 3])
  Int? numCPUs
  Int numCPUsDefault = select_first([numCPUs, 4])
  Float? memory
  Float memoryDefault = select_first([memory, 10])

  # Optional input to increase all disk sizes in case of outlier sample with strange size behavior
  Int? increaseDiskSize

  # Some tasks need wiggle room, and we also need to add a small amount of disk to prevent getting a
  # Cromwell error from asking for 0 disk when the input is less than 1GB
  Int additionalDisk = select_first([increaseDiskSize, 20])

  String dockerImageNameDefault = select_first([dockerImageName, "quay.io/wshands/hmmer-docker:feature_hmmerdockernew"  ])
  String outputFileNameDefault = select_first([outputFileName, "myHMMER_${hmmerCommand}.txt"  ])

  # Get the size of the standard reference file
  # Calling size seems to make the https input URL fail - at least on a Mac
  #Float fileDiskSize = size(DBFile, "GB") + size(sequenceFile, "GB")

  call hmmerTask { input:
                    hmmerCommand = hmmerCommand,
                    DBFile = DBFile,
                    options = options,
                    sequenceFile = sequenceFile,
                    outputFileName = outputFileNameDefault,
                    diskSize = additionalDisk,
                    preemptibleTries = preemptibleTriesDefault,
                    maxRetries = maxRetriesDefault,
                    numCPUs = numCPUsDefault,
                    memory = memoryDefault,
                    #diskSize = fileDiskSize + additionalDisk,
                    dockerImageName = dockerImageNameDefault
       }

  meta {
      author : "Walt Shands"
      email : "wshands@gmail.com"
      description: "This is the workflow WDL for HMMER"
   }

  output {
    File hmmerOutput = hmmerTask.outputFile
  }
}

