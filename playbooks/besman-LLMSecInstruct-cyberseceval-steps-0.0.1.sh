#!/bin/bash

__besman_echo_white "Running $ASSESSMENT_TOOL_NAME-$ASSESSMENT_TOOL_TYPE"

cd "$BESMAN_TOOL_PATH/PurpleLlama" || return 1

## Activate venv
if [[ ! -d ~/.venvs/CybersecurityBenchmarks ]]; then
    __besman_echo_red "[ERROR] Python virtual environment for CybersecurityBenchmarks is missing."
    (return 1 2>/dev/null) || exit 1
fi

source ~/.venvs/CybersecurityBenchmarks/bin/activate

    python3 -m CybersecurityBenchmarks.benchmark.run \
        --benchmark=instruct \
        --prompt-path="$BESMAN_CYBERSECEVAL_DATASETS/instruct/instruct.json" \
        --response-path="$BESMAN_RESULTS_PATH/instruct_responses.json" \
        --stat-path="$BESMAN_RESULTS_PATH/instruct_stat.json" \
        --llm-under-test="$BESMAN_ARTIFACT_PROVIDER::$BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION::http://localhost:11434" \
        --run-llm-in-parallel \
        --num-test-cases="$BESMAN_NUM_TEST_CASES_INSTRUCT"

if [[ "$?" -ne 0 ]]; then
    export INSTRUCT_RESULT=1
else
    export INSTRUCT_RESULT=0
    jq 'to_entries[0].value' "$BESMAN_RESULTS_PATH/instruct_stat.json" >"$BESMAN_RESULTS_PATH/instruct_stat.tmp.json" && mv "$BESMAN_RESULTS_PATH/instruct_stat.tmp.json" "$BESMAN_RESULTS_PATH/instruct_stat.json"
    if [[ "$?" != "0" ]]; then
        __besman_echo_red "Could not read the summary file"
        return 1
    fi
fi



deactivate