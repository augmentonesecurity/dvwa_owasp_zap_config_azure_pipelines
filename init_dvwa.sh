#!/bin/bash

# this script is to initialize the DVWA web application

# getting the port number from 1st argument
dvwaContainerPortNumber=$1

startAndInitializeDVWAContainer () {
  curl --dump-header headers.txt GET "http://localhost:${dvwaContainerPortNumber}/setup.php" > htmlresponse.txt

  # extracting out the php session id
  shellOutput=$(cat headers.txt | grep "PHPSESSID")
  echo "shellOutput for PHPSESSID lines:${shellOutput}"
  
  # getting the first line of the shell output
  firstLine=`echo "${shellOutput}" | head -n1`
  echo "Extracting first line: ${firstLine}"
  
  # removing the left hand side part of the line
  temp=${firstLine#*PHPSESSID=}
  # removing the right hand side of the line, leaving only the php session id
  phpSessionId=${temp%;*}
  echo "##[debug] php session id: ${phpSessionId}"
  
  # extracting out the user token
  shellOutput=$(cat htmlresponse.txt | grep "user_token")
  echo "shellOutput:${shellOutput}"
  temp=${shellOutput#*value=\'}
  userToken=${temp%\'*}
  echo "##[debug] user token: ${userToken}"
  
  # initializing the database of the dvwa application
  shellOutput=$(curl --location --request POST "http://localhost:${dvwaContainerPortNumber}/setup.php" --header "Cookie: PHPSESSID=${phpSessionId}; security=low" --form "user_token=${userToken}" --form "create_db=Create+%2F+Reset+Database")
  
  # checking if the database has been initialized
  if [ $(echo "${shellOutput}" | grep -c "Database has been created") -ge 1 ]
  then
    # returning true if the database has been initialized
    return 0
  else
    # returning false if the database has NOT been initialized
    return 1
  fi  
}

# looping for a few times to retry initializing the dvwa application
for i in {0..2}
do
  echo "Sleeping for 5 seconds" 
  sleep 5
  echo "Awake now" 
  shellOutput=$(curl -v -L "http://localhost:${dvwaContainerPortNumber}")
  if [ $(echo "${shellOutput}" | grep -c "<title>Login :: Damn Vulnerable Web Application (DVWA) v1.10 \*Development\*</title>") -e 1 ]; then  
    echo "DVWA application still not started" 
  elif startAndInitializeDVWAContainer; then
	echo "DVWA application initialized"
    exit 0
  else
	echo "DVWA application NOT initialized"
  fi
done

# when DVWA is still not initialized after a number of tries, we return an error exit code to cause the job to fail
exit 1
