#!/bin/bash

#
# Images to scan
# gp-server, geometry-server, map-server, arcgis-postgresql
# enterprise-admin-tools, gp-proxy-server, sharing,
# sds-feature-server, relational-datastore 

# 
# Images to skip
#
ImagesToSkip='apps arcgis-minio jsapi home manager enterprise-rabbitmq arcgis-ingress-controller arcgis-filebeat arcgis-busybox'

DockerImageList="$(docker images --format {{.Repository}}:{{.Tag}}:{{.ID}})"

#echo $DockerImageList

for DockerImage in $DockerImageList; do
    #echo $DockerImage
    echo
    set -- $(echo $DockerImage | awk -F ":" '{print $1, $2, $3}')
    ImageDesc=$1
    BuildTag=$2
    ImageID=$3

    #echo "Image Desc " $ImageDesc
    #echo "Build Tag " $BuildTag
    #echo "Image ID " $ImageID

    ContainerName=$(echo $ImageDesc | awk -F "/" '{print $3}')-$BuildTag
    ImageName=$(echo $ImageDesc | awk -F "/" '{print $3}')

    #echo "Container name : $ContainerName"
    #echo "Images to skip: $ImagesToSkip"

    if [[ "$ImagesToSkip" == *"$ImageName"* ]]; then
        echo "Skipping image : $ImageName ..."
        continue
    fi

    echo "Checking docker image for: $ImageName"

    # DBG
    #continue

    #
    # Doesn't work for some images (relational-datastore, postgresql,etc...)
    #ContainerID=$(docker create --name $ContainerName $ImageID)
    # echo "Container ID:" $ContainerID
    # To manually create container and view jar files use 
    #      docker run --rm -it --entrypoint=/bin/bash $ImageID
    #docker run -it --entrypoint=/bin/bash --name ContainerName 886ff79a0df5
    #ContainerID=$(docker run -d --entrypoint=/bin/bash --name $ContainerName $ImageID sleep 120)
    #

    #docker run -t -d --entrypoint=/bin/bash --name $ContainerName "$ImageID"
    ContainerID=$(docker run -t -d --entrypoint=/bin/bash --name $ContainerName "$ImageID")
    
    # Copy script to container
    echo "docker cp /home/root/sandbox/get-list-esri-jars.sh $ContainerName:/arcgis/"
    docker cp /home/root/sandbox/get-list-esri-jars.sh $ContainerName:/arcgis/

    # Run script inside container
    #echo "docker start $ContainerName"
    docker start $ContainerName 

    echo "docker exec $ContainerName /arcgis/get-list-esri-jars.sh"
    docker exec $ContainerName /arcgis/get-list-esri-jars.sh

    #Copy script output to host
    echo "docker cp  $ContainerName:/arcgis/EsriJarFileList.txt ./EsriJarFileList_$ContainerName.txt"
    docker cp  $ContainerName:/arcgis/EsriJarFileList.txt ./EsriJarFileList_$ContainerName.txt
    
    if [ ! -d "arcgis-jars" ];then
        mkdir arcgis-jars
    fi

    echo "Copying Jars for $ContainerName..."
    while IFS= read -r JarFileName
    do
        Dir="$(dirname "${JarFileName}")"
        FileName="$(basename "${JarFileName}")"
        DestFolder="./arcgis-jars/"$ContainerName"_"$(echo $Dir | cut -d "/" -f 3- | sed  's/\//_/g')"/"
	#echo
        #echo "Src " $JarFileName

	#
	# Ensure base folder exists
        #
	if [ ! -d "$DestFolder" ];then
            #echo " Creating $DestFolder..."
	    mkdir $DestFolder
        fi
	#echo "Dest " $DestFolder
	# Print out copy command for manual testing
        #echo "docker cp $ContainerName:$JarFileName $DestFolder"

        docker cp $ContainerName:$JarFileName $DestFolder

	# Test single run of loop
        #docker stop $ContainerName
        #docker rm $ContainerName
	#exit

    done < "./EsriJarFileList_$ContainerName.txt"
    echo "- Done copying Jars for $ContainerName"

    # Clean up container
    # Stopping container...
    echo "Stopping  $ContainerName..."
    docker stop $ContainerName
    # Deleting container...
    echo "Deleting  $ContainerName..."
    docker rm $ContainerName

    # Run test for a single image 
    #exit
done
