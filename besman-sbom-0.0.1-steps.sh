#!/bin/bash

if [[ $SBOM_TOOL == "spdx-sbom-generator" ]] 
then
    ./spdx-sbom-generator -p "$OSSP_DIR" -o "$SBOM_PATH" -f JSON
fi