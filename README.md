# BeS Playbooks

A playbook in Be-Secure ecosystem refers to a set of instructions for completing a routine task. Not to be confused with an Ansible playbook. There can be automated(.sh), interactive(.ipynb) & manual(*.md) playbooks. It helps the security analyst who works in a BeSLab instance to carry out routine tasks in a consistent way. These playbooks are automated and are executed using the [BeSman](https://github.com/Be-Secure/BeSman) utility.

This repository stores all the playbooks crafted by members of the Be-Secure community.

## Playbook Types
Broadly Be-Secure playbooks classified into two types.

### 1. Playbook for a specific OSS project
- Playbook that automates the exploit test case for a known vulnerability (CVE) of this project. There could be 10 playbooks for 10 known CVE exploit cases for the project.
- Playbook to exploit a weakness (CWE) of a project
- Playbook to introduce an integrity violation, CIA tirad. application level playbook (may not be applicable for libraries like fastjson. Rather it may be applicable to applications like Drupal etc. Applicable for threat models like STRIDE). This may call the functional apis of the applicaiton.
- Playbook to patch a vulnerabilitiy (the vulnerabilitiy may have been patched manually the first time by a blue teamer. You are making it repeatbale for the other version of the project where the patch is not applied. This playbook will be created by the blue teamer who first patches it. This playbook is maintained till the community catches up with the same patch or till the organization decides to maintain the forked version of that project)

### 2. Playbook applicable for multiple projects
- Playbook that automates the exploit test case for a known vulnerability (CVE) that is affecting multiple projects
- Playbook that automates an assessment tool execution. Ex: Sonarqube playbook, oss-fuzz playbook, Fossology playbook, CodeQL playbook, OpenSSF Scorecard and Criticality Score playbook)
- Playbook for OSS Groking. This is to assess an OSS project in all angle including sbom, SLSA maturity, License compliance, execution for CLO monitor, VEX, STIX and TAXI etc. More information about the open sour cepojrect ncluding the build best practices)
- Playbook for Sigstore/DICE ID generation and JSON report submission.

### 3. Playbook for using an open source security tool
- Playbook to assist a security analyst in the operations of an open source security tool (ex: Playbook for OpenCTI for threat intelligence)

## Playbook Lifecycle
A typical BeS playbook consists of two files - the playbook lifecycle file and the steps file. Both files go into the "playbooks" directory in this repository. 

### Naming Conventions
- Lifecycle File => besman-\<purpose\>-\<version\>-playbook.sh
- Steps File     => besman-\<purpose\>-\<version\>-steps.sh/md/ipynb (The file extension depends on the execution type as automated(.sh), interactive(.ipynb) & manual(*.md))

### Lifecycle File Methods

- __besman_init()
- __besman_execute()
- __besman_prepare()
- __besman_publish()
- __besman_cleanup()
- __besman_launch()

### Lifecycle File Skeletal Code

    function __besman_init {
        # This function initializes everything necessary for executing the playbook as well as for publishing the reports.
    }
    
    function __besman_execute {
        # This function executes the steps file which contains the instructions for the activity. The steps file can be in various formats such as 'sh', '.ipynb', or '.md'.
    }
    
    function __besman_prepare {
        # Filters the data from the report to prepare for publishing.
    }
    
    function __besman_publish {
        # Publishes the reports to the datastore.
    }
    
    function __besman_cleanup {
        # Handles the cleanup tasks.
    }
    
    function __besman_launch {
        # Playbook launch function that gets called by BeSman utility. This function triggers the lifecycle methods of a playbook.
        __besman_init
        __besman_execute
        __besman_prepare
        __besman_publish
        __besman_cleanup
    }

## Developer guide

Thank you for your contribution. You can take a look at our [developer guide](./developer-guide.md) to start working on playbooks.

## Usage

### 1. Install BeSman

Install BeSman by following the instructions [here](https://github.com/Be-Secure/BeSman?tab=readme-ov-file#installation).

### 2. Install an environment

Installing an environments make sure you have the necessary tools installed to run the playbook as well as the source code and assessment datastore is made available in the user's machine

Get the list of environments by using

`$ bes list -env`

Install the environment by using

`$ bes install -env <enviornment name> -V <version>`

### 3. List the available playbooks

Run the below command to ge the list of available playbooks

`$ bes list -P`

If you wish to list/run playbooks from a different branch/tag,

`$ bes set BESMAN_PLAYBOOK_REPO_BRANCH <branch name/tag>`

### 4. Run the playbook

`$ bes run -P <playbook name> -V <version>`

## Report Issue
This project uses GitHub's integrated issue tracking system to record bugs and feature requests. If you want to raise an issue, please follow the recommendations below:

* Before you log a bug, please search the [issue tracker](https://github.com/Be-Secure/besecure-playbooks-store/issues) to see if someone has already reported the problem.
* If the issue doesn't already exist, [create a new issue](https://github.com/Be-Secure/besecure-playbooks-store/issues/new/choose).
* Please provide as much information as possible with the issue report.
We like to know the BeS-Schema version you're using.
* If possible, try to attach the screenshot of the issue.

## License
This proejct is an Open Source project released under the [Apache 2.0 license](https://www.apache.org/licenses/LICENSE-2.0.html).
