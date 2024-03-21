#!/bin/bash
# Author: Samir Ranjan Parhi
# License: Same as Repository Licence
# Usage : Beta-Release
# Date : 12/02/2024

set -e
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
RESET=$(tput sgr0)
BOLD=$(tput bold)

echo -e "\n${BLUE}###################################################${RESET}"

echo -e "\n${BOLD}${GREEN}Info!${RESET} ${BLUE}You are using Snyk playbook! \nSend your thoughts we would love the enhancement Ideas.\n${RESET}"

echo -e "\n${BLUE}###################################################${RESET}"


# Lifecycle functions
function __besman_init {

    echo -e "\n${BLUE}🛫 Preparing your machine for Snyk Run .${RESET}"
    # Specify the directory to save the scan results
    result_dir="$HOME/codeql_results"

    if command -v snyk &>/dev/null; then
        echo "Snyk CLI is installed."
    else
        echo "Snyk CLI is not installed. Please install it."
        exit 1
    fi

    project_path=$1
    project_lang=$2
    query_path=$3
    result_dir=$4
    # exclue_file_path=$5
}

function __besman_execute {

    # creating a CodeQL database for Java code
    echo "Performing Snyk CLI scan..."
    
    snyk test --all-sub-projects --language=$project_lang $project_path --json-file=$result_dir/snyk_scan_results.json

    # snyk test --all-sub-projects --language=$project_lang $project_path --exclude-files='$exclue_file_path' --json-file=$result_dir/snyk_scan_results.json

    echo "Scan completed and results saved to $result_dir/snyk_scan_results.json"

}
function __besman_prepare {

   echo -e "\n${BLUE}✅ preaparing snyk report!${RESET}"
 }

function __besman_publish {

   echo -e "\n${BLUE}✅ Placeholder for Snyk Report to BES Data Store!${RESET}"
 }

function __besman_cleanup {

        echo "Cleaning up the directory..."
        rm -rf "$result_dir"
        echo "Directory cleaned up."
 }

function __besman_launch {
     
__besman_execute
__besman_prepare
__besman_publish
__besman_cleanup

}
