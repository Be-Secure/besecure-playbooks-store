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

#### Understanding environments

Consider a project ABC, you are a security analyst who wants to perform assessments and find vulnerabilities in the project. You may also find some policy violations while performing assessments.

Now to perform the assessment, you 1) have to set up the project with all dependencies installed(in most cases), 2) install the tools for assessments and 3) perform the assessment. 

Now you can use an existing BeSman environment to install all the tools and dependencies of the project ABC as well as tools for asessments.

#### Understanding playbooks

Now after installing all the tools and dependencies of project ABC as well as tools for assessment, you need to perform the assessment. To do this you can use a BeSman playbook.


## Developing a playbook

### Setting up

1. Fork this repo to your namespace
2. Clone to local

        git clone https://github.com/Be-Secure/besecure-playbooks-store

3. Move into playbooks dir

        cd <path to besecure-playbooks-store>/playbooks

4. Create two new files 

    1. A lifecycle file - besman-<tool name>-<version>-playbook.sh
    2. A steps file - besman-<tool name>-<version>-steps.sh

