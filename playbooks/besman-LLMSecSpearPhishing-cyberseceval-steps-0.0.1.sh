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
if  [[ "$BESMAN_ARTIFACT_PROVIDER" == "Ollama" ]]
then
    python3 -m CybersecurityBenchmarks.benchmark.run \
        --benchmark=multiturn-phishing \
        --prompt-path="$BESMAN_CYBERSECEVAL_DATASETS/spear_phishing/multiturn_phishing_challenges.json" \
        --response-path="$BESMAN_RESULTS_PATH/phishing_model_responses.json" \
        --judge-response-path="$BESMAN_RESULTS_PATH/phishing_judge_responses.json" \
        --stat-path="$BESMAN_RESULTS_PATH/phishing_stats.json" \
        --judge-llm="Ollama::codellama:7b::http://localhost:11434" \
        --llm-under-test="$BESMAN_ARTIFACT_PROVIDER::$BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION::http://localhost:11434" \
        --run-llm-in-parallel \
        --num-test-cases="$BESMAN_NUM_TEST_CASES_SPEAR_PHISHING"
elif [[ "$BESMAN_ARTIFACT_PROVIDER" == "HuggingFace" ]] 
then
    python3 -m CybersecurityBenchmarks.benchmark.run \
        --benchmark=multiturn-phishing \
        --prompt-path="$BESMAN_CYBERSECEVAL_DATASETS/spear_phishing/multiturn_phishing_challenges.json" \
        --response-path="$BESMAN_RESULTS_PATH/phishing_model_responses.json" \
        --judge-response-path="$BESMAN_RESULTS_PATH/phishing_judge_responses.json" \
        --stat-path="$BESMAN_RESULTS_PATH/phishing_stats.json" \
        --judge-llm="MISTRALAI::mistral.mistral-7b-instruct-v0:2::$AWS_ACCESS_KEY_ID/$AWS_SECRET_ACCESS_KEY" \
        --llm-under-test="$BESMAN_ARTIFACT_PROVIDER::$BESMAN_MODEL_REPO_NAMESPACE/$BESMAN_ARTIFACT_NAME-$BESMAN_ARTIFACT_VERSION::random-string" \
        --run-llm-in-parallel \
        --num-test-cases="$BESMAN_NUM_TEST_CASES_SPEAR_PHISHING"
fi

if [[ "$?" -ne 0 ]]; then
    export SPEAR_PHISHING_RESULT=1
else
    export SPEAR_PHISHING_RESULT=0
    jq 'to_entries[0].value' "$BESMAN_RESULTS_PATH/phishing_stats.json" >"$BESMAN_RESULTS_PATH/phishing_stats.tmp.json" && mv "$BESMAN_RESULTS_PATH/phishing_stats.tmp.json" "$BESMAN_RESULTS_PATH/phishing_stats.json"
fi

# Copy result to detailed report path
# cp "$BESMAN_RESULTS_PATH/phishing_stats.json" "$SPEAR_PHISHING_TEST_REPORT_PATH/phishing_stats.json"
# cp "$BESMAN_RESULTS_PATH/phishing_model_responses.json" "$SPEAR_PHISHING_TEST_REPORT_PATH/phishing_model_responses.json"
# cp "$BESMAN_RESULTS_PATH/phishing_judge_responses.json" "$SPEAR_PHISHING_TEST_REPORT_PATH/phishing_judge_responses.json"
deactivate