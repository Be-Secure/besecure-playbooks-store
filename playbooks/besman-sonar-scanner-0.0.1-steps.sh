#!/bin/bash
# Author: Samir Ranjan Parhi
# License: Same as Repository Licence
# Usage : Beta-Release
# Date : 12/02/2024

    echo "Running $ASSESSMENT_TOOL_NAME"
     cd "$BESMAN_TOOL_PATH" || return 1

    export SONAR_RESULT=1

    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo -e "\n ❌ Docker is not installed. Please install Docker before running this script."
        SONAR_RESULT=0
        exit 1
        
    fi

    # Check if SonarQube container is running

    if docker ps -a --format '{{.Names}}' | grep -Eq '^sonarqube$'; then
        echo -e "\n✅ SonarQube container is already running."
    else
        echo -e "\n🛫 Starting SonarQube container..."
        docker run -d --name sonarqube -p 9000:9000 -p 9092:9092 sonarqube
    fi
    if ! command -v sonar-scanner &> /dev/null; then
        echo -e "\n❌ Sonar Scanner CLI is not installed. Please install Sonar Scanner CLI before running this script."
        SONAR_RESULT=0
        exit 1
    fi

    sonar-scanner \
    -Dsonar.projectKey=$BESMAN_ARTIFACT_NAME \
    -Dsonar.projectName="$BESMAN_ARTIFACT_NAME" \
    -Dsonar.host.url=$SONAR_HOST_URL \
    -Dsonar.sources=. \
    -Dsonar.python.binaries=python \
    # -Dsonar.analysis.report.format=json \
    -Dsonar.login=$SONAR_LOGIN_TOKEN

    if [[ "$?" != "0" ]] 
    then
        echo -e "\n ✅ Sonar-Scanner for $BESMAN_ARTIFACT_NAME project  successfully! \n the report stored at $BESMAN_TOOL_PATH/.scannerwork"
        export SONAR_RESULT=1
    else
        echo -e "\n ❌ Sonar-Scanner failed $BESMAN_ARTIFACT_NAME project  successfully!"
        export SONAR_RESULT=0
    fi 
    