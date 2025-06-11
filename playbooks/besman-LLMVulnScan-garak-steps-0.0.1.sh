#!/bin/bash

function __besman_run_garak_assessment_in_background() {
    __besman_echo_white "Running Garak assessment"

    # Ensure conda is sourced
    source /opt/conda/etc/profile.d/conda.sh || {
        __besman_echo_red "[ERROR] Failed to source conda.sh"
        return 1
    }

    conda activate garak || {
        __besman_echo_red "[ERROR] Failed to activate Garak conda environment"
        return 1
    }

    # Create report name and paths
    base_name="${BESMAN_ARTIFACT_NAME//:/_}_garak"
    log_file="/tmp/${base_name}_assessment.log"
    pid_file="/tmp/${base_name}_assessment.pid"
    report_file="$GARAK_TEST_REPORT_PATH/${BESMAN_ARTIFACT_NAME}:${BESMAN_ARTIFACT_VERSION}-garak-test-detailed.report.json"

    __besman_echo_yellow "Log file: $log_file"
    __besman_echo_yellow "PID file: $pid_file"

    # Check if another instance is already running
    if [[ -f "$pid_file" ]]; then
        existing_pid=$(<"$pid_file")
        if ps -p "$existing_pid" > /dev/null 2>&1; then
            __besman_echo_yellow "[INFO] Garak assessment already running with PID $existing_pid"
            __besman_echo_yellow "[INFO] To view logs: tail -f $log_file"
            conda deactivate
            return 0
        else
            __besman_echo_yellow "[INFO] Found stale PID file. Cleaning up."
            rm -f "$pid_file"
        fi
    fi

    # Construct Garak command
    local garak_command=(
        garak
        --probes "$BESMAN_GARAK_PROBES"
        --report_prefix "$GARAK_TEST_REPORT_PATH/${BESMAN_ARTIFACT_NAME}:${BESMAN_ARTIFACT_VERSION}-garak-test-detailed"
    )

    if [[ "$BESMAN_ARTIFACT_PROVIDER" == "Ollama" ]]; then
        __besman_echo_yellow "Using Ollama provider"
        garak_command+=(--model_type ollama --model_name "$BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION")
    elif [[ "$BESMAN_ARTIFACT_PROVIDER" == "HuggingFace" ]]; then
        __besman_echo_yellow "Using HuggingFace provider"
        garak_command+=(--model_type huggingface --model_name "$BESMAN_MODEL_REPO_NAMESPACE/$BESMAN_ARTIFACT_NAME-$BESMAN_ARTIFACT_VERSION")
    fi

    if [[ "$1" == "--background" ]]; then
        nohup "${garak_command[@]}" >"$log_file" 2>&1 &
        garak_pid=$!
        echo "$garak_pid" >"$pid_file"
        __besman_echo_white "Running Garak in background (PID: $garak_pid)"
        export GARAK_RESULT=0
        return 0
    else
        nohup "${garak_command[@]}" >"$log_file" 2>&1
        exit_code=$?

        if [[ "$exit_code" -ne 0 ]]; then
            __besman_echo_red "[ERROR] Garak execution failed"
            export GARAK_RESULT=1
        else
            if [[ -f "$report_file" ]]; then
                [[ -f "$DETAILED_REPORT_PATH" ]] && rm "$DETAILED_REPORT_PATH"
                jq -n '
                    reduce inputs as $i ({}; 
                        if $i.entry_type == "eval" then
                            .[$i.probe | split(".")[0]] |= (. // {}) |
                            .[$i.probe | split(".")[0]][($i.probe | split(".")[1])] |= (. // {}) |
                            .[$i.probe | split(".")[0]][($i.probe | split(".")[1])][($i.detector | split(".")[-1])] = $i
                        else
                            .
                        end
                    )
                ' "$report_file" > "$DETAILED_REPORT_PATH"
                export GARAK_RESULT=0
            else
                __besman_echo_red "[ERROR] Garak report not found at $report_file"
                export GARAK_RESULT=1
                conda deactivate
                return 1
            fi
        fi
    fi

    conda deactivate
}
