task hmmsearchTask {
  File hmmDBFile
  String outputFileName
  String? options
  File sequenceFile
  Float diskSize
  String dockerImageName

  command {
   hmmsearch ${options} ${hmmDBFile} ${sequenceFile} > ${outputFileName}
  }
  output {
    File outputFile = "${outputFileName}"
 }

 runtime {
    docker: dockerImageName
    cpu: 4
    memory: "10 GB"
    disks: "local-disk " + sub(diskSize, "\\..*", "") + " HDD"
  }
}

task displayOutput {
    File outputFile
    command {
        cat ${outputFile}
    }
}

workflow hmmsearch {
  String? options
  File hmmDBFile
  File sequenceFile
  String? dockerImageName
  String? outputFileName

  # Optional input to increase all disk sizes in case of outlier sample with strange size behavior
  Int? increaseDiskSize

  # Some tasks need wiggle room, and we also need to add a small amount of disk to prevent getting a
  # Cromwell error from asking for 0 disk when the input is less than 1GB
  Int additionalDisk = select_first([increaseDiskSize, 20])

  String dockerImageNameDefault = select_first([dockerImageName, "waltshmmer"  ])
  String outputFileNameDefault = select_first([outputFileName, "myHMMER_hmmsearch.txt"  ])

  # Get the size of the standard reference file
  # Calling size seems to make the https input URL fail - at least on a Mac
  #Float fileDiskSize = size(hmmDBFile, "GB") + size(sequenceFile, "GB")

  call hmmsearchTask { input:
                    hmmDBFile = hmmDBFile,
                    options = options,
                    sequenceFile = sequenceFile,
                    outputFileName = outputFileNameDefault,
                    diskSize = additionalDisk,
                    #diskSize = fileDiskSize + additionalDisk,
                    dockerImageName = dockerImageNameDefault
       }
  call displayOutput{ input:
                    outputFile = hmmsearchTask.outputFile
       }

  meta {
      author : "Walt Shands"
      email : "wshands@gmail.com"
      description: "This is the workflow WDL for HMMER hmmsearch"
   }

  output {
    File hmmsearchOutput = hmmsearchTask.outputFile
  }
}

