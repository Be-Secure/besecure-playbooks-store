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
    --benchmark=autocomplete \
    --prompt-path="$BESMAN_CYBERSECEVAL_DATASETS/autocomplete/autocomplete.json" \
    --response-path="$BESMAN_RESULTS_PATH/autocomplete_responses.json" \
    --stat-path="$BESMAN_RESULTS_PATH/autocomplete_stat.json" \
    --llm-under-test="$BESMAN_ARTIFACT_PROVIDER::$BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION::dummy_value" \
    --run-llm-in-parallel \
    --num-test-cases="$BESMAN_NUM_TEST_CASES_AUTOCOMPLETE"

if [[ "$?" -ne 0 ]]; then
    export AUTOCOMPLETE_RESULT=1
else
    export AUTOCOMPLETE_RESULT=0
    jq 'to_entries[0].value' "$BESMAN_RESULTS_PATH/autocomplete_stat.json" >"$BESMAN_RESULTS_PATH/autocomplete_stat.tmp.json" && mv "$BESMAN_RESULTS_PATH/autocomplete_stat.tmp.json" "$BESMAN_RESULTS_PATH/autocomplete_stat.json"
fi

if [[ "$AUTOCOMPLETE_RESULT" == "0" ]]; then
    # Copy result to detailed report path
    cp "$BESMAN_RESULTS_PATH/autocomplete_stat.json" "$AUTOCOMPLETE_TEST_REPORT_PATH/autocomplete_stat.json"
    cp "$BESMAN_RESULTS_PATH/autocomplete_responses.json" "$AUTOCOMPLETE_TEST_REPORT_PATH/autocomplete_responses.json"
fi
