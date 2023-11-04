#!/bin/bash
#Script to provision Cognitive Services account
grn=$'\e[1;32m'
end=$'\e[0m'

# Start of script
SECONDS=0

# Source subscription ID, and prep config file
source sub.env
sub_id=$SUB_ID
email_id=$EMAIL_ID

# Set the default subscription 
az account set -s $sub_id

# Create the resource group, location
number=$[ ( $RANDOM % 10000 ) + 1 ]
resourcegroup='cs'$number
speechService='cs'$number'speech'
storageAccount='cs'$number'storageaccount'
inputBlobContainer='cs'$number'inputs'
destBlobContainer='cs'$number'outputs'
location='eastus'
end_date=$(date -j -v +2d +"%Y-%m-%d")

printf "${grn}starting creation of resource group...${end}\n"
rgCreate=$(az group create --name $resourcegroup --location $location)
printf "Result of resource group create:\n $rgCreate \n"

## Create speech service
printf "${grn}creating the speech service...${end}\n"
speechServiceCreate=$(az cognitiveservices account create \
	--name $speechService \
	-g $resourcegroup \
	--kind 'SpeechServices' \
	--sku S0 \
	--location $location \
	--yes)
printf "Result of speech service create:\n $speechServiceCreate \n"

## Retrieve key from cognitive services
printf "${grn}retrieve keys & endpoints for speech service...${end}\n"
speechKey=$(az cognitiveservices account keys list -g $resourcegroup --name $speechService --query "key1" -o tsv)
speechEndpoint=$(az cognitiveservices account show -g $resourcegroup --n $speechService --query "properties.endpoint" -o tsv)

# Create the storage account
printf "${grn}starting creation of the storage account...${end}\n"
storageAcctCreate=$(az storage account create \
	--name $storageAccount \
	-g $resourcegroup \
	-l $location \
	--kind StorageV2 \
	--sku Standard_LRS)
printf "Result of storage account create:\n $storageAcctCreate \n"
sleep 5

# Get the connection string
conn_string=$(az storage account show-connection-string --name $storageAccount -g $resourcegroup --query "connectionString" -o tsv)

# Get the storage key
printf "${grn}save the storage account key...${end}\n"
storagekey=$(az storage account keys list --account-name $storageAccount --query [0].value -o tsv)
# printf "Result of storage key retrieval:\n $storagekey \n"

# Create input and output containers
printf "${grn}starting creation of the input blob container...${end}\n"
inputBlobContainerCreate=$(az storage container create --connection-string $conn_string --name $inputBlobContainer)
printf "Result of input blob container create:\n $inputBlobContainerCreate \n"

printf "${grn}generate sas token for input blob container...${end}\n"
inputSasToken=$(az storage container generate-sas \
	--account-name $storageAccount --name $inputBlobContainer \
  --account-key $storagekey \
	--permissions dlrw \
	--expiry $end_date \
  -o tsv
)

printf "${grn}get full input container url with sas token...${end}\n"
inputSasUrl=https://$storageAccount.blob.core.windows.net/$inputBlobContainer?$inputSasToken


printf "${grn}starting creation of the destination blob container...${end}\n"
destBlobContainerCreate=$(az storage container create --connection-string $conn_string --name $destBlobContainer)
printf "Result of destination blob container create:\n $destBlobContainerCreate \n"

printf "${grn}generate sas token for destination blob container...${end}\n"
destSasToken=$(az storage container generate-sas \
	--account-name $storageAccount --name $destBlobContainer \
  --account-key $storagekey \
	--permissions dlrw \
	--expiry $end_date \
  -o tsv
)

printf "${grn}get full destination container url with sas token...${end}\n"
destSasUrl=https://$storageAccount.blob.core.windows.net/$destBlobContainer?$destSasToken


# Upload local wav files
printf "${grn}upload wav files...${end}\n"
az storage blob upload-batch -d $inputBlobContainer --account-name $storageAccount \
  --account-key $storagekey \
  -s "./source-audio/" \
  --pattern *.wav

# Create environment file 
printf "${grn}writing out environment variables...${end}\n"
configFile='variables.env'
printf "RESOURCE_GROUP=$resourcegroup\n"> $configFile
printf "SPEECH_KEY=$speechKey\n">> $configFile
printf "SPEECH_LOCATION=$location\n">> $configFile
printf "SPEECH_ENDPOINT=$speechEndpoint\n">> $configFile
printf "STORAGE_ACCOUNT=$storageAccount\n">> $configFile
printf "STORAGE_KEY=$storagekey\n">> $configFile
printf "STORAGE_CONN_STRING=$conn_string\n">> $configFile
printf "BLOB_CONTAINER_NAME=$inputBlobContainer\n">> $configFile
echo "INPUT_CONTAINER_SAS_TOKEN=$inputSasToken">> $configFile
echo "INPUT_CONTAINER_SAS_URL=$inputSasUrl">> $configFile
echo "DEST_CONTAINER_SAS_TOKEN=$destSasToken">> $configFile
echo "DEST_CONTAINER_SAS_URL=$destSasUrl">> $configFile
