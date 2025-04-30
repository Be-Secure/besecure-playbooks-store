#!/bin/bash

__besman_echo_white "Running $ASSESSMENT_TOOL_NAME-$ASSESSMENT_TOOL_TYPE"

cd "$BESMAN_TOOL_PATH" || return 1

## Activate venv
if [[ ! -d ~/.venvs/CybersecurityBenchmarks ]]; then
    __besman_echo_red "[ERROR] Python virtual environment for CybersecurityBenchmarks is missing."
    (return 1 2>/dev/null) || exit 1
fi

source ~/.venvs/CybersecurityBenchmarks/bin/activate

# Check if AWS credentials are set
if [[ -z "$AWS_ACCESS_KEY_ID" || -z "$AWS_SECRET_ACCESS_KEY" ]]; then
    __besman_echo_red "[ERROR] AWS_ACCESS_KEY_ID or AWS_SECRET_ACCESS_KEY is not set."
    __besman_echo_white "Please export them before running:"
    __besman_echo_white "export AWS_ACCESS_KEY_ID=<your-access-key-id>"
    __besman_echo_white "export AWS_SECRET_ACCESS_KEY=<your-secret-access-key>"
    (return 1 2>/dev/null) || exit 1
fi

python3 -m CybersecurityBenchmarks.benchmark.run \
    --benchmark=multiturn-phishing \
    --prompt-path="$BESMAN_CYBERSECEVAL_DATASETS/spear_phishing/multiturn_phishing_challenges.json" \
    --response-path="$BESMAN_RESULTS_PATH/phishing_model_responses.json" \
    --judge-response-path="$BESMAN_RESULTS_PATH/phishing_judge_responses.json" \
    --stat-path="$BESMAN_RESULTS_PATH/phishing_stats.json" \
    --judge-llm="AWSBedrock::mistral.mistral-7b-instruct-v0:2::$AWS_ACCESS_KEY_ID/$AWS_SECRET_ACCESS_KEY" \
    --llm-under-test="$BESMAN_ARTIFACT_PROVIDER::$BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION::dummy_value" \
    --run-llm-in-parallel \
    --num-test-cases="$BESMAN_NUM_TEST_CASES_SPEAR_PHISHING"

if [[ "$?" -ne 0 ]]; then
    export SPEAR_PHISHING_RESULT=1
else
    export SPEAR_PHISHING_RESULT=0
fi

# Copy result to detailed report path
cp "$BESMAN_RESULTS_PATH/phishing_stats.json" "$DETAILED_REPORT_PATH"
cp "$BESMAN_RESULTS_PATH/phishing_model_responses.json" "$DETAILED_REPORT_PATH"
cp "$BESMAN_RESULTS_PATH/phishing_judge_responses.json" "$DETAILED_REPORT_PATH"
