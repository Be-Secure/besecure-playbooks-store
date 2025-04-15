#!/bin/bash


function __besman_change_default_branch() {
    __besman_echo_yellow "Changing default branch"

    curl --insecure -X PATCH \
        -H "Authorization: token $BESMAN_GH_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        https://api.github.com/repos/"$BESMAN_USER_NAMESPACE"/"$BESMAN_ARTIFACT_NAME" \
        -d '{"default_branch": "'"$BESMAN_ARTIFACT_VERSION"_tavoss'"}' >> /dev/null
    # [[ "$?" != "0" ]] && __besman_echo_red "Something went wrong while changing default branch" && return 1
}


function __besman_download_report() {
     # code to download or copy the reports generated if needed.
    echo ""
    return 0
}

function __besman_get_default_branch()
{
    local default_branch

    default_branch=$(curl --insecure -s -H "Authorization: token $BESMAN_GH_TOKEN" -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/$BESMAN_USER_NAMESPACE/$BESMAN_ARTIFACT_NAME" | jq -r '.default_branch')

    echo "$default_branch"
}

function __besman_steps () {

    # Execute the steps to run the tool and get the reports generated.
    # wite a sub-function and call it here.
    # Write another sub-function to download or capture the reports.
    echo ""
    return 0

}

function __besman_execute_steps() {

    local default_branch
    default_branch=$(__besman_get_default_branch)
    if [[ "$default_branch" != ""$BESMAN_ARTIFACT_VERSION"_tavoss" ]] 
    then
        __besman_echo_yellow "Changing default branch"
        cd "$BESMAN_ARTIFACT_DIR" || return 1

        git checkout -b "$BESMAN_ARTIFACT_VERSION"_tavoss "$BESMAN_ARTIFACT_VERSION"

        git push origin -u "$BESMAN_ARTIFACT_VERSION"_tavoss

        __besman_change_default_branch || return 1
    fi

    __besman_steps

    __besman_download_report || return 1

    if [[ "$?" == "0" ]] 
    then
        export PLAYBOOK_EXECUTION_STATUS="success"
    else
        export PLAYBOOK_EXECUTION_STATUS="failure"
    fi

}

__besman_execute_steps
