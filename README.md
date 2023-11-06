# batch-transcription-samples
A repo to document some code related to Azure Speech to text's batch transcription features using the REST APIs. Source files from
[here](https://www.youtube.com/watch?v=lYxx-8wQSO0&t=1s), the
[here](https://www.youtube.com/watch?v=gxaj1cD5Qnw&t=2s), and [here](https://www.youtube.com/watch?v=rm52Oh7FPXY).

### Running the code
- The general flow of operations is captured in the Makefile.
- Note that the audio files to be processed through a batch transcription request need to honor the following [formats](https://learn.microsoft.com/en-us/azure/ai-services/speech-service/batch-transcription-audio-data?tabs=portal#supported-audio-formats). There is a command in the Makefile which illustrates tooling to aid conversion (at least on a Macbook).
- To run any of the commands (on a Unix/Linux system), at the terminal, you would run `make <command>`.
- For example, once you've authenticated to your Azure environment through the Azure CLI, to deploy the infrastructure (a speech resource and a storage account to
host the audio files), you can run `make infra`, which creates a resource group, provisions the
infrastructure, etc.  This also takes the files in `source-audio` and uploads them as a batch. 
- Once that runs successfully, you can then run `make create-transcript` to initiate a batch transcription.
- Then, run `make get-status` to check on the status of the job request.
- Run `make get-files` and `make get-file-transcripts` (in that order) to download the transcriptions.
