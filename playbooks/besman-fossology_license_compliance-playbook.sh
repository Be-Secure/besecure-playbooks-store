#!/bin/bash
# Author: Samir Ranjan Parhi
# License: Same as Repository Licence
# Usage : Beta-Release
# Date : 2/03/2024

set -e
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
RESET=$(tput sgr0)
BOLD=$(tput bold)

echo -e "\n${BLUE}###################################################${RESET}"

echo -e "\n${BOLD}${GREEN}Info!${RESET} ${BLUE}You are using fosology playbook! \nSend your thoughts we would love the enhancement Ideas.\n${RESET}"

echo -e "\n${BLUE}###################################################${RESET}"


# Lifecycle functions
function __besman_init {
    
   # Check Prerequsite for this CLI to run
   echo -e "\n${BLUE}🛫 Lets do a Quick check if you are running Any container runtime .${RESET}"

    PWD=$(pwd)
    PROJECT_NAME="$1"

    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo -e "\n${BLUE}❌ Docker is not installed. Please install Docker before running this script.${RESET}"
        exit 1
    fi

    # Check if Fossology container is running

    if docker ps -a --format '{{.Names}}' | grep -Eq '^fossology$'; then
        echo -e "\n${BLUE}✅ Fossology container is already running.${RESET}"
    else
        echo -e "\n${BLUE}🛫 Starting fossology container...${RESET}"

        docker run --name fossology -p 8081:80 --d fossology/fossology
    fi

}

function __besman_execute {

    # Define variables

    FOSSOLOGY_HOST_URL_WITH_PORT_NO="$2"
    FOSSOLOGY_TOKEN="$3"

    mkdir $PWD/$PROJECT_NAME

    echo -e "\n${BLUE}🛫 Starting Fossology Analysis...${RESET}"

   

    curl -k -s -S -X POST http://FOSSOLOGY_HOST_URL_WITH_PORT_NO/repo/api/v1/folders \
    -H "parentFolder: 1" \
    -H "folderName: $PROJECT_NAME" \
    -H "Authorization: Bearer $FOSSOLOGY_TOKEN"

    curl -k -s -S -X GET http://localhost:8081/repo/api/v1/folders \
    -H "Authorization: Bearer $FOSSOLOGY_TOKEN"

    curl -k -s -S -X POST http://localhost:8081/repo/api/v1/uploads \
    -H "folderId: 4" \
    -H "uploadDescription: Created for $PROJECT_NAME" \
    -H "public: public' -H 'Content-Type: multipart/form-data" \
    -F "fileInput=@"$PWD-$PROJECT_NAME.tar.gz";type=application/octet-stream" \
    -H "Authorization: Bearer $FOSSOLOGY_TOKEN"

    curl -k -s -S -X POST http://localhost:8081/repo/api/v1/jobs \
    -H "folderId: 4" \
    -H "uploadId: 3" \
    -H "Authorization: Bearer $FOSSOLOGY_TOKEN" \
    -H 'Content-Type: application/json'
        --data '{
        "analysis": {
            "bucket": true,
            "copyright_email_author": true,
            "ecc": true, "keyword": true,
            "mime": true,
            "monk": true,
            "nomos": true,
            "package": true
        },
        "decider": {
            "nomos_monk": true,
            "bulk_reused": true,
            "new_scanner": true
        }
        }'

    curl -k -s -S -X GET http://localhost:8081/repo/api/v1/report \
    -H "uploadId: 3" -H 'reportFormat: spdx2' \
    -H "Authorization: Bearer $FOSSOLOGY_TOKEN" \

    curl -k -s -S -X GET http://localhost:8081/repo/api/v1/report/6 \
    -H "Authorization: Bearer $FOSSOLOGY_TOKEN" \
    -H 'accept: text/plain' > $PWD/$PROJECT_NAME/$PROJECT_NAME_report.rdf.xml

    if [ $? -eq 0 ]; then
        echo -e "\n${BLUE}✅ Fossology for ${PROJECT_NAME} project  successfully! \n the report stored at ${PWD}/${PROJECT_NAME}${RESET}"
    else
        echo -e "\n${BLUE}❌ Fossology Analysis failed for ${PROJECT_NAME} project!${RESET}"
    fi
}
function __besman_prepare {

   echo -e "\n${BLUE}✅ Preparing Fossology report!${RESET}"
 }

function __besman_publish {

   echo -e "\n${BLUE}✅ Placeholder for Fossology Report to BES Data Store!${RESET}"
 }

function __besman_cleanup {

    echo -e "\n${BLUE}✅ Cleaning-UP and Reclaiming your Used space !${RESET}"
    # Stop Fossology container
    echo -e "\n${BLUE}Stopping Fossology container...${RESET}"

    docker stop fossology

    sleep 10
    

    if [ $? -eq 0 ]; then
        echo -e "\n${BLUE}✅ Fossology Container Stopped successfully.${RESET}"
    else
        echo -e "\n${BLUE}❌ Sorry was not able to stop info for Fossology container.😊 No Worries you can check it using ${BOLD}${GREEN}docker ps --format '{{.Names}}${RESET}'${RESET}"
    fi

    rm -rf $PWD/$PROJECT_NAME
 }

function __besman_launch {
    __besman_init
    __besman_execute
    __besman_prepare
    __besman_publish
    __besman_cleanup

}
