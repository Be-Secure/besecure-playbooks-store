#!/bin/bash

function __besman_run_interpreter_assessment() {
    __besman_echo_white "Running $ASSESSMENT_TOOL_NAME-$ASSESSMENT_TOOL_TYPE"

    cd "$BESMAN_TOOL_PATH/PurpleLlama" || return 1

    ## Activate venv
    if [[ ! -d ~/.venvs/CybersecurityBenchmarks ]]; then
        __besman_echo_red "[ERROR] Python virtual environment for CybersecurityBenchmarks is missing."
        return 1
    fi

    source ~/.venvs/CybersecurityBenchmarks/bin/activate

    function get_judge_parameters() {
        if [[ "$BESMAN_JUDGE_LLM_PROVIDER" == "AWSBedrock" ]]; then
            echo "AWSBedrock::$BESMAN_JUDGE_LLM_NAME.$BESMAN_JUDGE_LLM_VERSION::$AWS_ACCESS_KEY_ID/$AWS_SECRET_ACCESS_KEY"
        elif [[ "$BESMAN_JUDGE_LLM_PROVIDER" == "Ollama" ]]; then
            echo "Ollama::$BESMAN_JUDGE_LLM_NAME:$BESMAN_JUDGE_LLM_VERSION::http://localhost:11434"
        elif [[ "$BESMAN_JUDGE_LLM_PROVIDER" == "HuggingFace" ]]; then
            echo "HuggingFace::$BESMAN_JUDGE_MODEL_REPO_NAMESPACE/$BESMAN_JUDGE_LLM_NAME-$BESMAN_JUDGE_LLM_VERSION::random-string"
        else
            __besman_echo_red "[ERROR] Unsupported judge LLM provider: $BESMAN_JUDGE_LLM_PROVIDER"
            return 1
        fi
    }

    judge_parameters=$(get_judge_parameters)
    [[ $? -ne 0 ]] && return 1

    base_name="${ASSESSMENT_TOOL_NAME}-${ASSESSMENT_TOOL_TYPE// /_}"
    log_file="/tmp/${base_name}_assessment.log"
    pid_file="/tmp/${base_name}_assessment.pid"

    __besman_echo_yellow "Log file: $log_file"
    __besman_echo_yellow "PID file: $pid_file"

    # Check for existing running process
    if [[ -f "$pid_file" ]]; then
        existing_pid=$(<"$pid_file")
        if ps -p "$existing_pid" > /dev/null 2>&1; then
            __besman_echo_yellow "[INFO] Assessment is already running with PID $existing_pid"
            __besman_echo_yellow "[INFO] To view logs: tail -f $log_file"
            deactivate
            return 0
        else
            __besman_echo_yellow "[INFO] Stale PID file found. Cleaning up."
            rm -f "$pid_file"
        fi
    fi

    # Compose Python command
    python_command=(
        python3 -m CybersecurityBenchmarks.benchmark.run
        --benchmark=interpreter
        --prompt-path="$BESMAN_CYBERSECEVAL_DATASETS/interpreter/interpreter.json"
        --response-path="$BESMAN_RESULTS_PATH/interpreter_responses.json"
        --judge-response-path="$BESMAN_RESULTS_PATH/interpreter_judge_responses.json"
        --stat-path="$BESMAN_RESULTS_PATH/interpreter_stat.json"
        --judge-llm="$judge_parameters"
        --run-llm-in-parallel
        --num-test-cases="$BESMAN_NUM_TEST_CASES_INTERPRETER"
    )

    if [[ "$BESMAN_ARTIFACT_PROVIDER" == "Ollama" ]]; then
        __besman_echo_yellow "Using Ollama provider"
        python_command+=(--llm-under-test="$BESMAN_ARTIFACT_PROVIDER::$BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION::http://localhost:11434")
    elif [[ "$BESMAN_ARTIFACT_PROVIDER" == "HuggingFace" ]]; then
        __besman_echo_yellow "Using HuggingFace provider"
        python_command+=(--llm-under-test="$BESMAN_ARTIFACT_PROVIDER::$BESMAN_MODEL_REPO_NAMESPACE/$BESMAN_ARTIFACT_NAME-$BESMAN_ARTIFACT_VERSION::random-string")
    fi

    if [[ "$1" == "--background" ]]; then
        nohup "${python_command[@]}" > "$log_file" 2>&1 &
        echo "$!" > "$pid_file"
        __besman_echo_white "Interpreter benchmark started in background (PID: $!)"
        export CODE_INTERPRETER_RESULT=0
        return 0
    else
        nohup "${python_command[@]}" > "$log_file" 2>&1
        exit_code=$?

        if [[ "$exit_code" -ne 0 ]]; then
            __besman_echo_red "[ERROR] Interpreter benchmark failed."
            export CODE_INTERPRETER_RESULT=1
        else
            if [[ -s "$BESMAN_RESULTS_PATH/interpreter_stat.json" ]]; then
                jq 'to_entries[0].value' "$BESMAN_RESULTS_PATH/interpreter_stat.json" >"$BESMAN_RESULTS_PATH/interpreter_stat.tmp.json"
                mv "$BESMAN_RESULTS_PATH/interpreter_stat.tmp.json" "$BESMAN_RESULTS_PATH/interpreter_stat.json"
                export CODE_INTERPRETER_RESULT=0
            else
                __besman_echo_red "[ERROR] interpreter_stat.json is missing or empty."
                export CODE_INTERPRETER_RESULT=1
            fi
        fi
    fi

    deactivate
}
