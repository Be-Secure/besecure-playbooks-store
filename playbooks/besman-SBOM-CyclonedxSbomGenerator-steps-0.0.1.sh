#!/bin/bash

echo "Running $ASSESSMENT_TOOL_NAME"
cd "$BESMAN_ARTIFACT_DIR" || return 1
cdxgen -r -o "$DETAILED_REPORT_PATH" 
if [[ "$?" != "0" ]]; then
    export SBOM_RESULT=1
else
    export SBOM_RESULT=0
fi
