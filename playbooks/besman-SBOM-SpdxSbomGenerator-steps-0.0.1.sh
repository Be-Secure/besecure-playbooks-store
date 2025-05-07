#!/bin/bash

    echo "Running $ASSESSMENT_TOOL_NAME"
    cd "$BESMAN_TOOL_PATH" || return 1
    ./spdx-sbom-generator -p "$BESMAN_ARTIFACT_DIR" -o "$SBOM_PATH" -f JSON
    if [[ "$?" != "0" ]] 
    then
        export SBOM_RESULT=1
    else
        export SBOM_RESULT=0
    fi 
    