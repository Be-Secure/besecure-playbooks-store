#!/bin/bash

# The data for this json should be made available by prep function

# {
#     "schema_version": "0.1.0",
# Asset info can come from environment scripts. 
#     "asset": {
#         "type": string, - BESMAN_OSS_TYPE
#         "name": string, - BESMAN_OSSP_NAME
#         "version": string, - BESMAN_OSSP_VERSION
#         "url": string, - BESMAN_OSSP_URL
#         "environment": string - BESMAN_ENV_NAME
#     },
#     "assessments": [
#         {
    # Tool info can come from playbook
#             "tool": {
#                 "name": string, - BESLAB_ASSESSMENT_TOOL
#                 "type": string, - BESLAB_ASSESSMENT_TYPE
#                 "version": string, - BESLAB_TOOL_VERSION
#                 "playbook": string - BESMAN_PLAYBOOK_NAME
#             },
    # Execution info can come from both beslab and playbook
#             "execution": {
#                 "type": string, -  BESLAB_OWNER_TYPE
#                 "id": string, - BESLAB_OWNER_ID
#                 "status": string, - BESMAN_PLAYBOOK_STATUS
#                 "timestamp": timestamp, can come from besman 
#                 "duration": string, can come from besman
#                 "output_path": string BESLAB_ASSESSMENT_DATASTORE_URL
#             },
# The results data should be fetched from the detailed report. 
#             "results": [
#                 {
#                     "feature": string,
#                     "aspect": string,
#                     "attribute": string,
#                     "value": number
#                 }
#             ]
#         }
#     ]
# }

function __besman_init()
{
    # All the required environment variables should be set by BeSman environment scripts or BeSLab.

    local var_array=("BESMAN_OSSP_NAME" "BESMAN_OSSP_DIR" "BESMAN_OSSP_VERSION" "BESLAB_ASSESSMENT_DATASTORE_DIR" "BESLAB_ASSESSMENT_SUMMARY_DATASTORE_DIR" "BESLAB_ARTIFACT_PATH" "BESLAB_REPORT_FORMAT" "BESLAB_SBOM_TOOL" "BESLAB_ASSESSMENT_DATASTORE_URL" "BESLAB_ASSESSMENT_SUMMARY_DATASTORE_URL")

    local flag=false
    for var in "${var_array[@]}";
    do
        if [[ ! -v $var ]] 
        then

            echo "$var is not set"
            flag=true
        fi

    done
    

    local dir_array=("BESLAB_ASSESSMENT_DATASTORE_DIR" "BESLAB_ASSESSMENT_SUMMARY_DATASTORE_DIR")

    for dir in "${dir_array[@]}";
    do
        # Get the value of the variable with the name stored in $dir
        dir_path="${!dir}"

        if [[ ! -d $dir_path ]] 
        then
    
            echo "Could not find $dir_path"
    
            flag=true
    
        fi
    
    done

    [[ ! -f $BESLAB_ARTIFACT_PATH/$BESLAB_SBOM_TOOL ]] && echo "Could not find artifact @ $BESLAB_ARTIFACT_PATH/$BESLAB_SBOM_TOOL" && flag=true

    if [[ $flag == true ]] 
    then
    
        return 1
    
    else
        export SBOM_PATH="$BESLAB_ASSESSMENT_DATASTORE_DIR/$BESMAN_OSSP_NAME/$BESMAN_OSSP_VERSION/sbom"
        export DETAILED_REPORT_PATH="$SBOM_PATH/$BESMAN_OSSP_NAME-$BESMAN_OSSP_VERSION-sbom.$BESLAB_REPORT_FORMAT"
        mkdir -p "$SBOM_PATH"
        return 0
    
    fi

}

function __besman_launch()
{

    echo "Launching steps file"

    source besman-sbom-0.0.1-steps.sh
    if [[ $? == 0 ]] 
    then
        
        return 0
    
    else

        return 1
    fi
    
}

function __besman_prepare()
{

    mv "$SBOM_PATH"/bom-*.json "$DETAILED_REPORT_PATH"
    
}

function __besman_publish()
{
    # push code to remote datastore
    
}

function __besman_cleanup()
{
    echo "1"
    
}

function __besman_execute()
{
    local flag=1
    
    __besman_init
    flag=$?
    echo "flag=$flag"
    if [[ $flag == 0 ]] 
    then
    
    __besman_launch
    flag=$?
    
    else

    __besman_cleanup
    return
    fi

    if [[ $flag == 0 ]] 
    then
    
    __besman_prepare
    __besman_publish
    __besman_cleanup
    
    else

    __besman_cleanup
    return


    fi
}



