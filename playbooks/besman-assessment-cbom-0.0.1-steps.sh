#!/bin/bash

function __besman_get_default_branch() {
    local default_branch

    default_branch=$(curl --insecure -s -H "Authorization: token $BESMAN_GH_TOKEN" -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/$BESMAN_USER_NAMESPACE/$BESMAN_ARTIFACT_NAME" | jq -r '.default_branch')

    echo "$default_branch"
}

function __besman_change_default_branch() {
    __besman_echo_yellow "Changing default branch"

    curl --insecure -X PATCH \
        -H "Authorization: token $BESMAN_GH_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        https://api.github.com/repos/"$BESMAN_USER_NAMESPACE"/"$BESMAN_ARTIFACT_NAME" \
        -d '{"default_branch": "'"$BESMAN_ARTIFACT_VERSION"_tavoss'"}' >>/dev/null
    # [[ "$?" != "0" ]] && __besman_echo_red "Something went wrong while changing default branch" && return 1
}

function __besman_write_workflow_file() {
    local workflow_file_path="$BESMAN_ARTIFACT_DIR/.github/workflows/cbom.yml"
    cd "$BESMAN_ARTIFACT_DIR"
    mkdir -p "$BESMAN_ARTIFACT_DIR/.github/workflows"
    if [[ -f "$workflow_file_path" ]]; then
        __besman_echo_yellow "Workflow file available"
        # __besman_rerun_job || return 1
    else
        __besman_echo_yellow "Creating workflow file"

        touch "$workflow_file_path"
        cat <<EOF >"$workflow_file_path"
# This workflow uses actions that are not certified by GitHub. They are provided
# by a third-party and are governed by separate terms of service, privacy
# policy, and support documentation.

name: cbom
on:
 
  branch_protection_rule:
  push:
    branches: [ "${BESMAN_ARTIFACT_VERSION}_tavoss" ]
  workflow_dispatch:

# Declare default permissions as read only.
permissions: read-all

jobs:
  cbom-scan:
    runs-on: ubuntu-latest
    name: CBOM generation
    permissions:
      contents: write
      pull-requests: write
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          ref: "${BESMAN_ARTIFACT_VERSION}_tavoss" # Ensure the correct branch is checked out

      - name: Create CBOM
        uses: PQCA/cbomkit-action@v1.1.0
        id: cbom
        continue-on-error: true

      - name: Create and publish CBOM artifact
        uses: actions/upload-artifact@v4
        with:
          name: "CBOM"
          path: cbom.json

EOF
        git add ".github/workflows/cbom.yml"
        git commit -m "Added cbom.yml workflow"
        git push origin "$BESMAN_ARTIFACT_VERSION"_tavoss
    fi

    cd "$HOME"

    sleep 2

}

__besman_download_report() {
    local GITHUB_TOKEN="$BESMAN_GH_TOKEN"
    local REPO_OWNER="$BESMAN_USER_NAMESPACE"
    local REPO_NAME="$BESMAN_ARTIFACT_NAME"
    local WORKFLOW_NAME="cbom.yml"
    local ARTIFACT_NAME="CBOM"
    local DOWNLOAD_DIR="$CBOM_PATH"
    local ARTIFACT_VERSION="$BESMAN_ARTIFACT_VERSION"

    # 1. Get the run ID
    local RUN_ID=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
        "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/actions/runs?workflow_filename=$WORKFLOW_NAME" |
        jq -r '.workflow_runs[0].id')

    if [ -z "$RUN_ID" ]; then
        __besman_echo_red "Error: Failed to get workflow run ID."
        return 1
    fi

    __besman_echo_green "Workflow Run ID: $RUN_ID"

    # 2. Loop to check the run's conclusion/status
    local RUN_STATUS=""
    local attempt=0
    local max_attempts=30 # Adjust as needed (30 attempts * 30 seconds = 5 minutes)

    while [ "$RUN_STATUS" != "success" ] && [ "$attempt" -lt "$max_attempts" ]; do
        RUN_STATUS=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
            "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/actions/runs/$RUN_ID" |
            jq -r '.conclusion')

        if [ -z "$RUN_STATUS" ]; then
            __besman_echo_red "Error: Failed to get workflow run status."
            return 1
        fi

        if [ "$RUN_STATUS" == "success" ]; then
            __besman_echo_green "Workflow Run Status: Success"
            break # Exit loop if successful
        elif [ "$RUN_STATUS" == "failure" ] || [ "$RUN_STATUS" == "cancelled" ] || [ "$RUN_STATUS" == "timed_out" ]; then
            __besman_echo_red "Workflow run failed. Status: $RUN_STATUS"
            return 1
        else
            attempt=$((attempt + 1))
            __besman_echo_green "Workflow run in progress. Attempt $attempt. Status: $RUN_STATUS. Waiting 10 seconds..."
            sleep 90
        fi
    done

    if [ "$RUN_STATUS" != "success" ]; then
        __besman_echo_red "Workflow run did not succeed after $max_attempts attempts. Exiting."
        return 1
    fi

    # 3. Get the artifact ID
    local ARTIFACT_ID=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
        "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/actions/runs/$RUN_ID/artifacts" |
        jq -r ".artifacts[] | select(.name == \"$ARTIFACT_NAME\") | .id")

    if [ -z "$ARTIFACT_ID" ]; then
        __besman_echo_red "Error: Artifact '$ARTIFACT_NAME' not found in run ID $RUN_ID."
        return 1
    fi

    __besman_echo_green "Artifact ID: $ARTIFACT_ID"

    # 4. Download the artifact
   # mkdir -p "$DOWNLOAD_DIR"

    curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        -L "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/actions/artifacts/$ARTIFACT_ID/zip" \
        -o "$DOWNLOAD_DIR/$ARTIFACT_NAME-$ARTIFACT_VERSION-cbom.zip"

    if [ $? -eq 0 ]; then
        __besman_echo_green "Artifact '$ARTIFACT_NAME' downloaded to $DOWNLOAD_DIR/$ARTIFACT_NAME-$ARTIFACT_VERSION-cbom.zip"
        unzip "$DOWNLOAD_DIR/$ARTIFACT_NAME-$ARTIFACT_VERSION-cbom.zip" -d "$DOWNLOAD_DIR/$ARTIFACT_NAME-$ARTIFACT_VERSION-cbom-report.json"
    else
        __besman_echo_red "Error: Failed to download artifact."
        return 1
    fi
}

function __besman_execute_steps() {

    local default_branch
    default_branch=$(__besman_get_default_branch)
    if [[ "$default_branch" != ""$BESMAN_ARTIFACT_VERSION"_tavoss" ]]; then
        __besman_echo_yellow "Changing default branch"
        cd "$BESMAN_ARTIFACT_DIR" || return 1

        git checkout -b "$BESMAN_ARTIFACT_VERSION"_tavoss "$BESMAN_ARTIFACT_VERSION"

        git push origin -u "$BESMAN_ARTIFACT_VERSION"_tavoss

        __besman_change_default_branch || return 1
    fi

    __besman_write_workflow_file

    __besman_download_report || return 1

    if [[ "$?" == "0" ]]; then
        export PLAYBOOK_EXECUTION_STATUS="success"
    else
        export PLAYBOOK_EXECUTION_STATUS="failure"
    fi

}

__besman_execute_steps
