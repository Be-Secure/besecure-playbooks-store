#!/bin/bash

    echo "Running $ASSESSMENT_TOOL_NAME"

    if [[ "$?" != "0" ]] 
    then
        export SCORECARD_RESULT=1
    else
        export SCORECARD_RESULT=0
    fi 