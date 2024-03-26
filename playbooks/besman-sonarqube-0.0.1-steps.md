# Login

1. Go to url - http://localhost:9000
2. For the first login, provide login/password as admin/admin.
3. You will be asked to update your password.

# Create a project

1. Create a project by selecting "Create a local project"
2. Fill in the details by providing your project name and default branch and click next
3. Select "use global setting" as the project's baseline.
4. Select "create project"

# Project analysis

1. Once you create the project, you can choose the analysis method.
2.  If you choose locally,
   1.  Click "Generate" to generate a token.
   2.  Save the token.
   3.  Click "continue"
   4.  Select the appropriate build option for your project.
   5.  Copy the command displayed and run in your project's directory.
   6.  Once the execution is done, the browser page will be automatically reloaded and display the weaknesses found.

# Downloading reports

1. Download the code smells, bugs and hotspots report from 
        
    http://localhost:9000/api/issues/search?componentKeys=<project name>

2. Convert the report to json and save it in a temp file.
3. Download the vulnerability report separately from
   
    http://localhost:9000/api/issues/search?componentKeys=<project name>&types=VULNERABILITY

4.  Copy the data from the issues field of the vulnerability and append it to the issues field of the report saved in the temp file. 
    
5. Run the below command to move the file to the assessment datastore.

        mv <temp file>.json "$SONARQUBE_PATH/"$BESMAN_ARTIFACT_NAME-$BESMAN_ARTIFACT_VERSION-$ASSESSMENT_TOOL_NAME-report.json"


# Finishing up

Once all the above steps are down, you can close the editor