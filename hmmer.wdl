task hmmerTask {
  String hmmerCommand
  File DBFile
  File sequenceFile
  String outputFileName
  String? options

  #String aMultipleAlignmentsFileName
  #String tbloutFileName
  #String domtbloutFileName
  #String pfamtbloutFileName

  Int preemptibleTries
  Int maxRetries
  Int numCPUs
  Float memory
  Float diskSize
  String dockerImageName

  # We have to use a trick to make Cromwell
  # skip substitution when using the bash ${<variable} syntax
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
      gzip -t ${DBFile} 2>/dev/null
      # If it is gzipped then unzip it; phmmer requires it be unzipped
      if [[ $? -eq 0 ]]
      then
         unzippedDBFile="unzippedDBFile"
         gunzip -c ${DBFile} > ${dollar}{unzippedDBFile}
      else
         unzippedDBFile="${DBFile}"
      fi
      # to exit with a non-zero status, or zero if all commands of the pipeline exit
      set -o pipefail
      # cause a bash script to exit immediately when a command fails
      set -e

      case ${hmmerCommand} in
        "hmmscan")
          hmmpress ${dollar}{unzippedDBFile}
          hmmscan -o ${outputFileName} ${options} ${dollar}{unzippedDBFile} ${sequenceFile}
          ;;
        "nhmmscan")
          hmmpress ${dollar}{unzippedDBFile}
          nhmmscan -o ${outputFileName} ${options} ${dollar}{unzippedDBFile} ${sequenceFile}
          ;;
        "nhmmer")
          hmmpress ${dollar}{unzippedDBFile}
          nhmmer -o ${outputFileName} ${options} ${dollar}{unzippedDBFile} ${sequenceFile}
          ;;
        "hmmsearch")
          hmmsearch -o ${outputFileName} ${options} ${dollar}{unzippedDBFile} ${sequenceFile}
          ;;
        "phmmer")
          phmmer -o ${outputFileName} ${options} ${sequenceFile} ${dollar}{unzippedDBFile}
          ;;
        "jackhmmer")
          jackhmmer -o ${outputFileName} ${options} ${sequenceFile} ${dollar}{unzippedDBFile}
          ;;
        *)
          echo "HMMER command ${hmmerCommand} is not known"
      esac
  >>>
  output {
    File outputFile = "${outputFileName}"
    Array[File] allOutputFiles = glob("*.*")

    #File aMultipleAlignmentsFile = "${aMultipleAlignmentsFileName}"
    #File tbloutFile = "${tbloutFileName}"
    #File domtbloutFile = "${domtbloutFileName}"
    #File pfamtbloutFile = "${pfamtbloutFileName}"
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

  #String? aMultipleAlignments
  #String? tblout
  #String? domtblout
  #String? pfamtblout

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

  # Concatenate all the output table file options to the other options
  #String allOptions1 = select_first([options, ""])
  #String allOptions2 =  allOptions1 + if (defined(aMultipleAlignments)) then " -A ${aMultipleAlignments}" else " -A ${hmmerCommand}_multiplealignments.txt"
  #String allOptions3 = allOptions2 + if (defined(tblout)) then " --tblout ${tblout}" else " --tblout ${hmmerCommand}_tblout.txt"
 # String allOptions4 = allOptions3 + if (defined(domtblout)) then " --domtblout ${domtblout}" else " --domtblout ${hmmerCommand}_domtblout.txt"
  #String allOptions = allOptions4 + if (defined(pfamtblout)) then " --pfamtblout ${pfamtblout}" else " --pfamtblout ${hmmerCommand}_pfamtblout.txt"

  #String defaultMultipleAlignmentsFileName = select_first([aMultipleAlignmentsFileName, 
  # Get the size of the standard reference file
  # Calling size seems to make the https input URL fail - at least on a Mac
  #Float fileDiskSize = size(DBFile, "GB") + size(sequenceFile, "GB")

  call hmmerTask { input:
                    hmmerCommand = hmmerCommand,
                    DBFile = DBFile,
                    options = options,

                    #aMultipleAlignmentsFileName = aMultipleAlignments,
                    #tbloutFileName = tblout,
                    #domtbloutFileName = domtblout,
                    #pfamtbloutFileName = pfamtblout,

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
    Array[File] allOutputFiles = hmmerTask.allOutputFiles

    #File aMultipleAlignmentsFile = hmmerTask.aMultipleAlignmentsFile
    #File tbloutFile = hmmerTask.tbloutFile
    #File domtbloutFile = hmmerTask.domtbloutFile
    #File pfamtbloutFile = hmmerTask.pfamtbloutFile
  }
}

