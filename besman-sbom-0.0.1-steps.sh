#!/bin/bash

if [[ $BESLAB_SBOM_TOOL == "spdx-sbom-generator" ]] 
then
    echo "Running $BESLAB_SBOM_TOOL"
    cd "$BESLAB_ARTIFACT_PATH" || return 1
    if ! ./spdx-sbom-generator -p "$BESMAN_OSSP_DIR" -o "$SBOM_PATH" -f JSON
    then
        return 1
    else
        return 0
    fi

fi