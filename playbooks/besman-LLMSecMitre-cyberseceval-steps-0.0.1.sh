#!/bin/bash

function __besman_run_mitre_assessment() {
    __besman_echo_white "Running $ASSESSMENT_TOOL_NAME-$ASSESSMENT_TOOL_TYPE"

    cd "$BESMAN_TOOL_PATH/PurpleLlama" || return 1

    if [[ ! -d ~/.venvs/CybersecurityBenchmarks ]]; then
        __besman_echo_red "[ERROR] Python virtual environment for CybersecurityBenchmarks is missing."
        return 1
    fi

    source ~/.venvs/CybersecurityBenchmarks/bin/activate

    function get_judge_parameters() {
        case "$BESMAN_JUDGE_LLM_PROVIDER" in
            AWSBedrock)
                echo "AWSBedrock::$BESMAN_JUDGE_LLM_NAME.$BESMAN_JUDGE_LLM_VERSION::$AWS_ACCESS_KEY_ID/$AWS_SECRET_ACCESS_KEY"
                ;;
            Ollama)
                echo "Ollama::$BESMAN_JUDGE_LLM_NAME:$BESMAN_JUDGE_LLM_VERSION::http://localhost:11434"
                ;;
            HuggingFace)
                echo "HuggingFace::$BESMAN_JUDGE_MODEL_REPO_NAMESPACE/$BESMAN_JUDGE_LLM_NAME-$BESMAN_JUDGE_LLM_VERSION::random-string"
                ;;
            *)
                __besman_echo_red "[ERROR] Unsupported judge provider: $BESMAN_JUDGE_LLM_PROVIDER"
                return 1
                ;;
        esac
    }

    function get_expansion_parameters() {
        case "$BESMAN_EXPANSION_LLM_PROVIDER" in
            AWSBedrock)
                echo "AWSBedrock::$BESMAN_EXPANSION_LLM_NAME.$BESMAN_EXPANSION_LLM_VERSION::$AWS_ACCESS_KEY_ID/$AWS_SECRET_ACCESS_KEY"
                ;;
            Ollama)
                echo "Ollama::$BESMAN_EXPANSION_LLM_NAME:$BESMAN_EXPANSION_LLM_VERSION::http://localhost:11434"
                ;;
            HuggingFace)
                echo "HuggingFace::$BESMAN_JUDGE_MODEL_REPO_NAMESPACE/$BESMAN_EXPANSION_LLM_NAME-$BESMAN_EXPANSION_LLM_VERSION::random-string"
                ;;
            *)
                __besman_echo_red "[ERROR] Unsupported expansion provider: $BESMAN_EXPANSION_LLM_PROVIDER"
                return 1
                ;;
        esac
    }

    judge_parameters=$(get_judge_parameters)
    [[ $? -ne 0 ]] && __besman_echo_red "Failed to get judge parameters." && return 1

    expansion_parameters=$(get_expansion_parameters)
    [[ $? -ne 0 ]] && __besman_echo_red "Failed to get expansion parameters." && return 1

    base_name="${ASSESSMENT_TOOL_NAME}-${ASSESSMENT_TOOL_TYPE// /_}"
    log_file="/tmp/${base_name}_assessment.log"
    pid_file="/tmp/${base_name}_assessment.pid"

    __besman_echo_yellow "Log file: $log_file"
    __besman_echo_yellow "PID file: $pid_file"

    if [[ -f "$pid_file" ]]; then
        existing_pid=$(<"$pid_file")
        if ps -p "$existing_pid" > /dev/null 2>&1; then
            __besman_echo_yellow "[INFO] MITRE benchmark already running with PID $existing_pid"
            __besman_echo_yellow "[INFO] To view logs: tail -f $log_file"
            deactivate
            return 0
        else
            __besman_echo_yellow "[INFO] Stale PID file found. Removing it."
            rm -f "$pid_file"
        fi
    fi

    python_command=(
        python3 -m CybersecurityBenchmarks.benchmark.run
        --benchmark=mitre
        --prompt-path="$BESMAN_CYBERSECEVAL_DATASETS/mitre/mitre_benchmark_100_per_category_with_augmentation.json"
        --response-path="$BESMAN_RESULTS_PATH/mitre_responses.json"
        --judge-response-path="$BESMAN_RESULTS_PATH/mitre_judge_responses.json"
        --stat-path="$BESMAN_RESULTS_PATH/mitre_stat.json"
        --judge-llm="$judge_parameters"
        --expansion-llm="$expansion_parameters"
        --run-llm-in-parallel
        --num-test-cases="$BESMAN_NUM_TEST_CASES_MITRE"
    )

    if [[ "$BESMAN_ARTIFACT_PROVIDER" == "Ollama" ]]; then
        python_command+=(--llm-under-test="$BESMAN_ARTIFACT_PROVIDER::$BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION::http://localhost:11434")
    elif [[ "$BESMAN_ARTIFACT_PROVIDER" == "HuggingFace" ]]; then
        python_command+=(--llm-under-test="$BESMAN_ARTIFACT_PROVIDER::$BESMAN_MODEL_REPO_NAMESPACE/$BESMAN_ARTIFACT_NAME-$BESMAN_ARTIFACT_VERSION::random-string")
    else
        __besman_echo_red "[ERROR] Unsupported artifact provider: $BESMAN_ARTIFACT_PROVIDER"
        deactivate
        return 1
    fi

    if [[ "$1" == "--background" ]]; then
        nohup "${python_command[@]}" > "$log_file" 2>&1 &
        echo "$!" > "$pid_file"
        __besman_echo_white "MITRE benchmark started in background (PID: $!)"
        export MITRE_RESULT=0
        return 0
    else
        nohup "${python_command[@]}" > "$log_file" 2>&1
        exit_code=$?

        if [[ "$exit_code" -ne 0 ]]; then
            __besman_echo_red "[ERROR] MITRE benchmark failed."
            export MITRE_RESULT=1
        else
            export MITRE_RESULT=0
            # Optional copy
            # cp "$BESMAN_RESULTS_PATH/mitre_judge_responses.json" "$MITRE_TEST_REPORT_PATH/mitre_judge_responses.json"
            # cp "$BESMAN_RESULTS_PATH/mitre_responses.json" "$MITRE_TEST_REPORT_PATH/mitre_responses.json"
        fi
    fi

    deactivate
}
