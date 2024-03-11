#!/bin/bash

if [[ $ASSESSMENT_TOOL_NAME == "spdx-sbom-generator" ]] 
then
    echo "Running $ASSESSMENT_TOOL_NAME"
    cd "$BESLAB_ARTIFACT_PATH" || return 1
    if ! ./spdx-sbom-generator -p "$BESMAN_OSSP_DIR" -o "$SBOM_PATH" -f JSON
    then
        return 1
    else
        return 0
    fi

fi