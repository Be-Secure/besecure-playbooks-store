#!/bin/bash

function __besman_run_spear_phishing_assessment() {
    local force_flag="$1"
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

    judge_parameters=$(get_judge_parameters)
    [[ $? -ne 0 ]] && __besman_echo_red "Failed to get judge parameters." && return 1

    base_name="${ASSESSMENT_TOOL_NAME}-${BESMAN_ARTIFACT_NAME}-${BESMAN_ARTIFACT_VERSION}-${ASSESSMENT_TOOL_TYPE// /_}"
    log_dir="$BESMAN_DIR/log"
    mkdir -p "$log_dir" # Ensure the directory exists

    log_file="${log_dir}/${base_name}_assessment.log"
    pid_file="${log_dir}/${base_name}_assessment.pid"

    __besman_echo_yellow "Log file: $log_file"

    if [[ "$force_flag" == "--background" ]]; then

        __besman_echo_yellow "PID file: $pid_file"

        # Check if a previous process is already running
        if [[ -f "$pid_file" ]]; then
            existing_pid=$(<"$pid_file")
            if ps -p "$existing_pid" >/dev/null 2>&1; then
                __besman_echo_yellow "[INFO] Assessment is already running with PID $existing_pid"
                __besman_echo_yellow "[INFO] To view logs: tail -f $log_file"
                deactivate
                return 0
            else
                __besman_echo_yellow "[INFO] Found stale PID file. Cleaning up."
                rm -f "$pid_file"
            fi
        fi
    fi

    python_command=(
        python3 -m CybersecurityBenchmarks.benchmark.run
        --benchmark=multiturn-phishing
        --prompt-path="$BESMAN_CYBERSECEVAL_DATASETS/spear_phishing/multiturn_phishing_challenges.json"
        --response-path="$BESMAN_RESULTS_PATH/phishing_model_responses.json"
        --judge-response-path="$BESMAN_RESULTS_PATH/phishing_judge_responses.json"
        --stat-path="$BESMAN_RESULTS_PATH/phishing_stats.json"
        --judge-llm="$judge_parameters"
        --run-llm-in-parallel
        --num-test-cases="$BESMAN_NUM_TEST_CASES_SPEAR_PHISHING"
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
        __besman_echo_yellow "Running in background to see log run: tail -f $log_file"
        nohup "${python_command[@]}" > "$log_file" 2>&1 &
        echo "$!" > "$pid_file"
        __besman_echo_white "Spear Phishing benchmark started in background (PID: $!)"
        export SPEAR_PHISHING_RESULT=0
        return 0
    else
        nohup "${python_command[@]}" 2>&1 | tee "$log_file"
        exit_code=$?

        if [[ "$exit_code" -ne 0 ]]; then
            __besman_echo_red "[ERROR] Spear Phishing benchmark failed."
            export SPEAR_PHISHING_RESULT=1
        else
            export SPEAR_PHISHING_RESULT=0
            if [[ -s "$BESMAN_RESULTS_PATH/phishing_stats.json" ]]; then
                jq 'to_entries[0].value' "$BESMAN_RESULTS_PATH/phishing_stats.json" >"$BESMAN_RESULTS_PATH/phishing_stats.tmp.json" \
                    && mv "$BESMAN_RESULTS_PATH/phishing_stats.tmp.json" "$BESMAN_RESULTS_PATH/phishing_stats.json"
            else
                __besman_echo_red "[ERROR] phishing_stats.json is missing or empty."
                export AUTOCOMPLETE_RESULT=1
            fi
        fi
    fi

    deactivate
}
