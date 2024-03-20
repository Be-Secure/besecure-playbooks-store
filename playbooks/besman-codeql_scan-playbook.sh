#!/bin/bash
# Author: Sandhya K
# License: Same as Repository Licence
# Usage : Beta-Release
# Date : 05-Mar-2024

set -e
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
RESET=$(tput sgr0)
BOLD=$(tput bold)

echo -e "\n${BLUE}###################################################${RESET}"

echo -e "\n${BOLD}${GREEN}Info!${RESET} ${BLUE}You are using CodeQL playbook (API way)! \nSend your thoughts we would love the enhancement Ideas.\n${RESET}"

echo -e "\n${BLUE}###################################################${RESET}"

PROJECT_NAME=$1
github_token=$2
github_api_version=$3
github_project_owner=$4
github_repo_name=$5
project_version=$6  

# Lifecycle functions
function __besman_init {

    echo -e "\n${BLUE}🛫 Preparing your machine for Code QL Run .${RESET}"

    mkdir -p $HOME/$PROJECT_NAME
    echo -e "ls -l $PWD/$PROJECT_NAME"
}

function __besman_execute {
    # Generating CodeQL report 
    curl -sS \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $github_token" \
        -H "X-GitHub-Api-Version: $github_api_version" \
        "https://api.github.com/repos/$github_project_owner/$github_repo_name/code-scanning/alerts?tool_name=CodeQL&per_page=100" >> $HOME/$PROJECT_NAME/$github_repo_name-$project_version-codeql-report.json

}
function __besman_prepare {

   echo -e "\n${BLUE}✅ preaparing CodeQL report!${RESET}"
 }

function __besman_publish {

   echo -e "\n${BLUE}✅ Placeholder for CodeQl Report to BES Data Store!${RESET}"
 }

#function __besman_cleanup {

#    rm -rf $PWD/$PROJECT_NAME/*
# }

function __besman_launch {

    __besman_init
    __besman_execute
    __besman_prepare
    __besman_publish
#    __besman_cleanup
    echo "CodeQL scan completed and results saved to $PWD/$PROJECT_NAME"

}

__besman_launch