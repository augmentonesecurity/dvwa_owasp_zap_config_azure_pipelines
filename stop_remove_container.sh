#!/bin/bash	

containerName=$1
 
# to check if the container exists. xargs is used to trim spaces
containerId=$(docker ps -aqf "name=${containerName}" | xargs)
echo "container id for ${containerName}: ${containerId}"
 
if [[ ${containerId} != "" ]]
then
    echo "Stopping container"
	docker container stop ${containerId}
    echo "Removing container"
	docker container rm ${containerId}
else 
	echo "no container called ${containerName}"
fi