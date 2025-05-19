#!/bin/bash
function __besman_init() {
    __besman_echo_white "initialising"
    export ASSESSMENT_TOOL_NAME="CriticalityScore"
    export ASSESSMENT_TOOL_TYPE="PIA"
    export ASSESSMENT_TOOL_VERSION="2.0.3"
    #export BESLAB_OWNER_TYPE="Organization"
    #export BESLAB_OWNER_NAME="Be-Secure"
    export ASSESSMENT_TOOL_PLAYBOOK="besman-$ASSESSMENT_TOOL_TYPE-$ASSESSMENT_TOOL_NAME-playbook-0.0.1.sh"

    local steps_file_name="besman-$ASSESSMENT_TOOL_TYPE-$ASSESSMENT_TOOL_NAME-steps-0.0.1.sh"
    export BESMAN_STEPS_FILE_PATH="$BESMAN_PLAYBOOK_DIR/$steps_file_name"

    local var_array=("BESMAN_ARTIFACT_TYPE" "BESMAN_ARTIFACT_NAME" "BESMAN_ARTIFACT_VERSION" "BESMAN_ARTIFACT_URL" "BESMAN_ENV_NAME" "BESMAN_ARTIFACT_DIR" "ASSESSMENT_TOOL_NAME" "ASSESSMENT_TOOL_TYPE" "ASSESSMENT_TOOL_VERSION" "ASSESSMENT_TOOL_PLAYBOOK" "BESMAN_ASSESSMENT_DATASTORE_DIR" "BESMAN_TOOL_PATH" "BESMAN_ASSESSMENT_DATASTORE_URL" "BESMAN_LAB_TYPE" "BESMAN_LAB_NAME")

    local flag=false
    for var in "${var_array[@]}"; do
        if [[ ! -v $var ]]; then

            # read -rp "Enter value for $var:" value #remove
            # export "$var"="$value" #remove
            __besman_echo_yellow "$var is not set" #uncomment
            __besman_echo_no_colour ""             #uncomment
            flag=true                              #uncomment
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

    # [[ ! -f $BESMAN_TOOL_PATH/$ASSESSMENT_TOOL_NAME ]] && __besman_echo_red "Could not find artifact @ $BESMAN_TOOL_PATH/$ASSESSMENT_TOOL_NAME" && flag=true
    if ! [ -x "$(command -v criticality_score)" ]; then
        __besman_echo_red "required tool - criticality_score is not installed. Please check the installed Bes env"
        flag=true
    fi

    # [[ ! -f $BESMAN_TOOL_PATH/$ASSESSMENT_TOOL_NAME ]] && __besman_echo_red "Could not find artifact @ $BESMAN_TOOL_PATH/$ASSESSMENT_TOOL_NAME" && flag=true
    if [[ -z "$GITHUB_AUTH_TOKEN" ]]; then
        __besman_echo_red "GitHUb token is not set. Run export GITHUB_AUTH_TOKEN=<your access token>"
        flag=true
    fi

    if [[ $flag == true ]]; then
        return 1
    else
        export CRITICALITY_SCORE_PATH="$BESMAN_ASSESSMENT_DATASTORE_DIR/$BESMAN_ARTIFACT_NAME/$BESMAN_ARTIFACT_VERSION/criticality_score"
        export DETAILED_REPORT_PATH="$CRITICALITY_SCORE_PATH/$BESMAN_ARTIFACT_NAME-$BESMAN_ARTIFACT_VERSION-criticality_score-report.json"
        mkdir -p "$CRITICALITY_SCORE_PATH"
        export OSAR_PATH="$BESMAN_ASSESSMENT_DATASTORE_DIR/$BESMAN_ARTIFACT_NAME/$BESMAN_ARTIFACT_VERSION/$BESMAN_ARTIFACT_NAME-$BESMAN_ARTIFACT_VERSION-osar.json"
        
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
    if [[ $CRITICALITY_SCORE_RESULT == 1 ]]; then

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

    __besman_generate_osar

}

function __besman_publish() {
    __besman_echo_yellow "Pushing to datastores"
    # push code to remote datastore
    cd "$BESMAN_ASSESSMENT_DATASTORE_DIR"

    git add "$DETAILED_REPORT_PATH" "$OSAR_PATH"
    git commit -m "Added osar and detailed report"
    git push origin main
}

function __besman_cleanup() {
    local var_array=("ASSESSMENT_TOOL_NAME" "ASSESSMENT_TOOL_TYPE" "ASSESSMENT_TOOL_PLAYBOOK" "ASSESSMENT_TOOL_VERSION" "OSAR_PATH" "CRITICALITY_SCORE_PATH" "DETAILED_REPORT_PATH")

    for var in "${var_array[@]}"; do
        if [[ -v $var ]]; then
            unset "$var"
        fi

    done

}

# function launch
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

