1. Create a workflow file:
    - Go to the github website of the project and fork it into the desired namespace.
    - Click on the actions tab and click on create new workflow.
    - Search for OSSF Scorecard and click on configure.
    - A new workflow file called scorecard.yml will be created.

2. Commit the workflow file
    - Click on commit changes to commit the scorecard.yml file to the repository.

3. Check the status of scorecard actions
    - Click on the actions tab and select Scorecard supply-chain security from the workflows list
    - If the status of the workflow run is successful, run the playbook to download the scorecard report

4. Close the file to continue with the rest of the script