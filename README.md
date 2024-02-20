# BeS Playbooks

A playbook in Be-Secure ecosystem refers to a set of instructions for completing a routine task. Not to be confused with an Ansible playbook. There can be  automated(.sh) , interactive (.ipynb) & manual(*.md) playbooks. It helps the security analyst who works in a BeSLab instance to carry out routine tasks in a consistent way. These playbooks are automated and are executed using the [BeSman](https://github.com/Be-Secure/BeSman) utility.

This repository stores all the playbooks crafted by members of the Be-Secure community.

### Playbook Types
Broadly Be-Secure playbooks classified into two types.

1. Playbook for a specific OSS project. Few instances listed below.
	- Playbook that automates the exploit test case for a known vulnerability (CVE) of this project. There could be 10 playbooks for 10 known CVE exploit cases for the project.
	- Playbook to exploit a weakness (CWE) of a project
	- Playbook to introduce an integrity violation, CIA tirad. application level playbook (may not be applicable for libraries
	like fastjson. Rather it may be applicable to applications like Drupal etc. Applicable for threat models
	like STRIDE). This may call the functional apis of the applicaiton.
	- Playbook to patch a vulnerabilitiy (the vulnerabilitiy may have been patched manually the first time by a blue teamer. You are making it repeatbale for the other version of the project where the patch is not applied. 
	This playbook will be created by the blue teamer who first patches it. This playbook is maintained till the community catches up with the same patch or till the organization decides to maintain the forked version of that project)
2. Playbook applicable for multiple projects. For instance vulnerabilities, some security operations that is tied to a tool etc. Detailed list below.
  - Playbook that automates the exploit test case for a known vulnerability (CVE) that is affecting multiple projects
  - Playbook that automates an assessment tool execution. Ex: Sonarqube playbook, oss-fuzz playbook, Fossology playbook, CodeQL playbook, OpenSSF Scorecard and Criticality Score playbook)
  - Playbook for OSS Groking. This is to assess an OSS project in all angle including sbom, SLSA maturity, License compliance, execution for CLO monitor, VEX, STIX and TAXI etc. More information about the open sour cepojrect ncluding the build best practices)
  - Playbook for Sigstore/DICE ID generation and JSON report submission.


### Playbook Lifecycle Functions
A typical BeS playbook comprises the following skeleton code:

    function __besman_init {
    # This function initializes everything necessary for executing the playbook as well as for publishing the reports.
    }
    
    function __besman_launch {
        # This function executes the steps file which contains the instructions for the activity. The steps file can be in various formats such as 'sh', '.ipynb', or '.md'.
    }
    
    function __besman_prep {
        # Filters the data from the report to prepare for publishing.
    }
    
    function __besman_publish {
        # Publishes the reports to the datastore.
    }
    
    function __besman_cleanup {
        # Handles the cleanup tasks.
    }
    
    function __besman_execute {
        # This function triggers all the other functions within this playbook.
        __besman_init
        __besman_launch
        __besman_publish
        __besman_cleanup
    }

## Report Issue
This project uses GitHub's integrated issue tracking system to record bugs and feature requests. If you want to raise an issue, please follow the recommendations below:

* Before you log a bug, please search the [issue tracker](https://github.com/Be-Secure/besecure-playbooks-store/issues) to see if someone has already reported the problem.
* If the issue doesn't already exist, [create a new issue](https://github.com/Be-Secure/besecure-playbooks-store/issues/new/choose).
* Please provide as much information as possible with the issue report.
We like to know the BeS-Schema version you're using.
* If possible, try to attach the screenshot of the issue.

## License
This proejct is an Open Source project released under the [Apache 2.0 license](https://www.apache.org/licenses/LICENSE-2.0.html).