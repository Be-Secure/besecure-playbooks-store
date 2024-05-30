#!/bin/bash

function __besman_init() {
    __besman_echo_white "initializing"
    export ASSESSMENT_TOOL_NAME="watchtower"
    export ASSESSMENT_TOOL_TYPE="ml-model-scanner"
    export ASSESSMENT_TOOL_VERSION="0.0.1"
    export ASSESSMENT_TOOL_PLAYBOOK="besman-$ASSESSMENT_TOOL_NAME-$ASSESSMENT_TOOL_VERSION-playbook.sh"
    
    local steps_file_name="besman-$ASSESSMENT_TOOL_NAME-$ASSESSMENT_TOOL_VERSION-steps.sh"
    export BESMAN_STEPS_FILE_PATH="$BESMAN_PLAYBOOK_DIR/$steps_file_name"

    # List of environment variables
    local var_array=("BESMAN_REPO_TYPE" "BESMAN_REPO_URL" "BESMAN_BRANCH_NAME" "BESMAN_DEPTH_VAL" "BESMAN_ARTIFACT_NAME")

    # Set values for testing (remove in production)
    export BESMAN_REPO_TYPE="huggingface"         # Example value
    export BESMAN_REPO_URL="https://huggingface.co/vendorabc/modeltest"  # Example value
    export BESMAN_BRANCH_NAME="main"          # Example value
    export BESMAN_DEPTH_VAL="1"              # Example value
    export BESMAN_ARTIFACT_NAME="modeltest"  # Example value

    local flag=false
    for var in "${var_array[@]}"; do
        if [[ ! -v $var ]]; then
            __besman_echo_yellow "$var is not set"
            __besman_echo_no_colour ""
            flag=true
        fi
    done

    if [[ $flag == true ]]; then
        return 1
    else
        __besman_fetch_steps_file "$steps_file_name" || return 1
        return 0
    fi
}

function __besman_execute() {
    local duration
    __besman_echo_yellow "Launching steps file"

    SECONDS=0
    . "$BESMAN_STEPS_FILE_PATH"
    duration=$SECONDS

    export EXECUTION_DURATION=$duration
    if [[ $SCAN_RESULT == 1 ]]; then
        export PLAYBOOK_EXECUTION_STATUS=failure
        return 1
    else
        export PLAYBOOK_EXECUTION_STATUS=success
        return 0
    fi
}

function __besman_prepare() {
    __besman_echo_white "preparing data"
    EXECUTION_TIMESTAMP=$(date)
    export EXECUTION_TIMESTAMP

    local report_id_dir=$(grep -oP '(?<=scanned_reports/)[0-9]+' <<< "$SCAN_OUTPUT")
    local summary_report="$HOME/watchtower/src/scanned_reports/$report_id_dir/summary_reports_$report_id_dir.json"
    local detailed_report="$HOME/watchtower/src/scanned_reports/$report_id_dir/detailed_reports_$report_id_dir.json"

    local target_dir="$HOME/besecure-ml-assessment-datastore/models/$BESMAN_ARTIFACT_NAME/sast"
    mkdir -p "$target_dir"

    cp "$summary_report" "$target_dir/$BESMAN_ARTIFACT_NAME-sast-summary-report.json"
    cp "$detailed_report" "$target_dir/$BESMAN_ARTIFACT_NAME-sast-detailed-report.json"
}

function __besman_publish() {
    __besman_echo_yellow "Pushing to datastore"
    cd "$HOME/besecure-ml-assessment-datastore"

    git add models/"$BESMAN_ARTIFACT_NAME"/sast/*.json
    git commit -m "Added SAST reports for $BESMAN_ARTIFACT_NAME"
    git push origin main
}

function __besman_cleanup() {
    local var_array=("BESMAN_REPO_TYPE" "BESMAN_REPO_URL" "BESMAN_BRANCH_NAME" "BESMAN_DEPTH_VAL" "BESMAN_ARTIFACT_NAME")

    for var in "${var_array[@]}"; do
        if [[ -v $var ]]; then
            unset "$var"
        fi
    done
}

function __besman_launch() {
    __besman_echo_yellow "Starting playbook"
    local flag=1

    __besman_init
    flag=$?
    if [[ $flag == 0 ]]; then
        __besman_execute
        flag=$?
    else
        __besman_cleanup
        return
    fi

    if [[ $flag == 0 ]]; then
        __besman_prepare
        __besman_publish
        __besman_cleanup
    else
        __besman_cleanup
        return
    fi
}

function __besman_fetch_steps_file() {
    echo "Fetching steps file"
    local steps_file_name=$1

    if [[ ! -f "$BESMAN_STEPS_FILE_PATH" ]]; then
        echo "Steps file not found: $BESMAN_STEPS_FILE_PATH"
        return 1
    fi
    echo "Steps file found: $BESMAN_STEPS_FILE_PATH"
}
