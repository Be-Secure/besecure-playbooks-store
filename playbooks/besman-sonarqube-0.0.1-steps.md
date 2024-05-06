
## To Perform Sonar Scanning, make sure SonarQube is up and ready in your Docker host.

### Below are the steps to achieve it:

1. Check if Docker is installed on your System using below command . 
    `docker --version`
you should find the Docker information. If there is no info. you can refer the Documentation to install in on your pc https://docs.docker.com/get-docker/
2. Now that you have Docker in place, you can check if sonar container is running or not. Hit Below command .
`docker ps | grep sonarqube`
you can get the Container info if it is running else hit the below command:
```docker run -d --name sonarqube -p 9000:9000 sonarqube```

>This command will pull the SonarQube Docker image and run it as a container named "sonarqube" on port 9000.

3. Now Create a Token for further use:
- ###### From the UI:
    - Launch/Login to SonarQube
    - Open your web browser and navigate to http://localhost:9000. You can login with the default credentials:
    Username: admin
    Password: admin
    - Navigate to http://localhost:9000/account/security/ after logging in.
    - Click on "Generate Tokens".
    - Provide a name for your token and click "Generate".
    - Copy the generated token. Make sure to save it securely as you won't be able to see it again.
- ###### Using Curl :
    ```
    export SONARQUBE_URL="http://localhost:9000" && \
    export USERNAME="admin" && \
    export PASSWORD="admin" && \
    API_ENDPOINT="${SONARQUBE_URL}/api/user_tokens/generate" && \

    TOKEN=curl -u "${USERNAME}:${PASSWORD}" -X POST "${API_ENDPOINT}" -d "name=automation_token" | jq -r '.token' && \
    echo "${TOKEN}"
    ```
4. Create a Project using above created token:
- ###### using curl :
``` 
export YOUR_PROJECT_KEY="<your Project key here>" && \
export YOUR_PROJECT_NAME="<your Project Name here>" && \
export TOKEN="<Your Token created in above step>" && \
API_ENDPOINT="http://localhost:9000/api/projects/create"

curl -u "${TOKEN}": -X POST "${API_ENDPOINT}" \
  -d "project=${YOUR_PROJECT_KEY}" \
  -d "name=${YOUR_PROJECT_NAME}" 
  ```
5. Performing Sonar Scanning for a project.
- Make sure you have sonar-Scanner-CLI installed or you can install it by following  URL : https://docs.sonarsource.com/sonarqube/latest/analyzing-source-code/scanners/sonarscanner/

- Navigate to your project directory and run the scanner command:
```
sonar-scanner \
-Dsonar.projectKey=${YOUR_PROJECT_KEY} \
-Dsonar.sources=.
```
6. Sending the Result to SonarQube:
- After running the above step, it will automatically send the analysis results to the SonarQube server you configured. You can view the results in the SonarQube web interface.

7. Downloading the Report to a Specific Folder in Your PC:

- ###### From UI
    - In SonarQube, navigate to the project for which you want to download the report.
    - Click on "Measures" or "Quality Gate" to view the analysis results.
    - You may find options to export or download the report. Typically, there will be an option to download the report as a PDF or CSV.
    - Choose the desired format and save the report to a specific folder on your PC.
    
- ###### Using curl:

    ``` 
    API_ENDPOINT="http://localhost:9000/api/measures/component"

    export TOKEN="your_authentication_token"


    export PROJECT_KEY="your_project_key"

    export PARAMS="component=${PROJECT_KEY}&metricKeys=coverage,bugs,vulnerabilities"

    curl -u "${TOKEN}": ${API_ENDPOINT}?${PARAMS} --output "provide the Path to Data store directory as mentioned in the below" 
    ```
