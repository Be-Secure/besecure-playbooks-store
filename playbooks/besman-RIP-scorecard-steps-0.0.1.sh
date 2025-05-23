#!/bin/bash

function __besman_get_workflow_id()
{
    local workflow_id
    workflow_id=$(curl --insecure -s -H "Authorization: token $BESMAN_GH_TOKEN" -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/$BESMAN_USER_NAMESPACE/$BESMAN_ARTIFACT_NAME/actions/workflows" | jq '.workflows[]  | select(.name == "Scorecard supply-chain security") | .id')
    echo "$workflow_id"
}

function __besman_get_workflow_runs()
{
    local workflow_id workflow_run_id
    workflow_id=$1

    workflow_run_id=$(curl --insecure -s -H "Authorization: token  $BESMAN_GH_TOKEN"      -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/$BESMAN_USER_NAMESPACE/$BESMAN_ARTIFACT_NAME/actions/workflows/$workflow_id/runs" | jq '.workflow_runs[0].id')

    echo "$workflow_run_id"
}

function __besman_get_job_id()
{
    local workflow_run_id job_id
    workflow_run_id=$1

    job_id=$(curl --insecure -s -H "Authorization: token $BESMAN_GH_TOKEN" -H "Accept: application/vnd.github.v3+json"      "https://api.github.com/repos/$BESMAN_USER_NAMESPACE/$BESMAN_ARTIFACT_NAME/actions/runs/$workflow_run_id/jobs" |  jq '.jobs[0].id')
    echo "$job_id"
}

function __besman_rerun_job()
{
    local workflow_run_id job_id workflow_id
    __besman_echo_yellow "Re-run workflow"
    workflow_id=$(__besman_get_workflow_id)
    workflow_run_id=$(__besman_get_workflow_runs "$workflow_id")
    job_id=$(__besman_get_job_id "$workflow_run_id")
    curl --insecure -L --silent  -X POST   -H "Accept: application/vnd.github+json"   -H "Authorization: Bearer $BESMAN_GH_TOKEN"   -H "X-GitHub-Api-Version: 2022-11-28"   https://api.github.com/repos/$BESMAN_USER_NAMESPACE/$BESMAN_ARTIFACT_NAME/actions/jobs/$job_id/rerun

}

function __besman_change_default_branch() {
    __besman_echo_yellow "Changing default branch"

    curl --insecure -X PATCH \
        -H "Authorization: token $BESMAN_GH_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        https://api.github.com/repos/"$BESMAN_USER_NAMESPACE"/"$BESMAN_ARTIFACT_NAME" \
        -d '{"default_branch": "'"$BESMAN_ARTIFACT_VERSION"_tavoss'"}' >> /dev/null
    # [[ "$?" != "0" ]] && __besman_echo_red "Something went wrong while changing default branch" && return 1
}

function __besman_write_workflow_file() {
    local workflow_file_path="$BESMAN_ARTIFACT_DIR/.github/workflows/scorecard.yml"
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

name: Scorecard supply-chain security
on:
  # For Branch-Protection check. Only the default branch is supported. See
  # https://github.com/ossf/scorecard/blob/main/docs/checks.md#branch-protection
  branch_protection_rule:
  # To guarantee Maintained check is occasionally updated. See
  # https://github.com/ossf/scorecard/blob/main/docs/checks.md#maintained
  push:
    branches: [ "${BESMAN_ARTIFACT_VERSION}_tavoss" ]

# Declare default permissions as read only.
permissions: read-all

jobs:
  analysis:
    name: Scorecard analysis
    runs-on: ubuntu-latest
    permissions:
      # Needed to upload the results to code-scanning dashboard.
      security-events: write
      # Needed to publish results and get a badge (see publish_results below).
      id-token: write
      # Uncomment the permissions below if installing in a private repository.
      # contents: read
      # actions: read

    steps:
      - name: "Checkout code"
        uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11 # v4.1.1
        with:
          persist-credentials: false

      - name: "Run analysis"
        uses: ossf/scorecard-action@0864cf19026789058feabb7e87baa5f140aac736 # v2.3.1
        with:
          results_file: results.sarif
          results_format: sarif
          # (Optional) "write" PAT token. Uncomment the \`repo_token\` line below if:
          # - you want to enable the Branch-Protection check on a *public* repository, or
          # - you are installing Scorecard on a *private* repository
          # To create the PAT, follow the steps in https://github.com/ossf/scorecard-action?tab=readme-ov-file#authentication-with-fine-grained-pat-optional.
          # repo_token: \${{ secrets.SCORECARD_TOKEN }}

          # Public repositories:
          #   - Publish results to OpenSSF REST API for easy access by consumers
          #   - Allows the repository to include the Scorecard badge.
          #   - See https://github.com/ossf/scorecard-action#publishing-results.
          # For private repositories:
          #   - \`publish_results\` will always be set to \`false\`, regardless
          #     of the value entered here.
          publish_results: true

      # Upload the results as artifacts (optional). Commenting out will disable uploads of run results in SARIF
      # format to the repository Actions tab.
      - name: "Upload artifact"
        uses: actions/upload-artifact@97a0fba1372883ab732affbe8f94b823f91727db # v3.pre.node20
        with:
          name: scorecard-sarif
          path: results.sarif
          retention-days: 5

      # Upload the results to GitHub's code scanning dashboard (optional).
      # Commenting out will disable upload of results to your repo's Code Scanning dashboard
      - name: "Upload to code-scanning"
        uses: github/codeql-action/upload-sarif@1b1aada464948af03b950897e5eb522f92603cc2 # v3.24.9
        with:
          sarif_file: results.sarif


EOF
        git add ".github/workflows/scorecard.yml"
        git commit -m "Added scorecard.yml"
        git push origin "$BESMAN_ARTIFACT_VERSION"_tavoss
    fi

    cd "$HOME"

    sleep 2

}

function __besman_status_url()
{
    local url=$1
    local status
    status=$(curl --insecure --silent -H  "Accept: application/vnd.github+json"   -H "Authorization: Bearer $BESMAN_GH_TOKEN"   -H "X-GitHub-Api-Version: 2022-11-28" "$url" | jq '.workflow_runs[0].status')

    echo "$status"
}

function __besman_get_workflow_status()
{
    local workflow_id=$1
    local status
    local url
    url="https://api.github.com/repos/$BESMAN_USER_NAMESPACE/$BESMAN_ARTIFACT_NAME/actions/workflows/$workflow_id/runs"
    # status=$(curl --insecure   -H "Accept: application/vnd.github+json"   -H "Authorization: Bearer $BESMAN_GH_TOKEN"   -H "X-GitHub-Api-Version: 2022-11-28"   https://api.github.com/repos/$BESMAN_USER_NAMESPACE/$BESMAN_ARTIFACT_NAME/actions/workflows/$workflow_id/runs | jq '.workflow_runs[0].status')

    start_time=$(date +%s)

    # Loop until a successful response is received or timeout occurs
    while true; do
        status=$(__besman_status_url "$url")
        if echo "$status" | grep -q "completed" 
        then
            __besman_echo_green "Workflow done"
            break
        else
            # Check if 15 minutes have passed
            current_time=$(date +%s)
            elapsed_time=$((current_time - start_time))
            if [ "$elapsed_time" -ge 300 ]; then
                __besman_echo_red "Exiting... Time limit exceeded"
                return 1
            fi
            __besman_echo_no_colour "Waiting for workflow to complete, status: $status"
            sleep 10 # Adjust the sleep duration as needed
        fi
    done

}

function __besman_get_conclusion()
{
    local workflow_id=$1
    local conclusion
    local url
    url="https://api.github.com/repos/$BESMAN_USER_NAMESPACE/$BESMAN_ARTIFACT_NAME/actions/workflows/$workflow_id/runs"

    conclusion=$(curl --insecure --silent -H "Accept: application/vnd.github+json"   -H "Authorization: Bearer $BESMAN_GH_TOKEN"   -H "X-GitHub-Api-Version: 2022-11-28" "$url" | jq '.workflow_runs[0].conclusion')

    echo "$conclusion"
}

function __besman_download_data() {
    local url 
    GLOBAL_RESPONSE_CODE=0
    url="$1"
    
    GLOBAL_RESPONSE_CODE=$(curl -s --insecure -X 'GET' \
    "$url" \
    -H 'accept: application/json' \
    -o "$DETAILED_REPORT_PATH" \
    -w "%{http_code}")
    
   # curl -s --insecure -X 'GET' \
   #     "$url" \
    #    -H 'accept: application/json' \
     #   -o "$DETAILED_REPORT_PATH" \
      #  -w "%{http_code}" \
       # -o /dev/null
}

function __besman_download_report() {
    
    
    local code_collab
    local response_code
    local start_time
    local current_time
    local elapsed_time
    local workflow_id
    local conclusion
    local url
    
    if [[ "$BESMAN_CODE_COLLAB_URL" == "https://github.com" ]]; then
        code_collab="github.com"
    else
        code_collab="gitlab.com"
    fi
    # Define the url
    
    url="https://api.securityscorecards.dev/projects/$code_collab/$BESMAN_USER_NAMESPACE/$BESMAN_ARTIFACT_NAME"

    workflow_id=$(__besman_get_workflow_id)
    __besman_get_workflow_status "$workflow_id"

    __besman_echo_yellow "Check workflow conclusion"
    conclusion=$(__besman_get_conclusion "$workflow_id")

    if ! echo "$conclusion" | grep -q "success" 
    then
        __besman_echo_red "Workflow failed"
        return 1
    fi
    # Record the start time
    start_time=$(date +%s)

    # Loop until a successful response is received or timeout occurs
    while true; do
        #response_code=$(__besman_download_data "$url")
        __besman_download_data "$url"
        __besman_echo_white "=====response-code====== $GLOBAL_RESPONSE_CODE================="
        if [ "$GLOBAL_RESPONSE_CODE" = "200" ]; then
            __besman_echo_green "Data downloaded successfully!"
            return 0
        else
            # Check if 15 minutes have passed
            current_time=$(date +%s)
            elapsed_time=$((current_time - start_time))
            if [ "$elapsed_time" -ge 900 ]; then
                __besman_echo_red "Exiting... Time limit exceeded"
                return 1
            fi
            __besman_echo_no_colour "Waiting for response..."
            sleep 5 # Adjust the sleep duration as needed
        fi
    done
}

function __besman_get_default_branch()
{
    local default_branch

    default_branch=$(curl --insecure -s -H "Authorization: token $BESMAN_GH_TOKEN" -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/$BESMAN_USER_NAMESPACE/$BESMAN_ARTIFACT_NAME" | jq -r '.default_branch')

    echo "$default_branch"
}

function __besman_execute_steps() {

    local default_branch


    if [[ -n "$BESMAN_SCORECARD_ASSESSMENT_MODE" && "$BESMAN_SCORECARD_ASSESSMENT_MODE" == "github-action" ]] 
    then
        __besman_echo_yellow "Running scorecard GitHub action"
        default_branch=$(__besman_get_default_branch)
        if [[ "$default_branch" != ""$BESMAN_ARTIFACT_VERSION"_tavoss" ]] 
        then
            __besman_echo_yellow "Changing default branch"
            cd "$BESMAN_ARTIFACT_DIR" || return 1

            git checkout -b "$BESMAN_ARTIFACT_VERSION"_tavoss "$BESMAN_ARTIFACT_VERSION"

            git push origin -u "$BESMAN_ARTIFACT_VERSION"_tavoss

            __besman_change_default_branch || return 1
        fi
        __besman_write_workflow_file

        __besman_download_report || return 1
        if [[ "$?" == "0" ]] 
        then
            export PLAYBOOK_EXECUTION_STATUS="success"
        else
            export PLAYBOOK_EXECUTION_STATUS="failure"
        fi
    elif [[ -z "$BESMAN_SCORECARD_ASSESSMENT_MODE" || "$BESMAN_SCORECARD_ASSESSMENT_MODE" == "cli" ]] 
    then
        __besman_echo_yellow "Running scorecard CLI"
        cd "$BESMAN_ARTIFACT_DIR" || return 1
        
        scorecard --repo "$BESMAN_ARTIFACT_ORIGIN_URL" --format json --output "$DETAILED_REPORT_PATH" 
        if [[ "$?" == "0" ]] 
        then
            export PLAYBOOK_EXECUTION_STATUS="success"
        else
            export PLAYBOOK_EXECUTION_STATUS="failure"
        fi
    fi

}

__besman_execute_steps
