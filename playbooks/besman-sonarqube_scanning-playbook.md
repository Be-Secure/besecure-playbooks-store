1. Execute the below command as a Non-root user :
    /opt/sonarqube/bin/[OS]/sonar.sh console

2. Once your instance is up and running, Log in to http://localhost:9000 from any Web Browser

3. System Administrator credentials
    login: admin 
    password: admin

4. Now that you're logged in to your local SonarQube instance

5. Analyze the Project :
    - Click the Create new project button.
    - Give your project a Project key and a Display name as Fastjson and click the Set Up button.
    - Under Provide a token, select Generate a token. Give your token a name, click the Generate button, and click Continue.
    - Select your main language as Maven(Java), Run analysis on your project, and follow the instructions to analyze your project.
    - Here you'll download and execute a Scanner on your code (if you're using Maven or Gradle, the Scanner is automatically downloaded).
