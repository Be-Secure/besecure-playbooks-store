#!/bin/bash
# Author: Samir Ranjan Parhi
# License: Same as Repository Licence
# Usage : Beta-Release
# Date : 05-march-2024

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

    PROJECT_NAME=$1
    github_token=$2
    github_api_version=$3
    github_project_owner=$4
    github_repo_name=$5
    project_version=$6  

# Lifecycle functions
function __besman_init {

    echo -e "\n${BLUE}🛫 Preparing your machine for ScoreCard Run .${RESET}"
    # Specify the directory to save the scan results
    mkdir -p "$HOME/$PROJECT_NAME/scoreCard"

}

function __besman_execute {

    # creating a CodeQL database for Java code
    curl -X 'GET' \
    "https://api.securityscorecards.dev/projects/github.com/Be-Secure/$github_repo_name" \
    -H "accept: application/json" >> $HOME/$PROJECT_NAME/scoreCard/$github_repo_name-$project_version-scorecard-report.json

}
function __besman_prepare {

   echo -e "\n${BLUE}✅ preaparing Scorecard report!${RESET}"
 }

function __besman_publish {

   echo -e "\n${BLUE}✅ Placeholder for Scorecard Report upload to BES Data Store!${RESET}"
 }

function __besman_cleanup {

    rm -rf $result_dir/*
 }

function __besman_launch {

        __besman_execute
        __besman_prepare
        __besman_publish
        __besman_cleanup

}
