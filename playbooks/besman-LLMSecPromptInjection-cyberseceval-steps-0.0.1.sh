#!/bin/bash

__besman_echo_white "Running $ASSESSMENT_TOOL_NAME-$ASSESSMENT_TOOL_TYPE"

cd "$BESMAN_TOOL_PATH/$BESMAN_LLM_SEC_BENCH" || return 1

## Activate venv
if [[ ! -d ~/.venvs/CybersecurityBenchmarks ]]; then
    __besman_echo_red "[ERROR] Python virtual environment for CybersecurityBenchmarks is missing."
    (return 1 2>/dev/null) || exit 1
fi

source ~/.venvs/CybersecurityBenchmarks/bin/activate

function get_judge_parameters()
{
    if [[ "$BESMAN_JUDGE_LLM_PROVIDER" == "AWSBedrock" ]] 
    then
        echo "AWSBedrock::$BESMAN_JUDGE_LLM_NAME.$BESMAN_JUDGE_LLM_VERSION::$AWS_ACCESS_KEY_ID/$AWS_SECRET_ACCESS_KEY"
    elif [[ "$BESMAN_JUDGE_LLM_PROVIDER" == "Ollama" ]]
    then
        echo "Ollama::$BESMAN_JUDGE_LLM_NAME:$BESMAN_JUDGE_LLM_VERSION::http://localhost:11434"
    elif [[ "$BESMAN_JUDGE_LLM_PROVIDER" == "HuggingFace" ]]
    then
        echo "HuggingFace::$BESMAN_JUDGE_MODEL_REPO_NAMESPACE/$BESMAN_JUDGE_LLM_NAME-$BESMAN_JUDGE_LLM_VERSION::random-string"
    else
        __besman_echo_error "[ERR]: The provier $BESMAN_JUDGE_LLM_PROVIDER is not supported" >&2
        return 1
    fi
}

judge_parameters=$(get_judge_parameters)
if [[ $? -ne 0 ]]; then
    echo "Failed to get judge llm parameters." >&2
fi
if  [[ "$BESMAN_ARTIFACT_PROVIDER" == "Ollama" ]]
then
    python3 -m CybersecurityBenchmarks.benchmark.run \
        --benchmark=prompt-injection \
        --prompt-path="$BESMAN_CYBERSECEVAL_DATASETS/prompt_injection/prompt_injection.json" \
        --response-path="$BESMAN_RESULTS_PATH/prompt_injection_responses.json" \
        --judge-response-path="$BESMAN_RESULTS_PATH/prompt_injection_judge_responses.json" \
        --stat-path="$BESMAN_RESULTS_PATH/prompt_injection_stat.json" \
        --judge-llm="$judge_parameters" \
        --llm-under-test="$BESMAN_ARTIFACT_PROVIDER::$BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION::http://localhost:11434" \
        --run-llm-in-parallel \
        --num-test-cases="$BESMAN_NUM_TEST_CASES_PROMPT_INJECTION"
elif [[ "$BESMAN_ARTIFACT_PROVIDER" == "HuggingFace" ]] 
then
    python3 -m CybersecurityBenchmarks.benchmark.run \
        --benchmark=prompt-injection \
        --prompt-path="$BESMAN_CYBERSECEVAL_DATASETS/prompt_injection/prompt_injection.json" \
        --response-path="$BESMAN_RESULTS_PATH/prompt_injection_responses.json" \
        --judge-response-path="$BESMAN_RESULTS_PATH/prompt_injection_judge_responses.json" \
        --stat-path="$BESMAN_RESULTS_PATH/prompt_injection_stat.json" \
        --judge-llm="$judge_parameters" \
        --llm-under-test="$BESMAN_ARTIFACT_PROVIDER::$BESMAN_MODEL_REPO_NAMESPACE/$BESMAN_ARTIFACT_NAME-$BESMAN_ARTIFACT_VERSION::random-string" \
        --run-llm-in-parallel \
        --num-test-cases="$BESMAN_NUM_TEST_CASES_PROMPT_INJECTION"
fi

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