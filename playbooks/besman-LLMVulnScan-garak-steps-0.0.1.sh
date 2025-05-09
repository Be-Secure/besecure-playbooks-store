#!/bin/bash

source /opt/conda/etc/profile.d/conda.sh
[[ $? -ne 0 ]] && { echo "Failed to source conda.sh"; return 1; }

conda activate garak
[[ $? -ne 0 ]] && { echo "Failed to activate conda environment"; return 1; }

if [[ "$BESMAN_ARTIFACT_PROVIDER" == "Ollama" ]] 
then
    garak --model_type ollama --model_name "$BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION" --probes "$BESMAN_GARAK_PROBES" --report_prefix "$GARAK_TEST_REPORT_PATH/$BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION-garak-test-detailed"
elif [[ "$BESMAN_ARTIFACT_PROVIDER" == "HuggingFace" ]]
then
    garak --model_type huggingface --model_name "$BESMAN_MODEL_REPO_NAMESPACE/$BESMAN_ARTIFACT_NAME-$BESMAN_ARTIFACT_VERSION" --probes "$BESMAN_GARAK_PROBES" --report_prefix "$GARAK_TEST_REPORT_PATH/$BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION-garak-test-detailed"
fi

if [[ -f "$GARAK_TEST_REPORT_PATH/$BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION-garak-test-detailed.report.jsonl" ]] 
then
    jq -n '
    reduce inputs as $i ({}; 
        if $i.entry_type == "eval" then
        .[$i.probe | split(".")[0]] |= (. // {}) 
        | .[$i.probe | split(".")[0]][($i.detector | split(".")[-1])] = $i
        else
        .
        end
    )
    ' "$GARAK_TEST_REPORT_PATH/$BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION-garak-test-detailed.report.jsonl" > "$DETAILED_REPORT_PATH"
    export GARAK_RESULT=0
else
    __besman_echo_red "Garak report not found at $GARAK_TEST_REPORT_PATH/$BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION-garak-test-detailed.report.jsonl"
    export GARAK_RESULT=1
    return 1
fi

conda deactivate

