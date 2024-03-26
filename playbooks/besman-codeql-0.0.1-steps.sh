#!/bin/bash
    echo "Do CodeQL github actions before running the playbook"
    echo "Running $ASSESSMENT_TOOL_NAME"
    cd "$BESMAN_TOOL_PATH" || return 1
    curl -sS \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $github_token" \
        -H "X-GitHub-Api-Version: $github_api_version" \
        "https://api.github.com/repos/$github_project_owner/$github_repo_name/code-scanning/alerts?tool_name=CodeQL&per_page=100" >> $CODEQL_PATH/$BESMAN_ARTIFACT_NAME-$BESMAN_ARTIFACT_VERSION-codeql-report.json

    
    if [[ "$?" != "0" ]] 
    then
        export CODEQL_RESULT=1
    else
        export CODEQL_RESULT=0
    fi 
    