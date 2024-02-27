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

echo -e "\n${BOLD}${GREEN}Info!${RESET} ${BLUE}You are using CodeQL playbook! \nSend your thoughts we would love the enhancement Ideas.\n${RESET}"

echo -e "\n${BLUE}###################################################${RESET}"


# Lifecycle functions
function __besman_init {

    echo -e "\n${BLUE}🛫 Preparing your machine for Code QL Run .${RESET}"
    # Specify the directory to save the scan results
    result_dir="$HOME/codeql_results"

     if command -v codeql &>/dev/null; then
        return 0  # CodeQL is installed
    else
        return 1  # CodeQL is not installed
    fi
    project_path=$1
    project_lang=$2
    query_path=$3
    result_dir=$4
}

function __besman_execute {

    # creating a CodeQL database for Java code
    codeql database create $project_path --language=$project_lang
    codeql query run --database=$project_path $Query_path/python_function_definitions.ql --output=$result_dir/results.txt

}
function __besman_prepare {

   echo -e "\n${BLUE}✅ preaparing CodeQL report!${RESET}"
 }

function __besman_publish {

   echo -e "\n${BLUE}✅ Placeholder for CodeQl Report to BES Data Store!${RESET}"
 }

function __besman_cleanup {

    rm -rf $result_dir/*
 }

function __besman_launch {

    if __besman_init; then
        echo "CodeQL is installed."
        mkdir -p $result_dir 
        __besman_execute
        __besman_prepare
        __besman_publish
        __besman_cleanup
        echo "CodeQL scan completed and results saved to $result_dir."
    else
        echo "Error: CodeQL is not installed. Please install CodeQL and try again."
        exit 1
    fi

}
