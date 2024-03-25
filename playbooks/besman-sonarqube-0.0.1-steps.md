1. Open the below url.

        http://localhost:9000/
        
    
    If the page is not up, make sure the docker container is running.

        docker run -d --name sonarqube -p 9000:9000 -p 9092:9092 sonarqube

2. First time users should use the default login/password: admin/admin.
3. Once you login, you will be asked to set a new password.
4. Once you login, click create a local project
5. 
