#!/bin/bash

function __besman_init() {
    __besman_echo_white "initializing"
    export ASSESSMENT_TOOL_NAME="counterfit"
    export ASSESSMENT_TOOL_TYPE="dast"
    export ASSESSMENT_TOOL_VERSION="0.1.1"
    export ASSESSMENT_TOOL_PLAYBOOK="besman-$ASSESSMENT_TOOL_NAME-0.0.1-playbook.sh"
    
    local steps_file_name="besman-$ASSESSMENT_TOOL_NAME-0.0.1-steps.ipynb"
    export BESMAN_STEPS_FILE_PATH="$BESMAN_PLAYBOOK_DIR/$steps_file_name"

    local var_array=("BESMAN_COUNTERFIT_LOCAL_PATH" "BESMAN_COUNTERFIT_BRANCH" "BESMAN_COUNTERFIT_URL" "BESMAN_ARTIFACT_NAME" "BESMAN_ASSESSMENT_DATASTORE_DIR" "BESMAN_ARTIFACT_VERSION" "BESMAN_ARTIFACT_URL" "BESMAN_ENV_NAME" "BESMAN_LAB_TYPE" "BESMAN_LAB_NAME" "BESMAN_ASSESSMENT_DATASTORE_URL")

    local flag=false
    for var in "${var_array[@]}"; do
        if [[ ! -v $var ]]; then
            __besman_echo_yellow "$var is not set"
            __besman_echo_no_colour ""
            flag=true
        fi
    done

    [[ ! -d $BESMAN_COUNTERFIT_LOCAL_PATH ]] && __besman_echo_red "counterfit not found at $BESMAN_COUNTERFIT_LOCAL_PATH" && flag="true"

    if [[ $flag == true ]]; then
        return 1
    else
        export DETAILED_REPORT_PATH="$BESMAN_ASSESSMENT_DATASTORE_DIR/models/$BESMAN_ARTIFACT_NAME/dast/$BESMAN_ARTIFACT_NAME-dast-summary-report.json"
        export OSAR_PATH="$BESMAN_ASSESSMENT_DATASTORE_DIR/models/$BESMAN_ARTIFACT_NAME/$BESMAN_ARTIFACT_NAME-osar.json"
        __besman_fetch_steps_file "$steps_file_name" || return 1
        return 0
    fi

  

}

function __besman_execute() {
    local duration

    # Isolating the steps file for better use
    mkdir -p "$BESMAN_DIR/tmp/steps"
    __besman_echo_yellow "Launching steps file"
    cp "$BESMAN_STEPS_FILE_PATH" "$BESMAN_DIR/tmp/steps"
    SECONDS=0

     read -p "Running playbook on cloud? (y/n):" clinput
    if [ xx"$clinput" == xx"y" ];then
        jupyter notebook --generatge-config 2>1>/dev/null
        sed -i "s/c.ServerApp.ip = 'localhost'/c.ServerApp.ip = '0.0.0.0'/g" $HOME/.jupyter/jupyter_notebook_config.py
        sed -i "s/# c.ServerApp.open_browser = False/c.ServerApp.open_browser = False/g" $HOME/.jupyter/jupyter_notebook_config.py

        __besman_echo_cyan "Since playbook is executing on cloud so please follow below steps to execute the steps playbook."
        __besman_echo_cyan "   1. Stop and start the jupyter notebook again on the jupyter server."
        __besman_echo_cyan "   2. Capture the jupter notebook token from the screen."
        __besman_echo_cyan "   3. Enable the jupyter notebook port (usaually port 8888) on security group /firewall settings of cloud provider."
        __besman_echo_cyan "   4. Make sure the instance firewall also allowing port of jupter notebook (usually 8888) is allowed."
        __besman_echo_cyan "   5. Open the jupyter notebook ui on the browser using the instance public IP and port number used (usually 8888)."
        __besman_echo_cyan "   6. Enter the token copied above into the UI and connect."
        __besman_echo_cyan "   7. Upload the steps playbook i.e $BESMAN_DIR/tmp/steps to the jupyter notebook ui"
        __besman_echo_cyan "   8. Follow the notebook steps in playbook and press \"y\" for below prompt after executing all playbook steps sucessfully."
        sleep 60
    else
            jupyter notebook "$BESMAN_DIR/tmp/steps"
    fi
    
    while true; do
        read -p "Playbook execution completed? (y/n):" userinput

	if [ xx"$userinput" == xx"y" ];then
           break;
	else
	  echo "Steps playbook need to be completed before proceed."
	fi
    done

    [[ -z $COUNTERFIT_ATTACKID ]] && __besman_echo_red "Attack Id is not set. Required. Please set it and try again." && return 1

    [[ ! -f $BESMAN_COUNTERFIT_LOCAL_PATH/targets/results/${COUNTERFIT_ATTACKID}/run_summary.json ]] && __besman_echo_red "Counterfit result file not found. Execute the playbook to generate the results first." && flag="true"

    duration=$SECONDS

    export EXECUTION_DURATION=$duration
    if [[ ! -f $BESMAN_COUNTERFIT_LOCAL_PATH/targets/results/${COUNTERFIT_ATTACKID}/run_summary.json ]]; then
        export PLAYBOOK_EXECUTION_STATUS=failure
        return 1
    else
        export PLAYBOOK_EXECUTION_STATUS=success
        return 0
    fi

    rm -rf "$BESMAN_DIR/tmp/steps"

}

function __besman_prepare() {
    echo "preparing data"
    EXECUTION_TIMESTAMP=$(date)
    export EXECUTION_TIMESTAMP

    source ~/.bashrc
    cp -f $BESMAN_COUNTERFIT_LOCAL_PATH/targets/results/${COUNTERFIT_ATTACKID}/run_summary.json $DETAILED_REPORT_PATH



    [[ ! -f $DETAILED_REPORT_PATH ]] && __besman_echo_red "Could not find report @ $DETAILED_REPORT_PATH" && return 1

    __besman_generate_osar
}


function __besman_publish() {
    __besman_echo_yellow "Pushing to datastore"
    cd "$BESMAN_ASSESSMENT_DATASTORE_DIR"

    git add models/$BESMAN_ARTIFACT_NAME/*
    git commit -m "Added DAST and OSAR reports for $BESMAN_ARTIFACT_NAME"
    git push origin main
}

function __besman_cleanup() {
    local var_array=("ASSESSMENT_TOOL_NAME" "ASSESSMENT_TOOL_TYPE" "ASSESSMENT_TOOL_VERSION" "ASSESSMENT_TOOL_PLAYBOOK" "BESMAN_STEPS_FILE_PATH" "DETAILED_REPORT_PATH" "OSAR_PATH" "EXECUTION_TIMESTAMP" "EXECUTION_DURATION")

    for var in "${var_array[@]}"; do
        if [[ -v $var ]]; then
            unset "$var"
        fi
    done
    sed -i "/export COUNTERFIT_ATTACKID=/d" ~/.bashrc
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
