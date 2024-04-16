#!/bin/bash

    echo "Running $ASSESSMENT_TOOL_NAME"
    cd "$BESMAN_TOOL_PATH" || return 1
    
    curl -X 'GET' \
    "https://api.securityscorecards.dev/projects/github.com/Be-Secure/$github_repo_name" \
    -H "accept: application/json" >> $BESMAN_ARTIFACT_NAME-$BESMAN_ARTIFACT_VERSION-scorecard.json

    if [[ "$?" != "0" ]] 
    then
        export SCORECARD_RESULT=1
    else
        export SCORECARD_RESULT=0
    fi 