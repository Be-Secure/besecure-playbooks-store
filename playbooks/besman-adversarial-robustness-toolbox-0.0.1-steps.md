1.Execute the below commamnd:
-docker pull fossology/fossology:latest 
-docker run -p 8081:80 --name fossology -d fossology/fossology 
2.Once your container is running ,Log in to http://localhost:8081/repo/ 
3.System Administrators credentials
Default username: fossy 
Default password: fossy 
4.Now you are logged in to your fossology insatnce
5.Analyze the Project :
-Go to Upload then From file
-Download the zip file of the project and add the zip file in "choose files".
-Then checkbox for below line needs to be checked
"Apply global decisions for current upload"
"visible for all groups"
Select optional analysis:
"copyright/Email?URL/Author Analysis"
"ECC Analysis,scanning for text fragments potentially relevent for export control"
"IPRA Analysis,scanning for text fragments potentially relevent for patent issues"
"Keyword Analysis"
"Monk License Analysis,scanning for license performing a text comparison"
"Nomos License Analysis ,scanning for license using regular expression"
"Ojo License Analysis,scanning for licesense using SPDX-License-Identifier"
Automatic concludede License Decider:
"Scanners matches if all Nomos findings are within Monk findings"
"scanners matches if ojo or REUSE software findings are no contradication with other findings"
-then click on "upload"
-After clicking on upload, you will see the “upload #.” click on the blue link to see the jobs running  
-To download the report, click on “Browse” and click on “select action” for the respective project and click on “Export CSV report (SPDX).” Click on “Jobs” to check the CSV report being downloaded. 
6.Downloded file is the formate of CSV convert it into json.(file should be in json formate)
7.After converting the file should be saved inside the assessment datastore directory in the appropriate location.