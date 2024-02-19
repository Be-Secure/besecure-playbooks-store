#!/bin/bash

function __besman_init_sbom()
{
    # export OSSP_NAME="fastjson"
    # export OSSP_VERSION="1.2.24"
    # export DETAILED_REPORT_PATH=$HOME/besecure-assessment-datastore/
    # export ASSESSMENT_SUMMARY_PATH=$HOME/besecure-OSAR-store/

    # All the required environment variables should be set by BeSman.

    local var_array=("OSSP_NAME" "OSSP_VERSION" "ASSESSMENT_DATASTORE" "ASSESSMENT_SUMMARY_DATASTORE" "ARTIFACT_PATH" "OSSP_DIR" "REPORT_FORMAT")
    local flag=false

    for var in "${var_array[@]}";
    do
        
        if [[ -z "$var" ]] 
        then
            echo "$var is not set"
            flag=true
        fi

    done
    

    local dir_array=("ASSESSMENT_DATASTORE" "ASSESSMENT_SUMMARY_DATASTORE")

    for dir in "${dir_array[@]}";
    do
    
        if [[ ! -d "$dir" ]] 
        then
    
            echo "Could not find $dir"
    
            flag=true
    
        fi
    
    done

    [[ -f "$ARTIFACT_PATH" ]] && echo "Could not find artifact @ $ARTIFACT_PATH" && flag=true

    if [[ $flag == true ]] 
    then
    
        return 1
    
    else
        export SBOM_PATH="$ASSESSMENT_DATASTORE/$OSSP_NAME/$OSSP_VERSION/sbom/"
        export DETAILED_REPORT_PATH="$SBOM_PATH/$OSSP_NAME-$OSSP_VERSION-sbom.$REPORT_FORMAT"
        mkdir -p "$SBOM_PATH"
        return 0
    
    fi

}

function __besman_launch_sbom()
{

    cd "$ARTIFACT_PATH" || return 1
    ./besman-sbom-0.0.1-steps.sh
    if [[ $? == 0 ]] 
    then
        
        return 0
    
    else

        return 1
    fi
    
}

function __besman_prepare_sbom()
{
    mv "$SBOM_PATH"/bom-*.json "$DETAILED_REPORT_PATH"
    
}

function __besman_publish_sbom()
{
    echo "1"
    
}

function __besman_cleanup_sbom()
{
    echo "1"
    
}

function __besman_execute_sbom()
{
    local flag=1
    
    __besman_init_sbom
    flag=$?
    
    if [[ $flag == 0 ]] 
    then
    
    __besman_launch_sbom
    flag=$?
    
    else

    __besman_cleanup_sbom

    fi

    if [[ $flag == 0 ]] 
    then
    
    __besman_prepare_sbom
    __besman_publish_sbom
    
    else

    __besman_cleanup_sbom

    fi
}

