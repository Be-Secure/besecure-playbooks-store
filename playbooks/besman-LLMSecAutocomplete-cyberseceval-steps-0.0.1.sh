#!/bin/bash

function __besman_run_assessment_in_background() {
    __besman_echo_white "Running $ASSESSMENT_TOOL_NAME-$ASSESSMENT_TOOL_TYPE"

    cd "$BESMAN_TOOL_PATH/PurpleLlama" || return 1

    if [[ ! -d ~/.venvs/CybersecurityBenchmarks ]]; then
        __besman_echo_red "[ERROR] Python virtual environment for CybersecurityBenchmarks is missing."
        return 1
    fi

    source ~/.venvs/CybersecurityBenchmarks/bin/activate

    base_name="${ASSESSMENT_TOOL_NAME}-${ASSESSMENT_TOOL_TYPE// /_}"
    log_dir="/tmp/besman_assessment"
    mkdir -p "$log_dir" # Ensure the directory exists

    log_file="${log_dir}/${base_name}_assessment.txt"
    pid_file="${log_dir}/${base_name}_assessment.pid"

    __besman_echo_yellow "Log file: $log_file"
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

    local python_command=(
        python3 -m CybersecurityBenchmarks.benchmark.run
        --benchmark=autocomplete
        --prompt-path="$BESMAN_CYBERSECEVAL_DATASETS/autocomplete/autocomplete.json"
        --response-path="$BESMAN_RESULTS_PATH/autocomplete_responses.json"
        --stat-path="$BESMAN_RESULTS_PATH/autocomplete_stat.json"
        --run-llm-in-parallel
        --num-test-cases="$BESMAN_NUM_TEST_CASES_AUTOCOMPLETE"
    )

    if [[ "$BESMAN_ARTIFACT_PROVIDER" == "Ollama" ]]; then
        __besman_echo_yellow "Using Ollama provider"
        python_command+=(--llm-under-test="$BESMAN_ARTIFACT_PROVIDER::$BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION::http://localhost:11434")
    elif [[ "$BESMAN_ARTIFACT_PROVIDER" == "HuggingFace" ]]; then
        __besman_echo_yellow "Using HuggingFace provider"
        python_command+=(--llm-under-test="$BESMAN_ARTIFACT_PROVIDER::$BESMAN_MODEL_REPO_NAMESPACE/$BESMAN_ARTIFACT_NAME-$BESMAN_ARTIFACT_VERSION::random-string")
    fi

    if [[ "$1" == "--background" ]]; then
        nohup "${python_command[@]}" >"$log_file" 2>&1 &
        benchmark_pid=$!
        echo "$benchmark_pid" >"$pid_file"
        __besman_echo_white "Running in background (PID: $benchmark_pid)"
        export AUTOCOMPLETE_RESULT=0 # You can later check status using PID
        return 0
    else
        nohup "${python_command[@]}" >"$log_file" 2>&1
        exit_code=$?

        if [[ "$exit_code" -ne 0 ]]; then
            export AUTOCOMPLETE_RESULT=1
        else
            export AUTOCOMPLETE_RESULT=0
            if [[ -s "$BESMAN_RESULTS_PATH/autocomplete_stat.json" ]]; then
                jq 'to_entries[0].value' "$BESMAN_RESULTS_PATH/autocomplete_stat.json" >"$BESMAN_RESULTS_PATH/autocomplete_stat.tmp.json"
                mv "$BESMAN_RESULTS_PATH/autocomplete_stat.tmp.json" "$BESMAN_RESULTS_PATH/autocomplete_stat.json"
            else
                __besman_echo_red "[ERROR] autocomplete_stat.json is missing or empty."
                export AUTOCOMPLETE_RESULT=1
            fi
        fi
    fi

    deactivate
}
