
This repository contains playbooks crafted by members of the Be-Secure community.

The Be-Secure playbooks serve the purpose of conducting either security assessment activities or exploit simulations. 
These playbooks are automated and are executed using the [BeSman](https://github.com/Be-Secure/BeSman) utility.

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

