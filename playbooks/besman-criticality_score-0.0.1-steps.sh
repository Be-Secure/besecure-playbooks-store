#!/bin/bash

echo "Running $ASSESSMENT_TOOL_NAME"
cd "$BESMAN_TOOL_PATH" || return 1
criticality_score -depsdev-disable -format json $BESMAN_ARTIFACT_URL | grep -o '{"default_score":.*}' >"$DETAILED_REPORT_PATH" 2>&1
if [[ "$?" != "0" ]]; then
    export CRITICALITY_SCORE_RESULT=1
else
    export CRITICALITY_SCORE_RESULT=0
fi
