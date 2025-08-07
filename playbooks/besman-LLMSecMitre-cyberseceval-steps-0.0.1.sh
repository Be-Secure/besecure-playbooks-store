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

function get_expansion_parameters()
{
    if [[ "$BESMAN_EXPANSION_LLM_PROVIDER" == "AWSBedrock" ]] 
    then
        echo "AWSBedrock::$BESMAN_EXPANSION_LLM_NAME.$BESMAN_EXPANSION_LLM_VERSION::$AWS_ACCESS_KEY_ID/$AWS_SECRET_ACCESS_KEY"
    elif [[ "$BESMAN_EXPANSION_LLM_PROVIDER" == "Ollama" ]]
    then
        echo "Ollama::$BESMAN_EXPANSION_LLM_NAME:$BESMAN_EXPANSION_LLM_VERSION::http://localhost:11434"
    elif [[ "$BESMAN_EXPANSION_LLM_PROVIDER" == "HuggingFace" ]]
    then
        echo "HuggingFace::$BESMAN_JUDGE_MODEL_REPO_NAMESPACE/$BESMAN_EXPANSION_LLM_NAME-$BESMAN_EXPANSION_LLM_VERSION::random-string"
    else
        __besman_echo_error "[ERR]: The provier $BESMAN_EXPANSION_LLM_PROVIDER is not supported" >&2
        return 1
    fi
}

expansion_parameters=$(get_expansion_parameters)
if [[ $? -ne 0 ]]; then
    echo "Failed to get expansion llm parameters." >&2
fi


if  [[ "$BESMAN_ARTIFACT_PROVIDER" == "Ollama" ]]
then
    python3 -m CybersecurityBenchmarks.benchmark.run \
        --benchmark=mitre \
        --prompt-path="$BESMAN_CYBERSECEVAL_DATASETS/mitre/mitre_benchmark_100_per_category_with_augmentation.json" \
        --response-path="$BESMAN_RESULTS_PATH/mitre_responses.json" \
        --judge-response-path="$BESMAN_RESULTS_PATH/mitre_judge_responses.json" \
        --stat-path="$BESMAN_RESULTS_PATH/mitre_stat.json" \
        --judge-llm="$judge_parameters" \
        --expansion-llm="$expansion_parameters" \
        --llm-under-test="$BESMAN_ARTIFACT_PROVIDER::$BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION::http://localhost:11434" \
        --run-llm-in-parallel \
        --num-test-cases="$BESMAN_NUM_TEST_CASES_MITRE"
elif [[ "$BESMAN_ARTIFACT_PROVIDER" == "HuggingFace" ]] 
then
    python3 -m CybersecurityBenchmarks.benchmark.run \
        --benchmark=mitre \
        --prompt-path="$BESMAN_CYBERSECEVAL_DATASETS/mitre/mitre_benchmark_100_per_category_with_augmentation.json" \
        --response-path="$BESMAN_RESULTS_PATH/mitre_responses.json" \
        --judge-response-path="$BESMAN_RESULTS_PATH/mitre_judge_responses.json" \
        --stat-path="$BESMAN_RESULTS_PATH/mitre_stat.json" \
        --judge-llm="$judge_parameters" \
        --expansion-llm="$expansion_parameters" \
        --llm-under-test="$BESMAN_ARTIFACT_PROVIDER::$BESMAN_MODEL_REPO_NAMESPACE/$BESMAN_ARTIFACT_NAME-$BESMAN_ARTIFACT_VERSION::random-string" \
        --num-test-cases="$BESMAN_NUM_TEST_CASES_MITRE"
fi
if [[ "$?" -ne 0 ]]; then
    export MITRE_RESULT=1
else
    export MITRE_RESULT=0
fi

# # Copy result to detailed report path
# cp "$BESMAN_RESULTS_PATH/mitre_judge_responses.json" "$MITRE_TEST_REPORT_PATH/mitre_judge_responses.json"
# cp "$BESMAN_RESULTS_PATH/mitre_responses.json" "$MITRE_TEST_REPORT_PATH/mitre_responses.json"
deactivate