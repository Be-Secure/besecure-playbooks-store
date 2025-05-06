#!/bin/bash

__besman_echo_white "Running $ASSESSMENT_TOOL_NAME-$ASSESSMENT_TOOL_TYPE"

cd "$BESMAN_TOOL_PATH/PurpleLlama" || return 1

## Activate venv
if [[ ! -d ~/.venvs/CybersecurityBenchmarks ]]; then
    __besman_echo_red "[ERROR] Python virtual environment for CybersecurityBenchmarks is missing."
    (return 1 2>/dev/null) || exit 1
fi

source ~/.venvs/CybersecurityBenchmarks/bin/activate

# Check if AWS credentials are set
# if [[ -z "$AWS_ACCESS_KEY_ID" || -z "$AWS_SECRET_ACCESS_KEY" ]]; then
#     __besman_echo_red "[ERROR] AWS_ACCESS_KEY_ID or AWS_SECRET_ACCESS_KEY is not set."
#     __besman_echo_white "Please export them before running:"
#     __besman_echo_white "export AWS_ACCESS_KEY_ID=<your-access-key-id>"
#     __besman_echo_white "export AWS_SECRET_ACCESS_KEY=<your-secret-access-key>"
#     return 1
# fi

    python3 -m CybersecurityBenchmarks.benchmark.run \
        --benchmark=prompt-injection \
        --prompt-path="$BESMAN_CYBERSECEVAL_DATASETS/prompt_injection/prompt_injection.json" \
        --response-path="$BESMAN_RESULTS_PATH/prompt_injection_responses.json" \
        --judge-response-path="$BESMAN_RESULTS_PATH/prompt_injection_judge_responses.json" \
        --stat-path="$BESMAN_RESULTS_PATH/prompt_injection_stat.json" \
        --judge-llm="AWSBedrock::mistral.mistral-7b-instruct-v0:2::$AWS_ACCESS_KEY_ID/$AWS_SECRET_ACCESS_KEY" \
        --llm-under-test="$BESMAN_ARTIFACT_PROVIDER::$BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION::http://localhost:11434" \
        --run-llm-in-parallel \
        --num-test-cases="$BESMAN_NUM_TEST_CASES_PROMPT_INJECTION"


if [[ "$?" -ne 0 ]]; then
    export PROMPT_INJECTION_RESULT=1
else
    export PROMPT_INJECTION_RESULT=0
    jq 'to_entries[0].value' "$BESMAN_RESULTS_PATH/prompt_injection_stat.json" >"$BESMAN_RESULTS_PATH/prompt_injection_stat.tmp.json" && mv "$BESMAN_RESULTS_PATH/prompt_injection_stat.tmp.json" "$BESMAN_RESULTS_PATH/prompt_injection_stat.json"
fi

# Copy result to detailed report path
# cp "$BESMAN_RESULTS_PATH/prompt_injection_stat.json" "$PROMPT_INJECTION_TEST_REPORT_PATH/prompt_injection_stat.json"
# cp "$BESMAN_RESULTS_PATH/prompt_injection_responses.json" "$PROMPT_INJECTION_TEST_REPORT_PATH/prompt_injection_responses.json"
# cp "$BESMAN_RESULTS_PATH/prompt_injection_judge_responses.json" "$PROMPT_INJECTION_TEST_REPORT_PATH/prompt_injection_judge_responses.json"
deactivate