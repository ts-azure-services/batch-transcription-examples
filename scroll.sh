#!/bin/bash

#Script to scroll through specific transcripts

counter=1

# Read the file line by line
while IFS= read -r line
do
    # Use grep to find lines containing "contentUrl"
    if echo "$line" | grep -q "contentUrl"; then
        # Use awk to extract the URL, which is between double quotes
        url=$(echo "$line" | awk -F'"' '{print $4}')
        # echo "URL: $url"

        # Use curl to fetch the content of the URL
        content=$(curl -s "$url")

        # Write the content 
        echo "$content" > "file_$counter.txt"
        echo "Content saved to file_$counter.txt"

        # Increment counter
        ((counter++))
    fi
done < "file_list.txt"
