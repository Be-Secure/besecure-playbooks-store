#!/bin/bash

echo "Running $ASSESSMENT_TOOL_NAME"
source "$HOME/watchtower_env/bin/activate"

if [[ "$BESMAN_REPO_TYPE" == "github" ]]; then
    SCAN_CMD="python $BESMAN_WATCHTOWER_PATH/src/watchtower.py --repo_type=github --repo_url=$BESMAN_REPO_URL --branch_name=$BESMAN_BRANCH_NAME --depth=$BESMAN_DEPTH_VAL"
elif [[ "$BESMAN_REPO_TYPE" == "huggingface" ]]; then
    SCAN_CMD="python $BESMAN_WATCHTOWER_PATH/src/watchtower.py --repo_type=huggingface --repo_url=$BESMAN_REPO_URL"
else
    __besman_echo_red "Unknown repository type: $BESMAN_REPO_TYPE"
    export SCAN_RESULT=1
    return 1
fi

SCAN_OUTPUT=$($SCAN_CMD)
#echo "$SCAN_OUTPUT"

if [[ $? -ne 0 ]]; then
    export SCAN_RESULT=1
else
    export SCAN_RESULT=0
fi
