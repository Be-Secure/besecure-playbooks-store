# Developer Guide for Be-Secure Playbooks

This guide gives you instructions on how to develop a Be-Secure playbook.

## Repo Structure

```code
. ------------------------------------------------------------------- Root dir with repo related files.
├── checklist.md ---------------------------------------------------- Set of checklists that you should follow.
├── developer-guide.md ---------------------------------------------- This file
├── playbook-metadata.json ------------------------------------------ Contains metadata for playbooks present in this repo.
└── playbooks ------------------------------------------------------- This folder contains the playbooks.
    ├── besman-counterfit-0.0.1-playbook.sh ------------------------- Lifecycle file.
    ├── besman-counterfit-0.0.1-steps.ipynb ------------------------- Steps file.

```
## Things you should know

Here are some things you should know before you start working on an environment script.

### Be-Secure

Be-Secure is an open-source project ecosystem that is led by the Be-Secure Community. This community is transforming next generation Application security threat models and security assessment playbooks into global commons. Be-Secure is an ecosystem project for the open source security community. Among the tools included in the suite are open source security tools, sandbox environments for security assessments, as well as custom utilities written for the open source security community. Security assessment capabilities are provided by the platform through the aggregation of various open source security assessment services and utilities.

[Learn more](https://be-secure.github.io/Be-Secure/)

### BeSman

BeSman (pronounced as ‘B-e-S-man’) is a command-line utility designed for creating and provisioning customized security environments. It helps security professionals to reduce the turn around time for assessment of Open Source projects, AI Models, Model Datasets leaving them focus on the assessment task rather than setting up environment for it.

It also provides seamless support for creating and executing BeS playbooks, enabling users to automate complex workflows and tasks. With BeSman, users can efficiently manage and execute playbooks, streamlining their processes and enhancing productivity.

[Learn more](https://github.com/Be-Secure/BeSman)

### BeSman environments

A BeSman environment script is a script file that contains instructions for setting up and configuring the necessary tools, dependencies, and settings required for a specific software or project environment. It typically includes commands or directives to install/manage libraries, frameworks, databases, and other components needed to run the software or project successfully. Environment scripts automate the setup process, ensuring consistency and reproducibility across different environments or systems. They are commonly used in software development, testing, deployment, and other related tasks to streamline the environment setup and configuration

#### Types of environments

Here are the types of environments

- **Red Team environemnts(RT env)** - The env installs all the tools/utilities required for a security analyst to perform vulnerability assessment, create exploits etc.
- **Blue Team environment(BT env)** - The env would contain the instruction to install the tools required for a security professional to perform BT activities such as vulnerability remediation and patching.
- **Assessment environment** - The assessment environment is a common environment that is used to perform assessments on a wide range of projects.


[Learn more](./README.md)

### BeSman playbooks

A playbook in Be-Secure ecosystem refers to a set of instructions for completing a routine task. Not to be confused with an Ansible playbook. There can be automated(.sh), interactive(.ipynb) & manual(*.md) playbooks. It helps the security analyst who works in a BeSLab instance to carry out routine tasks in a consistent way. These playbooks are automated and are executed using the BeSman utility.

A playbook contain two files,

1. Lifecycle file - Contains the [lifecycle functions](./README.md#lifecycle-file-methods) of the playbook.
2. Steps file - Contains the actual steps of the assessment.

[Learn more](https://github.com/Be-Secure/besecure-playbooks-store)


### Order of Execution

You may face a challenge understanding the use of environments and playbooks. Lets understand this with an example.

Consider a project ABC, you are a security analyst who wants to perform assessments and find vulnerabilities in the project. You may also find some policy violations while performing assessments.

Now to perform the assessment, you 1) have to set up the project with all dependencies installed(in most cases), 2) install the tools for assessments and 3) perform the assessment. 

Now you can use an existing BeSman environment called `ABC-RT-env` to install all the tools and dependencies of the project ABC as well as tools for assessments.

Now after installing all the tools and dependencies of project ABC as well as tools for assessment, you need to perform the assessment. To do this you can use a BeSman playbook.


## Developing a playbook

1. Fork this repo to your namespace
2. Clone to local

        git clone https://github.com/<your github id>/besecure-playbooks-store

3. Move into playbooks dir

        cd <path to besecure-playbooks-store dir>/playbooks

4. Create two new files with the tool name

    1. A lifecycle file - `besman-<tool name>-<version>-playbook.sh`
    2. A steps file - `besman-<tool name>-<version>-steps.sh`

	`Note: The first version is usually 0.1.0 or 0.0.1`


## Explaining an assessment playbook

Let's take the example of criticality_score playbook under Be-Secure. As explained above, the criticality_score playbook also consists of two files, the [lifecycle file](https://github.com/Be-Secure/besecure-playbooks-store/blob/main/playbooks/besman-criticality_score-0.0.1-playbook.sh) and the [steps file](https://github.com/Be-Secure/besecure-playbooks-store/blob/main/playbooks/besman-criticality_score-0.0.1-steps.sh).

The job of the playbook file is to help the security analyst perform an assessment and generate two reports - the detailed report and the [Open Source Assessment Report (OSAR)](https://be-secure.github.io/bes-schema/assessment-report/).

### Functions of lifecycle file

#### __besman_init()

The init function is used to check and initialize all that is required for the tool to perform the assessment and generate the reports. You can do the following checks inside the function,

- check if the artifact dir is available.
- check if the assessment datastore dir is available.
- check if the tool is installed and is accessible.
- check if all the required variables are set.
- download the steps file from remote.
  
The following variables has to be exported in the `init` function,

- `ASSESSMENT_TOOL_NAME` - Name of the assessment tool
- `ASSESSMENT_TOOL_TYPE` - Type of tool(sast, sbom, license_compliance...)
- `ASSESSMENT_TOOL_VERSION` - Version of the assessment tool.
- `ASSESSMENT_TOOL_PLAYBOOK` - Name of the lifecycle file. Eg:- besman-criticality_score-0.0.1-playbook.sh.
- `DETAILED_REPORT_PATH` - Path to the detail report of the assessment.
- `OSAR_PATH` - Path to the OSAR file.
- `EXECUTION_TIMESTAMP` - The timestamp of execution.

You should check whether the following variables are empty or not.
```code
BESMAN_ARTIFACT_TYPE (Set by env config)

BESMAN_ARTIFACT_NAME (Set by env config)

BESMAN_ARTIFACT_VERSION (Set by env config)

BESMAN_ARTIFACT_URL (Set by env config)

BESMAN_ENV_NAME (Set by env config)

BESMAN_ARTIFACT_DIR (Set by env config)

ASSESSMENT_TOOL_NAME 

ASSESSMENT_TOOL_TYPE

ASSESSMENT_TOOL_VERSION

ASSESSMENT_TOOL_PLAYBOOK

BESMAN_ASSESSMENT_DATASTORE_DIR (Set by env config)

BESMAN_TOOL_PATH (Set by env config)

BESMAN_ASSESSMENT_DATASTORE_URL (Set by env config)

BESMAN_LAB_TYPE (Set by env config)

BESMAN_LAB_NAME (Set by env config)
```

It is important to note that the above variables are required you to create the OSAR. The developer can also check for other variables that are required to be set before the actual execution of tool.

Here is an example code snippet for the `init` function.

```code
function __besman_init() {
    __besman_echo_white "initialising"
    export ASSESSMENT_TOOL_NAME="criticality_score"
    export ASSESSMENT_TOOL_TYPE="criticality_score"
    export ASSESSMENT_TOOL_VERSION="2.0.3"
	EXECUTION_TIMESTAMP=$(date)
	export EXECUTION_TIMESTAMP
    export ASSESSMENT_TOOL_PLAYBOOK="besman-$ASSESSMENT_TOOL_NAME-0.0.1-playbook.sh"

    local steps_file_name="besman-$ASSESSMENT_TOOL_NAME-0.0.1-steps.sh"
    export BESMAN_STEPS_FILE_PATH="$BESMAN_PLAYBOOK_DIR/$steps_file_name"

    local var_array=("BESMAN_ARTIFACT_TYPE" "BESMAN_ARTIFACT_NAME" "BESMAN_ARTIFACT_VERSION" "BESMAN_ARTIFACT_URL" "BESMAN_ENV_NAME" "BESMAN_ARTIFACT_DIR" "ASSESSMENT_TOOL_NAME" "ASSESSMENT_TOOL_TYPE" "ASSESSMENT_TOOL_VERSION" "ASSESSMENT_TOOL_PLAYBOOK" "BESMAN_ASSESSMENT_DATASTORE_DIR" "BESMAN_TOOL_PATH" "BESMAN_ASSESSMENT_DATASTORE_URL" "BESMAN_LAB_TYPE" "BESMAN_LAB_NAME")

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

    local dir_array=("BESMAN_ASSESSMENT_DATASTORE_DIR")
    for dir in "${dir_array[@]}"; do
        # Get the value of the variable with the name stored in $dir
        dir_path="${!dir}"

        if [[ ! -d $dir_path ]]; then
            __besman_echo_red "Could not find $dir_path"
            flag=true
        fi

    done

    # [[ ! -f $BESMAN_TOOL_PATH/$ASSESSMENT_TOOL_NAME ]] && __besman_echo_red "Could not find artifact @ $BESMAN_TOOL_PATH/$ASSESSMENT_TOOL_NAME" && flag=true
    if ! [ -x "$(command -v criticality_score)" ]; then
        __besman_echo_red "required tool - criticality_score is not installed. Please check the installed Bes env"
    fi

    if [[ $flag == true ]]; then
        return 1
    else
        export CRITICALITY_SCORE_PATH="$BESMAN_ASSESSMENT_DATASTORE_DIR/$BESMAN_ARTIFACT_NAME/$BESMAN_ARTIFACT_VERSION/criticality_score"
        export DETAILED_REPORT_PATH="$CRITICALITY_SCORE_PATH/$BESMAN_ARTIFACT_NAME-$BESMAN_ARTIFACT_VERSION-criticality_score-report.json"
        mkdir -p "$CRITICALITY_SCORE_PATH"
        export OSAR_PATH="$BESMAN_ASSESSMENT_DATASTORE_DIR/$BESMAN_ARTIFACT_NAME/$BESMAN_ARTIFACT_VERSION/$BESMAN_ARTIFACT_NAME-$BESMAN_ARTIFACT_VERSION-osar.json"
        
        return 0

    fi
}
```

We do a `return 1` to exit from the functions when facing a error condition.

#### __besman_execute()

This is the function where we call the steps file to perform the assessment. 

There are three types of steps file,

##### 1. **Fully automated(.sh)**

This file will be a shell script and has to be executed using the dot(`.`) operator or the source command. Take the criticality_score example,

```code
local duration
__besman_echo_yellow "Launching steps file"

SECONDS=0
. "$BESMAN_STEPS_FILE_PATH"
duration=$SECONDS

export EXECUTION_DURATION=$duration
if [[ $CRITICALITY_SCORE_RESULT == 1 ]]; then

	export PLAYBOOK_EXECUTION_STATUS=failure
	return 1

else
	export PLAYBOOK_EXECUTION_STATUS=success
	return 0
fi

```

##### 2. **Semi automated(.ipynb)**

This will be a jupyter notebook with extension `.ipynb`. You need to open steps file using jupyter notebook command.

You can look at [this](https://github.com/Be-Secure/besecure-playbooks-store/blob/main/playbooks/besman-sonarqube-0.0.1-playbook.sh#L77) example. In here, the steps file is copied to a temporary dir to isolate the file, and then later removed during `cleanup` function. This is done because the jupyter command can only open a dir and not a single file.

You also need to export the vars `EXECUTION_DURATION` and `PLAYBOOK_EXECUTION_STATUS` like this,

```code
local duration
mkdir -p "$BESMAN_DIR/tmp/steps"
__besman_echo_yellow "Launching steps file"
cp "$BESMAN_STEPS_FILE_PATH" "$BESMAN_DIR/tmp/steps"
SECONDS=0
jupyter notebook "$BESMAN_DIR/tmp/steps"
duration=$SECONDS

export EXECUTION_DURATION=$duration
if [[ ! -f $DETAILED_REPORT_PATH ]]; then

	__besman_echo_red "Could not find detailed report @ $DETAILED_REPORT_PATH"
	export PLAYBOOK_EXECUTION_STATUS=failure
	return 1

else
	export PLAYBOOK_EXECUTION_STATUS=success
	return 0
fi
rm -rf "$BESMAN_DIR/tmp/steps"


```

The vars are later used for generating OSAR.

The var `CRITICALITY_SCORE_RESULT` is set inside the [steps file](https://github.com/Be-Secure/besecure-playbooks-store/blob/main/playbooks/besman-criticality_score-0.0.1-steps.sh) to store the result of the assessment and based on the value of this var, we are setting whether the execution was successful or not.

`Note: If the execution is not successful we are exiting the execution with some error messages. Ideally we should update the playbooks execution status in our datastore. But this is not implemented yet.`

##### 3. **Manual (.md | .ipynb)**

In this case the steps file will only contain textual information on performing assessments.

If the steps file is a markdown, you shouldm in the `execute()`, write the code to open the steps file as well as pause the playbook execution until the steps file is closed.

If the steps file is a jupyter notebook you should follow the instructions given in **Semi automated** steps file section.

The code to export the `EXECUTION_DURATION` will be same here.

```code
SECONDS=0
## Write code to open steps file
duration=$SECONDS
export EXECUTION_DURATION=$duration

```

#### __besman_prepare()

The `prepare()` function is where we prepare the detailed report path and generate OSAR. By preparing the detailed report path, we mean operations like moving the detailed report generated to the appropriate location or renaming it to our naming standard.

```code
function __besman_prepare() {
    __besman_echo_white "preparing data"
	# Write the code to move the data to appropriate location and rename it to the naming standard(if required).
    __besman_generate_osar
}
```

`__besman_generate_osar` is a function call to generate the OSAR. All the required data for generating the report is taken from the environment variables set in the `init()`, `execute()` and also from env config(during installation of environment).

#### __besman_publish()

The `publish()` function is used to push the detailed report and OSAR to the user's fork of the assessment datastore. The repo is cloned during the installation of the environment. We are also checking whether the datastore is available in the local in the `init()` using the var `BESMAN_ASSESSMENT_DATASTORE_DIR`.

Here is an example code,

```code
function __besman_publish() {
    __besman_echo_yellow "Pushing to datastores"
    # push code to remote datastore
    cd "$BESMAN_ASSESSMENT_DATASTORE_DIR"

    git add "$DETAILED_REPORT_PATH" "$OSAR_PATH"
    git commit -m "Added osar and detailed report"
    git push origin main
}
```

`Note: It is assumed that the reports should be in the main branch. If you wish to put the reports in a different branch, you should write the code for it`.

#### __besman_cleanup()

The `cleanup()` is used to remove any temporary files/directories/variables created using the playbook exeuction.

For example, in the below code, we are unsetting the variables set during the playbook execution,

```code
function __besman_cleanup() {
    local var_array=("ASSESSMENT_TOOL_NAME" "ASSESSMENT_TOOL_TYPE" "ASSESSMENT_TOOL_PLAYBOOK" "ASSESSMENT_TOOL_VERSION" "OSAR_PATH" "CRITICALITY_SCORE_PATH" "DETAILED_REPORT_PATH")

    for var in "${var_array[@]}"; do
        if [[ -v $var ]]; then
            unset "$var"
        fi

    done

}
```

#### __besman_launch()

The `launch` function is similar to the main() function. This is were the playbook execution is started. The launch function calls all the other functions and handle returns from them.

The `launch()` function is called from the `run` command is besman.

An example for launch function,

```code
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

```

Here we are using a `flag` var. This var stores the return values from each function. If the return value is `1` (Error), the `cleanup` function is called and the execution is stopped.


## Steps file

As said in the above, the steps file is where we write the actual steps of assessment. There can be three types of steps file - Automated(.sh), Semi automated(.ipynb) and Manual(.ipynb|.md)

Here is an example of the steps file code for criticality_score.

```code
echo "Running $ASSESSMENT_TOOL_NAME"
cd "$BESMAN_TOOL_PATH" || return 1
criticality_score -depsdev-disable -format json $BESMAN_ARTIFACT_URL | grep -o '{"default_score":.*}' > "$DETAILED_REPORT_PATH" 2>&1
if [[ "$?" != "0" ]]; then
    export CRITICALITY_SCORE_RESULT=1
else
    export CRITICALITY_SCORE_RESULT=0
fi
```

## Push and Pr

Commit the file and push it into your remote repo. After that you can raise a pr to the develop branch of [besecure-playbooks-store](https://github.com/Be-Secure/besecure-playbooks-store/tree/develop).