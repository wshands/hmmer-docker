task hmmerTask {
  String hmmerCommand
  File DBFile
  File sequenceFile
  String outputFileName
  String? options

  String aMultipleAlignmentFileName
  #String? options1 = if (defined(aMultipleAlignmentFileName)) then inputOptions + " -A ${aMultipleAlignmentFileName}" else inputOptions

  String tbloutFileName
  #String? options = if (defined(tbloutFileName)) then options1 + " -A ${tbloutFileName}" else options1
  String domtbloutFileName
  String pfamtbloutFileName

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

      # If the output file option is not in the options string
      # use the default file name or the one the user
      # placed in the named variable
      alloptions="${options}"

      SetOptionOutputFile()
      {
          commandOptions=$1
          option=$2
          outputFileName=$3

          if [[ ! "${dollar}{commandOptions}" =~ "${dollar}{option} " ]]
          then
              printf "Option is not in options string"
              # test if the length of the string is non zero
              if [[ -n "${dollar}{outputFileName}" ]]
              then
                  printf "Setting option ${dollar}{option} file to %s in options string\n" ${dollar}{outputFileName}
                  commandOptions="${dollar}{commandOptions} ${dollar}{option} ${dollar}{outputFileName}"
              else
                  outputFileName="${hmmerCommand}_multiplealignments.txt"
                  printf "Setting option ${dollar}{option} file to %s in options string\n" ${dollar}{outputFileName}
                  commandOptions="${dollar}{commandOptions} ${dollar}{option} ${dollar}{outputFileName}"
              fi
          else
              printf "Option is in options string"
              # test if the length of the string is non zero
              if [[ -n "${dollar}{outputFileName}" ]]
              then
                  printf "Setting option ${dollar}{option} file to %s in options string\n" ${dollar}{outputFileName}
                  #commandOptions="${dollar}{commandOptions/-A .* /-A ${aMultipleAlignmentFileName}}"
                  #https://stackoverflow.com/questions/13210880/replace-one-substring-for-another-string-in-shell-script
                  commandOptions="${dollar}{commandOptions/${dollar}{option}[[:space:]+][^[:space:]]*/${dollar}{option} ${dollar}{outputFileName}}"
              else
                  # Find out what the name of the output file is so we can
                  # put it in the output section
                  outputFileName=$(echo "${dollar}{commandOptions}" | sed "s/.*${dollar}{option}[[:space:]+]\([^[:space:]]*\)/\1/g")
                  #commandOptions=$(echo "${dollar}{commandOptions}" | sed "s/-A[[:space:]+][^[:space:]]*/-A ${aMultipleAlignmentFileName}/g")
              fi
          fi
          echo "${dollar}{outputFileName}" > outputFileName"${dollar}{option}".txt

          alloptions="${dollar}{commandOptions}"
      }


      SetOptionOutputFile "${dollar}{alloptions}" "-A" "${aMultipleAlignmentFileName}"
      SetOptionOutputFile "${dollar}{alloptions}" "--tblout" "${tbloutFileName}"
      SetOptionOutputFile "${dollar}{alloptions}" "--domtblout" "${domtbloutFileName}"
      SetOptionOutputFile "${dollar}{alloptions}" "--pfamtblout" "${pfamtbloutFileName}"


#      if [[ ! "${options}" =~ "--tblout " ]]
#      then
#          alloptions="${dollar}{alloptions} --tblout ${tbloutFileName}"
#      else
#          #alloptions="${dollar}{alloptions/--tblout .*[ $]/--tblout ${tbloutFileName}}"
#          alloptions=$(echo "${dollar}{alloptions}" | sed "s/--tblout[[:space:]+][^[:space:]]*/--tblout ${tbloutFileName}/g")
#      fi
#
#      if [[ ! "${options}" =~ "--domtblout " ]]
#      then
#          alloptions="${dollar}{alloptions} --domtblout ${domtbloutFileName}"
#      else
#          #alloptions="${dollar}{alloptions/--domtblout .*[ $]/--domtblout ${domtbloutFileName}}"
#          alloptions=$(echo "${dollar}{alloptions}" | sed "s/--domtblout[[:space:]+][^[:space:]]*/--domtblout ${domtbloutFileName}/g")
#      fi
#
#      if [[ ! "${options}" =~ "--pfamtblout " ]]
#      then
#          alloptions="${dollar}{alloptions} --pfamtblout ${pfamtbloutFileName}"
#      else
#          #alloptions="${dollar}{alloptions/--pfamtblout .*[ $]/--pfamtblout ${pfamtbloutFileName}}"
#          alloptions=$(echo "${dollar}{alloptions}" | sed "s/--pfamtblout[[:space:]+][^[:space:]]*/--pfamtblout ${pfamtbloutFileName}/g")
#      fi
#

      case ${hmmerCommand} in
        "hmmscan")
          hmmpress ${dollar}{unzippedDBFile}
          hmmscan -o ${outputFileName} ${dollar}{alloptions} ${dollar}{unzippedDBFile} ${sequenceFile}
          ;;
        "nhmmscan")
          hmmpress ${dollar}{unzippedDBFile}
          nhmmscan -o ${outputFileName} ${dollar}{alloptions} ${dollar}{unzippedDBFile} ${sequenceFile}
          ;;
        "nhmmer")
          hmmpress ${dollar}{unzippedDBFile}
          nhmmer -o ${outputFileName} ${dollar}{alloptions} ${dollar}{unzippedDBFile} ${sequenceFile}
          ;;
        "hmmsearch")
          hmmsearch -o ${outputFileName} ${dollar}{alloptions} ${dollar}{unzippedDBFile} ${sequenceFile}
          ;;
        "phmmer")
          phmmer -o ${outputFileName} ${dollar}{alloptions} ${sequenceFile} ${dollar}{unzippedDBFile}
          ;;
        "jackhmmer")
          jackhmmer -o ${outputFileName} ${dollar}{alloptions} ${sequenceFile} ${dollar}{unzippedDBFile}
          ;;
        *)
          echo "HMMER command ${hmmerCommand} is not known"
      esac
  >>>
  output {
    File outputFile = "${outputFileName}"
    Array[File] allOutputFiles = glob("*.*")

    File aMultipleAlignmentFile = read_string("outputFileName-A.txt")
    File tbloutFile =  "${tbloutFileName}"
    File domtbloutFile = "${domtbloutFileName}"
    File pfamtbloutFile = "${pfamtbloutFileName}"
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

  # If you provide the -A multiple alignment file name in
  # this variable do not also specify -A in the options variable
  String? aMultipleAlignmentFileName
  String defaultMultipleAlignmentFileName = select_first([aMultipleAlignmentFileName, "${hmmerCommand}_multiplealignments.txt"])
  String? tbloutFileName
  String defaultTblOutFileName = select_first([tbloutFileName, "${hmmerCommand}_tblout.txt"])

  String? domtbloutFileName
  String defaultDomTblOutFileName = select_first([domtbloutFileName, "${hmmerCommand}_domtblout.txt"])

  String? pfamtbloutFileName
  String defaultPfamTblOutFileName = select_first([pfamtbloutFileName, "${hmmerCommand}_pfamtblout.txt"])

  Int? preemptibleTries
  Int preemptibleTriesDefault = select_first([preemptibleTries, 1])
  Int? maxRetries
  Int maxRetriesDefault = select_first([maxRetries, 1])
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
  String outputFileNameDefault = select_first([outputFileName, "myHMMER_${hmmerCommand}_output.txt"  ])

  # Concatenate all the output table file options to the other options
  #String allOptions = options + " -A ${defaultMultipleAlignmentFileName}" + " --tblout ${defaultTblOutFileName}"
  #                     + " --domtblout ${defaultDomTblOutFileName}" + " --pfamtblout ${defaultPfamTblOutFileName}"
  #String allOptions = options + " -A ${defaultMultipleAlignmentFileName}" +
  #                     " --domtblout ${defaultDomTblOutFileName}" + " --pfamtblout ${defaultPfamTblOutFileName}"
 #String allOptions2 =  options + if (defined(aMultipleAlignmentsFileName)) then " -A ${aMultipleAlignmentsFileName}" else " -A ${hmmerCommand}_multiplealignments.txt"
  #String allOptions3 = allOptions2 + if (defined(tbloutFileName)) then " --tblout ${tbloutFileName}" else " --tblout ${hmmerCommand}_tblout.txt"
  #String allOptions4 = allOptions3 + if (defined(domtbloutFileName)) then " --domtblout ${domtbloutFileName}" else " --domtblout ${hmmerCommand}_domtblout.txt"
  #String allOptions = allOptions4 + if (defined(pfamtbloutFileName)) then " --pfamtblout ${pfamtbloutFileName}" else " --pfamtblout ${hmmerCommand}_pfamtblout.txt"

  #String defaultMultipleAlignmentsFileName = select_first([aMultipleAlignmentsFileName, 
  # Get the size of the standard reference file
  # Calling size seems to make the https input URL fail - at least on a Mac
  #Float fileDiskSize = size(DBFile, "GB") + size(sequenceFile, "GB")

  call hmmerTask { input:
                    hmmerCommand = hmmerCommand,
                    DBFile = DBFile,
                    options = options,

                    aMultipleAlignmentFileName = defaultMultipleAlignmentFileName,
                    tbloutFileName = defaultTblOutFileName,
                    domtbloutFileName = defaultDomTblOutFileName,
                    pfamtbloutFileName = defaultPfamTblOutFileName,

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

    File aMultipleAlignmentFile = hmmerTask.aMultipleAlignmentFile
    File tbloutFileFile = hmmerTask.tbloutFile
    File domtbloutFile = hmmerTask.domtbloutFile
    File pfamtbloutFile = hmmerTask.pfamtbloutFile
  }
}

