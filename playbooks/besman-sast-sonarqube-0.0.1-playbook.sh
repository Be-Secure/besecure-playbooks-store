#!/bin/bash

# Author: Samir Ranjan Parhi
# License: Same as Repository Licence
# Usage : Beta-Release
# Date : 12/04/2024

function __besman_init() {
    __besman_echo_white "initialising"
    export ASSESSMENT_TOOL_NAME="sonarqube"
    export ASSESSMENT_TOOL_TYPE="SAST"
    export ASSESSMENT_TOOL_VERSION="9.9.4"
    export ASSESSMENT_TOOL_PLAYBOOK="besman-$ASSESSMENT_TOOL_TYPE-$ASSESSMENT_TOOL_NAME-playbook.sh"
    
    export steps_file_name="besman-$ASSESSMENT_TOOL_TYPE-$ASSESSMENT_TOOL_NAME-steps.md"
    export BESMAN_STEPS_FILE_PATH="$BESMAN_PLAYBOOK_DIR/$steps_file_name"

        local var_array=("BESMAN_ARTIFACT_TYPE" "BESMAN_ARTIFACT_NAME" "BESMAN_ARTIFACT_VERSION" "BESMAN_ARTIFACT_URL" "BESMAN_ENV_NAME" "BESMAN_ARTIFACT_DIR" "ASSESSMENT_TOOL_NAME" "ASSESSMENT_TOOL_TYPE" "ASSESSMENT_TOOL_VERSION" "ASSESSMENT_TOOL_PLAYBOOK" "BESMAN_ASSESSMENT_DATASTORE_DIR" "BESMAN_TOOL_PATH" "BESMAN_ASSESSMENT_DATASTORE_URL" "BESMAN_LAB_TYPE" "BESMAN_LAB_NAME")

    local flag=false
    for var in "${var_array[@]}"; do
        if [[ ! -v $var ]]; then

            # read -rp "Enter value for $var:" value #remove
            # export "$var"="$value" #remove
            __besman_echo_yellow "$var is not set" #uncomment
            __besman_echo_no_colour "" #uncomment
            flag=true #uncomment
        fi

    done
    


    local dir_array=("BESMAN_ASSESSMENT_DATASTORE_DIR")

    for dir in "${dir_array[@]}"; do
        # Get the value of the variable with the name stored in $dir
        dir_path="${!dir}"

        if [[ ! -d $dir_path ]]; then

            __besman_echo_red "Could not find $dir_path"

            flag=true

        fi

    done

    [[ ! -f $BESMAN_TOOL_PATH/$ASSESSMENT_TOOL_NAME ]] && __besman_echo_red "Could not find artifact @ $BESMAN_TOOL_PATH/$ASSESSMENT_TOOL_NAME" && flag=true

    if [[ $flag == true ]]; then

        return 1

    else
        export SONAR_PATH="$BESMAN_ASSESSMENT_DATASTORE_DIR/$BESMAN_ARTIFACT_NAME/$BESMAN_ARTIFACT_VERSION/$ASSESSMENT_TOOL_TYPE/$ASSESSMENT_TOOL_NAME"
        export DETAILED_REPORT_PATH="$SONAR_PATH/$BESMAN_ARTIFACT_NAME-$BESMAN_ARTIFACT_VERSION-$ASSESSMENT_TOOL_TYPE-$ASSESSMENT_TOOL_NAME-report.json"
        mkdir -p "$SONAR_PATH"
        export OSAR_PATH="$BESMAN_ASSESSMENT_DATASTORE_DIR/osar/$BESMAN_ARTIFACT_NAME-$BESMAN_ARTIFACT_VERSION-OSAR.json"
        __besman_fetch_steps_file "$steps_file_name" || return 1
        return 0

    fi

}

function __besman_execute() {
    
    __besman_echo_yellow "Launching steps file"
    echo -e " ### ⚠️ important !!! You Should Store this Scan report to $DETAILED_REPORT_PATH " >> $BESMAN_STEPS_FILE_PATH
    # code BESMAN_STEPS_FILE_PATH

    xdg-open https://github.com/Be-Secure/besecure-playbooks-store/blob/main/playbooks/besman-sonarqube_scanning-steps.md

    # Wait until browser window is closed
    while pgrep -f "$(xdg-mime query default text/html)" > /dev/null; do
    sleep 1
    done
    #Wait till VS code is closed
    # while pgrep -x "Visual Studio Code" > /dev/null; do
    # sleep 1
    # done

}

function __besman_prepare() {

    __besman_echo_white "preparing data"
    EXECUTION_TIMESTAMP=$(date)
    export EXECUTION_TIMESTAMP
    __besman_generate_osar

}

function __besman_publish() {
    __besman_echo_yellow "Uploading Sonar Report to Local datastore directories"
    
    # push code to remote datastore
    cd "$BESMAN_ASSESSMENT_DATASTORE_DIR"
    git add "$DETAILED_REPORT_PATH" "$OSAR_PATH"
    git commit -m "Added osar and detailed report"
    git push origin main

    # Fix code
    # gh pr create --title "Added reports" --body "Added osar and detailed reports"

}

function __besman_cleanup() {
    local var_array=("ASSESSMENT_TOOL_NAME" "ASSESSMENT_TOOL_TYPE" "ASSESSMENT_TOOL_PLAYBOOK" "ASSESSMENT_TOOL_VERSION" "OSAR_PATH" "SONAR_PATH" "DETAILED_REPORT_PATH")

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
    __besman_echo_white "fetching steps file"
    local steps_file_name=$1
    local steps_file_url="https://raw.githubusercontent.com/$BESMAN_NAMESPACE/$BESMAN_PLAYBOOK_REPO/main/playbooks/$steps_file_name"
    __besman_check_url_valid "$steps_file_url" || return 1

    if [[ ! -f "$BESMAN_STEPS_FILE_PATH" ]]; then
    
        touch "$BESMAN_STEPS_FILE_PATH"

        __besman_secure_curl "$steps_file_url" >>"$BESMAN_STEPS_FILE_PATH"
    [[ "$?" != "0" ]] && __besman_echo_red "Failed to fetch from $steps_file_url" && return 1
    fi
    __besman_echo_white "done fetching"
}