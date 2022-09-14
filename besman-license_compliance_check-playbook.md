## Playbook for license compliance check using fossology

1. Make sure docker is installed using the below command.

    `$ docker --version`
    
2. Run the below command to pull and bring up the docker image of fossology.

    `$ docker run -p 8081:80 fossology/fossology`

3. Open the below url in your browser.

    `http://http://172.17.0.1:8081/repo`

4. Login using the default username `fossy` and password `fossy`.

5. Follow the instructions given in the below link to perform license compliance check.

    https://www.fossology.org/get-started/basic-workflow/#bw1

6. To kill the docker container, open a new terminal window and run the below command to get the container id.

    `$ docker container ls`

7. Copy the container id of fossology.

8. Run the below command to kill the container.

    `$ docker kill <container id>`