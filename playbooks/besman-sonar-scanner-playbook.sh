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

echo -e "\n${BOLD}${GREEN}Info!${RESET} ${BLUE}You are using Sonar-Scanner playbook! \nSend your thoughts we would love the enhancement Ideas.\n${RESET}"

echo -e "\n${BLUE}###################################################${RESET}"


# Lifecycle functions
function __besman_init {

   # Check Prerequsite for this CLI to run
   echo -e "\n${BLUE}🛫 Lets do a Quick check if you are running Any container runtime .${RESET}"

    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo -e "\n${BLUE}❌ Docker is not installed. Please install Docker before running this script.${RESET}"
        exit 1
    fi

    # Check if SonarQube container is running

    if docker ps -a --format '{{.Names}}' | grep -Eq '^sonarqube$'; then
        echo -e "\n${BLUE}✅ SonarQube container is already running.${RESET}"
    else
        echo -e "\n${BLUE}🛫 Starting SonarQube container...${RESET}"
        docker run -d --name sonarqube -p 9000:9000 -p 9092:9092 sonarqube
    fi

    # Check if Sonar Scanner CLI is installed
    if ! command -v sonar-scanner &> /dev/null; then
        echo -e "\n${BLUE}❌ Sonar Scanner CLI is not installed. Please install Sonar Scanner CLI before running this script.${RESET}"
        exit 1
    fi

}



function __besman_execute {

    PWD=$(pwd)
    SONAR_REPORT_PATH=  
    # Run SonarQube scan

    echo -e "\n${BLUE}🛫 Starting SonarQube scan...${RESET}"

    # Define variables

    PROJECT_KEY="$1"
    PROJECT_NAME="$2"
    SONAR_HOST_URL="$3"
    REPORT_FOLDER="$4"

    #Actual scanning command for sonar scanner

    # sonar-scanner -X \
    sonar-scanner \
    -Dsonar.projectKey=$PROJECT_KEY \
    -Dsonar.projectName="$PROJECT_NAME" \
    -Dsonar.host.url=$SONAR_HOST_URL \
    -Dsonar.sources=. \
    -Dsonar.python.binaries=python \
    # -Dsonar.analysis.report.format=json \
    -Dsonar.login=$SONAR_LOGIN_TOKEN

    if [ $? -eq 0 ]; then
        echo -e "\n${BLUE}✅ Sonar-Scanner for ${PROJECT_NAME} project  successfully! \n the report stored at ${PWD}/.scannerwork${RESET}"
    else
        echo -e "\n${BLUE}❌ Sonar-Scanner failed ${PROJECT_NAME} project  successfully!${RESET}"
    fi
}
function __besman_prepare {

   echo -e "\n${BLUE}✅ preaparing Sonar-Scanner report!${RESET}"
 }

function __besman_publish {

   echo -e "\n${BLUE}✅ Placeholder for Sonar Report to BES Data Store!${RESET}"
 }

function __besman_cleanup {

    echo -e "\n${BLUE}✅ Cleaning-UP and Reclaiming your Used space !${RESET}"
    # Stop SonarQube container
    echo -e "\n${BLUE}Stopping SonarQube container...${RESET}"

    docker stop sonarqube

    sleep 10

    if [ $? -eq 0 ]; then
        echo -e "\n${BLUE}✅ SonarQube Container Stopped successfully.${RESET}"
    else
        echo -e "\n${BLUE}❌ Sorry was not able to stop info for Sonar-Qube container.😊 No Worries you can check it using ${BOLD}${GREEN}docker ps --format '{{.Names}}${RESET}'${RESET}"
    fi
 }

function __besman_launch {
    __besman_init
    __besman_execute
    __besman_prepare
    __besman_publish
    __besman_cleanup

}
