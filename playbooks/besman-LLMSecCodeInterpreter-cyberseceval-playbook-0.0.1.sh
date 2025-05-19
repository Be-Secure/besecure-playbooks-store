#!/bin/bash
function __besman_init() {
    __besman_echo_white "initialising"
    export ASSESSMENT_TOOL_NAME="cybersecevalInterpreter"
    export ASSESSMENT_TOOL_TYPE="Security Benchmark"
    export ASSESSMENT_TOOL_VERSION="3"
    #export BESLAB_OWNER_TYPE="Organization"
    #export BESLAB_OWNER_NAME="Be-Secure"
    export ASSESSMENT_TOOL_PLAYBOOK="besman-LLMSecCodeInterpreter-cyberseceval-playbook-0.0.1.sh"

    local steps_file_name="besman-LLMSecCodeInterpreter-cyberseceval-steps-0.0.1.sh"
    export BESMAN_STEPS_FILE_PATH="$BESMAN_PLAYBOOK_DIR/$steps_file_name"

    local var_array=("BESMAN_ARTIFACT_PROVIDER" "BESMAN_NUM_TEST_CASES_INTERPRETER" "BESMAN_ARTIFACT_TYPE" "BESMAN_ARTIFACT_NAME" "BESMAN_ARTIFACT_VERSION" "BESMAN_ARTIFACT_URL" "BESMAN_ENV_NAME" "ASSESSMENT_TOOL_NAME" "ASSESSMENT_TOOL_TYPE" "ASSESSMENT_TOOL_VERSION" "ASSESSMENT_TOOL_PLAYBOOK" "BESMAN_ASSESSMENT_DATASTORE_DIR" "BESMAN_TOOL_PATH" "BESMAN_ASSESSMENT_DATASTORE_URL" "BESMAN_LAB_TYPE" "BESMAN_LAB_NAME" "BESMAN_RESULTS_PATH" "BESMAN_JUDGE_LLM_PROVIDER" "BESMAN_JUDGE_LLM_NAME" "BESMAN_JUDGE_LLM_VERSION")

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

    if [[ "$BESMAN_ARTIFACT_PROVIDER" == "HuggingFace" && -z "$BESMAN_MODEL_REPO_NAMESPACE" ]]; then
        __besman_echo_red "HuggingFace model repo namespace is not set"
        __besman_echo_no_colour ""
        __besman_echo_no_colour "Run the below command to set it"
        __besman_echo_no_colour ""
        __besman_echo_yellow "export BESMAN_MODEL_REPO_NAMESPACE=<namespace>"
        return 1
    elif [[ "$BESMAN_ARTIFACT_PROVIDER" == "Ollama" ]]; then
        if ! ollama ps | grep -q "$BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION" 
        then
            __besman_echo_red "Model $BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION is not running"
            __besman_echo_no_colour ""
            __besman_echo_no_colour "Run the below command to start it"
            __besman_echo_no_colour ""
            __besman_echo_yellow "   ollama run $BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION"
            return 1
        fi        
    fi

    if [[ "$BESMAN_JUDGE_LLM_PROVIDER" == "HuggingFace" && -z "$BESMAN_JUDGE_MODEL_REPO_NAMESPACE" ]] 
    then
        __besman_echo_error "Judge model repo namespace is not set"
        __besman_echo_no_colour ""
        __besman_echo_no_colour "Run the below command to set it"
        __besman_echo_no_colour ""
        __besman_echo_yellow "export BESMAN_JUDGE_MODEL_REPO_NAMESPACE=<namespace>"
        return 1
    elif [[ "$BESMAN_JUDGE_LLM_PROVIDER" == "AWSBedrock" && ( -z "$AWS_ACCESS_KEY_ID" || -z "$AWS_SECRET_ACCESS_KEY" )]] 
    then
        __besman_echo_error "Unauthenticated access to AWSBedrock"
        __besman_echo_no_colour "Set the AWS access keys by running the below command"
        __besman_echo_no_colour ""
        __besman_echo_yellow "      export AWS_ACCESS_KEY_ID=<value>"
        __besman_echo_yellow "      export AWS_SECRET_ACCESS_KEY=<value"
        __besman_echo_no_colour ""
        return 1
    elif [[ "$BESMAN_JUDGE_LLM_PROVIDER" == "Ollama" ]] 
    then
        if ! ollama ps | grep -q "$BESMAN_JUDGE_LLM_NAME:$BESMAN_JUDGE_LLM_VERSION" 
        then
            __besman_echo_red "Judge LLM $BESMAN_JUDGE_LLM_NAME:$BESMAN_JUDGE_LLM_VERSION is not running"
            __besman_echo_no_colour ""
            __besman_echo_no_colour "Run the below command to start it"
            __besman_echo_no_colour ""
            __besman_echo_yellow "   ollama run $BESMAN_JUDGE_LLM_NAME:$BESMAN_JUDGE_LLM_VERSION"
            return 1
        fi

    fi

    local dir_array=("BESMAN_ASSESSMENT_DATASTORE_DIR")
    for dir in "${dir_array[@]}"; do
        # Get the value of the variable with the name stored in $dir
        dir_path="${!dir}"

        if [[ ! -d $dir_path ]]; then
            __besman_echo_red "Could not find $dir_path"
            flag=true
        fi

    done

    # # [[ ! -f $BESMAN_TOOL_PATH/$ASSESSMENT_TOOL_NAME ]] && __besman_echo_red "Could not find artifact @ $BESMAN_TOOL_PATH/$ASSESSMENT_TOOL_NAME" && flag=true
    # if ! [ -x "$(command -v criticality_score)" ]; then
    #     __besman_echo_red "required tool - criticality_score is not installed. Please check the installed Bes env"
    # fi

    if [[ $flag == true ]]; then
        return 1
    else
        export INTERPRETER_TEST_REPORT_PATH="$BESMAN_ASSESSMENT_DATASTORE_DIR/models/$BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION/llm-benchmark"
        export DETAILED_REPORT_PATH="$INTERPRETER_TEST_REPORT_PATH/$BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION-interpreter-test-summary-report.json"
        mkdir -p "$INTERPRETER_TEST_REPORT_PATH"
        export OSAR_PATH="$BESMAN_ASSESSMENT_DATASTORE_DIR/models/$BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION/$BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION-osar.json"
        mkdir -p "$BESMAN_RESULTS_PATH"
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
    if [[ $CODE_INTERPRETER_RESULT == 1 ]]; then

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
    if [[ -f "$BESMAN_RESULTS_PATH/interpreter_judge_responses.json" ]]; then
        [[ -f "$INTERPRETER_TEST_REPORT_PATH/$BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION-interpreter-test-summary-report.json" ]] && rm "$INTERPRETER_TEST_REPORT_PATH/$BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION-interpreter-test-summary-report.json"
        [[ -f "$INTERPRETER_TEST_REPORT_PATH/$BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION-interpreter-test-detailed-report.json" ]] && rm "$INTERPRETER_TEST_REPORT_PATH/$BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION-interpreter-test-detailed-report.json"
        # Copy result to detailed report path
        mv "$BESMAN_RESULTS_PATH/interpreter_stat.json" "$INTERPRETER_TEST_REPORT_PATH/$BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION-interpreter-test-summary-report.json"
        mv "$BESMAN_RESULTS_PATH/interpreter_judge_responses.json" "$INTERPRETER_TEST_REPORT_PATH/$BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION-interpreter-test-detailed-report.json"

    fi

    __besman_generate_osar

}

function __besman_publish() {
    __besman_echo_yellow "Pushing to datastores"
    # push code to remote datastore
    cd "$BESMAN_ASSESSMENT_DATASTORE_DIR"

    git add "$DETAILED_REPORT_PATH" "$OSAR_PATH"
    git commit -m "Added osar and detailed report for PurpleLlama-CyberSecEval-LLMSecurityBenchmark-Code-Interpreter"
    git push origin main
}

function __besman_cleanup() {
    local var_array=("ASSESSMENT_TOOL_NAME" "ASSESSMENT_TOOL_TYPE" "ASSESSMENT_TOOL_PLAYBOOK" "ASSESSMENT_TOOL_VERSION" "OSAR_PATH" "INTERPRETER_TEST_REPORT_PATH" "DETAILED_REPORT_PATH")

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

