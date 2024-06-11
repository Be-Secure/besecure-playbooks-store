#!/bin/bash

function __besman_init() {
    __besman_echo_white "initializing"
    export ASSESSMENT_TOOL_NAME="watchtower"
    export ASSESSMENT_TOOL_TYPE="sast"
    export ASSESSMENT_TOOL_VERSION="0.0.1"
    export ASSESSMENT_TOOL_PLAYBOOK="besman-$ASSESSMENT_TOOL_NAME-$ASSESSMENT_TOOL_VERSION-playbook.sh"
    
    local steps_file_name="besman-$ASSESSMENT_TOOL_NAME-$ASSESSMENT_TOOL_VERSION-steps.sh"
    export BESMAN_STEPS_FILE_PATH="$BESMAN_PLAYBOOK_DIR/$steps_file_name"

    local var_array=("BESMAN_TARGET_REPO_TYPE" "BESMAN_TARGET_BRANCH_NAME" "BESMAN_TARGET_DEPTH_VAL" "BESMAN_ARTIFACT_NAME" "BESMAN_ASSESSMENT_DATASTORE_DIR" "BESMAN_WATCHTOWER_PATH")

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
        export DETAILED_REPORT_PATH="$BESMAN_ASSESSMENT_DATASTORE_DIR/models/$BESMAN_ARTIFACT_NAME/sast/$BESMAN_ARTIFACT_NAME-sast-summary-report.json"
        export OSAR_PATH="$BESMAN_ASSESSMENT_DATASTORE_DIR/models/$BESMAN_ARTIFACT_NAME/$BESMAN_ARTIFACT_NAME-osar.json"
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
    echo "preparing data"
    EXECUTION_TIMESTAMP=$(date)
    export EXECUTION_TIMESTAMP

    local report_id_dir=$(echo "$SCAN_OUTPUT" | grep -oP '(?<=scanned_reports/)[0-9]+(?=/summary_reports_)')
    local summary_report="./scanned_reports/$report_id_dir/summary_reports_$report_id_dir.json"
    local detailed_report="./scanned_reports/$report_id_dir/detailed_reports_$report_id_dir.json"

    local target_dir="$BESMAN_ASSESSMENT_DATASTORE_DIR/models/$BESMAN_ARTIFACT_NAME/sast"
    mkdir -p "$target_dir"

    cp "$summary_report" "$target_dir/$BESMAN_ARTIFACT_NAME-sast-summary-report.json"
    cp "$detailed_report" "$target_dir/$BESMAN_ARTIFACT_NAME-sast-detailed-report.json"

    rm -rf "./scanned_reports"
    __besman_generate_osar
}


function __besman_publish() {
    __besman_echo_yellow "Pushing to datastore"
    cd "$BESMAN_ASSESSMENT_DATASTORE_DIR"

    git add models/$BESMAN_ARTIFACT_NAME/*
    git commit -m "Added SAST and OSAR reports for $BESMAN_ARTIFACT_NAME"
    git push origin main
}

function __besman_cleanup() {
    local var_array=("BESMAN_TARGET_REPO_TYPE" "BESMAN_TARGET_BRANCH_NAME" "BESMAN_TARGET_DEPTH_VAL" "BESMAN_ARTIFACT_NAME" "BESMAN_ASSESSMENT_DATASTORE_DIR" "BESMAN_WATCHTOWER_PATH")

    for var in "${var_array[@]}"; do
        if [[ -v $var ]]; then
            unset "$var"
        fi
    done

    deactivate
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
    local steps_file_url="https://raw.githubusercontent.com/$BESMAN_PLAYBOOK_REPO/$BESMAN_PLAYBOOK_REPO_BRANCH/playbooks/$steps_file_name"
    __besman_check_url_valid "$steps_file_url" || return 1

    if [[ ! -f "$BESMAN_STEPS_FILE_PATH" ]]; then
        touch "$BESMAN_STEPS_FILE_PATH"
        __besman_secure_curl "$steps_file_url" >>"$BESMAN_STEPS_FILE_PATH"
        [[ "$?" != "0" ]] && echo "Failed to fetch from $steps_file_url" && return 1
    fi
    echo "Done fetching"
}
