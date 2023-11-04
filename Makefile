sub_init:
	echo "SUB_ID=<enter subscription name>" > sub.env

# Note: Diarization supported for only mono audio files; this is run locally (specific to the base system)
convert-to-wav:
	ffmpeg -i ./source-audio/"Incredible 2 (2018) - All Memorable Moments-gxaj1cD5Qnw.m4a" -ac 1 ./source-audio/memorable.wav
	ffmpeg -i ./source-audio/"The Incredibles - Family Argument (HDR - 4K - 5.1)-lYxx-8wQSO0.m4a" -ac 1 ./source-audio/argument.wav
	ffmpeg -i ./source-audio/"Incredibles 2 Fight Scene in Full - Jack-Jack vs. Raccoon (Exclusive)-h5lJTcChkoA.m4a" -ac 1 ./source-audio/racoon.wav

# This command provisions and sets up infrastructure
infra:
	./setup.sh

# This command triggers the batch transcription
# Notes: This is for the default base model in the specified locale
variables_file="variables.env"
speech_key=$(shell cat ${variables_file} | grep SPEECH_KEY | cut -d '=' -f2-)
location=$(shell cat ${variables_file} | grep SPEECH_LOCATION | cut -d '=' -f2-)
input_container_url=$(shell cat ${variables_file} | grep INPUT_CONTAINER_SAS_URL | cut -d '=' -f2-)
create-transcript:
	rm -rf create_result.txt
	curl -X POST -H "Ocp-Apim-Subscription-Key: $(speech_key)" -H "Content-Type: application/json" \
		-d '{"contentContainerUrl": "$(input_container_url)","locale": "en-US","displayName": "transcript-audio","model": null,"diarization": {"speakers": {"minCount": 1,"maxCount": 2}},"properties": {"wordLevelTimestampsEnabled": true,"diarizationEnabled": true,"languageIdentification": {"candidateLocales": ["en-US", "de-DE", "es-ES"]}}}' "https://$(location).api.cognitive.microsoft.com/speechtotext/v3.1/transcriptions" -o create_result.txt

# This command triggers the batch transcription, but for a Whisper model
create-whisper:
	rm -rf create_result.txt
	curl -X POST -H "Ocp-Apim-Subscription-Key: $(speech_key)" -H "Content-Type: application/json" \
		-d '{"contentContainerUrl": "$(input_container_url)","locale": "en-US","displayName": "transcript-audio","model": {"self":"https://eastus.api.cognitive.microsoft.com/speechtotext/v3.2-preview.1/models/base/e830341e-8f47-4e0a-b64c-3f66167b751c"},"diarization": {"speakers": {"minCount": 1,"maxCount": 2}},"properties": {"wordLevelTimestampsEnabled": false,"diarizationEnabled": true,"languageIdentification": {"candidateLocales": ["en-US", "de-DE", "es-ES"]}}}' "https://$(location).api.cognitive.microsoft.com/speechtotext/v3.1/transcriptions" -o create_result.txt

# This command gets the status of the batch transcription job created in the prior command
# Notes: Can run the command until status = "Succeeded"
submitted_request="create_result.txt"
turl=$(shell cat ${submitted_request} | grep "self" | cut -d ":" -f2- | cut -c 1- | rev | cut -c 2- | rev)
get-status:
	curl -v -X GET $(turl) -H "Ocp-Apim-Subscription-Key: $(speech_key)"

# This command gets the location of all the saved transcripts
# Notes: To be run after the command above changes to "Succeeded"
file_list=$(shell cat ${submitted_request} | grep "files" | cut -d ":" -f2-)
get-files:
	rm -rf file_list.txt
	curl -v -X GET $(file_list) -H "Ocp-Apim-Subscription-Key: $(speech_key)" -o file_list.txt

# Get file transcripts once you have them saved to "file_list.txt" (from above)
get-file-transcripts:
	./scroll.sh
