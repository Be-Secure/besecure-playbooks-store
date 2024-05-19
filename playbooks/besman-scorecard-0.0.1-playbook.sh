#!/bin/bash

function __besman_init() {
    __besman_echo_white "initialising"
    export ASSESSMENT_TOOL_NAME="ossf scorecard"
    export ASSESSMENT_TOOL_TYPE="scorecard"
    export ASSESSMENT_TOOL_VERSION="v4.13.1"
    export ASSESSMENT_TOOL_PLAYBOOK="besman-scorecard-0.0.1-playbook.sh"
    
    local steps_file_name="besman-scorecard-0.0.1-steps.sh"
    export BESMAN_STEPS_FILE_PATH="$BESMAN_PLAYBOOK_DIR/$steps_file_name"

    local var_array=("BESMAN_ARTIFACT_TYPE" "BESMAN_ARTIFACT_NAME" "BESMAN_ARTIFACT_VERSION" "BESMAN_ARTIFACT_URL" "BESMAN_ENV_NAME" "BESMAN_ARTIFACT_DIR" "ASSESSMENT_TOOL_NAME" "ASSESSMENT_TOOL_TYPE" "ASSESSMENT_TOOL_VERSION" "ASSESSMENT_TOOL_PLAYBOOK" "BESMAN_ASSESSMENT_DATASTORE_DIR" "BESMAN_ASSESSMENT_DATASTORE_URL" "BESMAN_LAB_TYPE" "BESMAN_LAB_NAME")

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

    if [[ -z $BESMAN_GH_TOKEN ]] 
    then
        __besman_echo_red "GitHub Auth token not found"
        __besman_echo_white ""
        __besman_echo_white "Run the below command to set it"
        __besman_echo_white ""
        __besman_echo_yellow "$ export BESMAN_GH_TOKEN=<token>"
        __besman_echo_white ""
        flag=true
    fi

    # [[ ! -f $BESMAN_TOOL_PATH/$ASSESSMENT_TOOL_NAME ]] && __besman_echo_red "Could not find artifact @ $BESMAN_TOOL_PATH/$ASSESSMENT_TOOL_NAME" && flag=true

    if [[ $flag == true ]]; then

        return 1

    else
        export SCORECARD_PATH="$BESMAN_ASSESSMENT_DATASTORE_DIR/$BESMAN_ARTIFACT_NAME/$BESMAN_ARTIFACT_VERSION/scorecard"
        export DETAILED_REPORT_PATH="$SCORECARD_PATH/$BESMAN_ARTIFACT_NAME-$BESMAN_ARTIFACT_VERSION-scorecard-report.json"
        mkdir -p "$SCORECARD_PATH"
        export OSAR_PATH="$BESMAN_ASSESSMENT_DATASTORE_DIR/osar/$BESMAN_ARTIFACT_NAME-$BESMAN_ARTIFACT_VERSION-OSAR.json"
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

}

function __besman_prepare() {

    EXECUTION_TIMESTAMP=$(date)
    export EXECUTION_TIMESTAMP
    __besman_echo_white "preparing data"
    
    # Check if the CodeQL GitHub Action is configured 
    # export workflow_id=$(curl -s -H "Authorization: token $BESMAN_GH_TOKEN" \
    # -H "Accept: application/vnd.github.v3+json" \
    # "https://api.github.com/repos/$BESMAN_USER_NAMESPACE/$BESMAN_ARTIFACT_NAME/actions/workflows" | jq -r '.workflows[] | select(.name == "Scorecard supply-chain security") | .id')
    # #echo $workflow_id
    # if [ -z "$workflow_id" ]; then
    #     echo "Scorecard github actions is not configured"  
    #     cat $BESMAN_STEPS_FILE_PATH
    #     echo -e "\nPress enter if the above steps are completed."
    #     read enter_key
    # else
    #     echo "Scorecard GitHub Action is configured"
    # fi

    # #downloading scorecard report
    # curl -X 'GET' \
    # "https://api.securityscorecards.dev/projects/github.com/$BESMAN_USER_NAMESPACE/$BESMAN_ARTIFACT_NAME" \
    # -H "accept: application/json" >> $BESMAN_ARTIFACT_NAME-$BESMAN_ARTIFACT_VERSION-scorecard-temp.json
    # EXECUTION_TIMESTAMP=$(date)
    # export EXECUTION_TIMESTAMP
    # python3 -m json.tool $BESMAN_ARTIFACT_NAME-$BESMAN_ARTIFACT_VERSION-scorecard-temp.json > $BESMAN_ARTIFACT_NAME-$BESMAN_ARTIFACT_VERSION-scorecard.json
    # rm $BESMAN_ARTIFACT_NAME-$BESMAN_ARTIFACT_VERSION-scorecard-temp.json
    # mv $BESMAN_ARTIFACT_NAME-$BESMAN_ARTIFACT_VERSION-scorecard.json "$DETAILED_REPORT_PATH"

    __besman_generate_osar

}

function __besman_publish() {
    __besman_echo_yellow "Pushing to datastores"
    # push code to remote datastore
    cd "$BESMAN_ASSESSMENT_DATASTORE_DIR"

    git add "$DETAILED_REPORT_PATH" "$OSAR_PATH"
    git commit -m "Added osar and detailed report"
    git push origin main
    # Fix code
    # gh pr create --title "Added reports" --body "Added osar and detailed reports"

}

function __besman_cleanup() {
    local var_array=("ASSESSMENT_TOOL_NAME" "ASSESSMENT_TOOL_TYPE" "ASSESSMENT_TOOL_PLAYBOOK" "ASSESSMENT_TOOL_VERSION" "OSAR_PATH" "SCORECARD_PATH" "DETAILED_REPORT_PATH")

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
   local steps_file_url="https://raw.githubusercontent.com/$BESMAN_PLAYBOOK_REPO/$BESMAN_PLAYBOOK_REPO_BRANCH/playbooks/$steps_file_name"
   __besman_check_url_valid "$steps_file_url" || return 1

   if [[ ! -f "$BESMAN_STEPS_FILE_PATH" ]]; then
    
       touch "$BESMAN_STEPS_FILE_PATH"

       __besman_secure_curl "$steps_file_url" >>"$BESMAN_STEPS_FILE_PATH"
   [[ "$?" != "0" ]] && __besman_echo_red "Failed to fetch from $steps_file_url" && return 1
   fi
    # nano $BESMAN_STEPS_FILE_PATH
    # wait
    # __besman_echo_white "Generating the scorecard report"
}
