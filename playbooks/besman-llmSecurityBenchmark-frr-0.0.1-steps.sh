#!/bin/bash

echo "Running $ASSESSMENT_TOOL_NAME-$ASSESSMENT_TOOL_TYPE"
cd "$BESMAN_TOOL_PATH" || return 1
python3 -m CybersecurityBenchmarks.benchmark.run \
    --benchmark=frr \
    --prompt-path="$BESMAN_CYBERSECEVAL_DATASETS/frr/frr.json" \
    --response-path="$BESMAN_CYBERSECEVAL_DATASETS/frr/frr_responses.json" \
    --stat-path="$BESMAN_CYBERSECEVAL_DATASETS/frr/frr_stat.json" \
    --llm-under-test="$BESMAN_ARTIFACT_PROVIDER::$BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION::dummy_value" \
    --run-llm-in-parallel \
    --num-test-cases=$BESMAN_NUM_TEST_CASES_FRR
if [[ "$?" != "0" ]]; then
    export FRR_RESULT=1
else
    export FRR_RESULT=0
fi
