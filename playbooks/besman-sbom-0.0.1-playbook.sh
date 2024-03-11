#!/bin/bash

function __besman_init() {
    echo "initialising"
    local steps_file_name="besman-sbom-0.0.1-steps.sh"
    export ASSESSMENT_TOOL_NAME="spdx-sbom-generator"
    export ASSESSMENT_TOOL_TYPE="sbom"
    export ASSESSMENT_TOOL_VERSION="v0.0.15"
    export ASSESSMENT_TOOL_PLAYBOOK="besman-$ASSESSMENT_TOOL_TYPE-$ASSESSMENT_TOOL_VERSION-playbook.sh"
    export OSAR_PATH="/home/arun/besecure-assessment-datastore/osar"
    export BESMAN_STEPS_FILE_PATH="$BESMAN_PLAYBOOK_DIR/$steps_file_name"

    local var_array=("BESMAN_ARTIFACT_TYPE" "BESMAN_ARTIFACT_NAME" "BESMAN_ARTIFACT_VERSION" "BESMAN_ARTIFACT_URL" "BESMAN_ENV_NAME" "BESMAN_ARTIFACT_DIR" "ASSESSMENT_TOOL_NAME" "ASSESSMENT_TOOL_TYPE" "ASSESSMENT_TOOL_VERSION" "ASSESSMENT_TOOL_PLAYBOOK" "BESLAB_ASSESSMENT_DATASTORE_DIR" "BESLAB_ARTIFACT_PATH" "BESLAB_REPORT_FORMAT" "BESLAB_ASSESSMENT_DATASTORE_URL" "OSAR_PATH")

    local flag=false
    for var in "${var_array[@]}"; do
        if [[ ! -v $var ]]; then

            read -rp "Enter value for $var:" value #remove
            export "$var"="$value" #remove
            # __besman_echo_yellow "$var is not set" #uncomment
            # __besman_echo_no_colour "" #uncomment
            # flag=true #uncomment
        fi

    done

    local dir_array=("BESLAB_ASSESSMENT_DATASTORE_DIR")

    for dir in "${dir_array[@]}"; do
        # Get the value of the variable with the name stored in $dir
        dir_path="${!dir}"

        if [[ ! -d $dir_path ]]; then

            __besman_echo_red "Could not find $dir_path"

            flag=true

        fi

    done
    echo "checking for maven"
    if [[ -z $(which mvn) ]] 
    then
        __besman_echo_red "Could not find maven"
        flag=true
    fi

    [[ ! -f $BESLAB_ARTIFACT_PATH/$ASSESSMENT_TOOL_NAME ]] && __besman_echo_red "Could not find artifact @ $BESLAB_ARTIFACT_PATH/$ASSESSMENT_TOOL_NAME" && flag=true

    if [[ $flag == true ]]; then

        return 1

    else
        export SBOM_PATH="$BESLAB_ASSESSMENT_DATASTORE_DIR/$BESMAN_ARTIFACT_NAME/$BESMAN_ARTIFACT_VERSION/sbom"
        export DETAILED_REPORT_PATH="$SBOM_PATH/$BESMAN_ARTIFACT_NAME-$BESMAN_ARTIFACT_VERSION-sbom-report.$BESLAB_REPORT_FORMAT"
        mkdir -p "$SBOM_PATH"
        ls $BESLAB_ASSESSMENT_DATASTORE_DIR/$BESMAN_ARTIFACT_NAME/$BESMAN_ARTIFACT_VERSION
        export OSAR_PATH="$BESLAB_ASSESSMENT_DATASTORE_DIR/osar/$BESMAN_ARTIFACT_NAME-$BESMAN_ARTIFACT_VERSION-OSAR.json"
        __besman_fetch_steps_file "$steps_file_name" || return 1
        return 0

    fi

}

function __besman_execute() {
    local duration
    __besman_echo_yellow "Launching steps file"

    SECONDS=0
    echo "$BESMAN_STEPS_FILE_PATH"
    . "$BESMAN_STEPS_FILE_PATH"
    duration=$SECONDS

    export EXECUTION_DURATION=$duration
    if [[ $SBOM_RESULT == 1 ]]; then

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
    ls "$SBOM_PATH"
    mv "$SBOM_PATH"/bom-*.json "$DETAILED_REPORT_PATH" || return 1

    # The below function is yet to be implemented.
    # __besman_prepare_osar

}

function __besman_publish() {
    __besman_echo_yellow "Pushing to datastores"
    # push code to remote datastore
    cd "$BESLAB_ASSESSMENT_DATASTORE_DIR"

    git add .
    git commit -m "Added osar and detailed report"
    git push origin main
    # Fix code
    gh pr create --title "Added reports" --body "Added osar and detailed reports"

}

function __besman_cleanup() {
    local var_array=("ASSESSMENT_TOOL_NAME" "ASSESSMENT_TOOL_TYPE" "ASSESSMENT_TOOL_PLAYBOOK" "ASSESSMENT_TOOL_VERSION" "OSAR_PATH" "SBOM_PATH" "DETAILED_REPORT_PATH")

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
    echo "fetching steps file"
    local steps_file_name=$1
    local steps_file_url="https://raw.githubusercontent.com/$BESMAN_NAMESPACE/$BESMAN_PLAYBOOK_REPO/main/playbooks/$steps_file_name"
    echo "$steps_file_url"
    __besman_check_url_valid "$steps_file_url" || return 1

    if [[ ! -f "$BESMAN_STEPS_FILE_PATH" ]]; then
    
        touch "$BESMAN_STEPS_FILE_PATH"

        __besman_secure_curl "$steps_file_url" >>"$BESMAN_STEPS_FILE_PATH"
    [[ "$?" != "0" ]] && __besman_echo_red "Failed to fetch from $steps_file_url" && return 1
    fi
    echo "done fetching"
}
