#!/bin/bash

today=$(date +"%Y_%m_%d")
ImagesFile="./image-list.txt"
#ImagesFile="./test-image-list.txt"

echo "Note: This script assumes that docker authorization has already be setup"
echo " "
echo "Note: Ensure you have atleast 50GB free space on /var/lib/docker "
echo " "
echo " !!! WARNING !!!"
echo "This script will attempt to delete all existing containers and images!"
echo " !!! WARNING !!!"
echo " "

echo " "
echo Please enter the docker image-tag
echo " "
read ImageTag
#echo Pulling docker images with tag : $ImageTag

DeleteImages="n"
DeleteCurrentImages="y"
SaveToFile="n"

echo " "
echo Save all docker images to zipped file?
echo " "
echo "y\n (Default: n)"
read SaveToFile


echo " "
echo Delete all docker images after download?
echo " "
echo "y\n (Default: n)"
read DeleteImages

echo " "
echo Delete all existing docker images?
echo " "
echo "y\n (Default: y)"
read DeleteCurrentImages

if [[ "$DeleteCurrentImages" == "yes" || "$DeleteCurrentImages" == "y" ]]
then
    echo " "
    echo "Deleting existing Docker containers and images..."
    echo " "
    docker kill $(docker ps -q -a)
    docker rmi $(docker images -q -a)
    docker system prune -a
    echo " "
fi

while IFS= read -r ImageName
do
    #echo $ImageName
    ShortImageName=$(echo $ImageName | awk -F "/" '{print $NF}')
    if [[ ${ImageName:0:1} == "#" ]]
    then
        echo 
        echo "Skipping $ShortImageName .."
        echo 
    else
        echo 
        #echo "Pulling image for $ShortImageName..."
        echo "docker pull $ImageName:$ImageTag"
        docker pull $ImageName:$ImageTag
        ImageId=$(docker images -a $ImageName:$ImageTag -q)
        #echo Image ID : $ImageId
        echo 
        echo 
        if [[ "$SaveToFile" == "yes" || "$SaveToFile" == "y" ]]
	then
            if [ -z $ImageId ]
            then
                echo ERROR: Could not find docker image with the specified Image ID
	        echo 
            else
                #echo docker save -o $ShortImageName.tar $ImageId
                #echo gzip $ShortImageName.tar 

                FileName=$today-$ShortImageName.tar

                echo " "
                echo     Saving $FileName...
                docker save -o $FileName $ImageId

                echo " "
                echo     Zipping $FileName... 
                gzip -f $FileName 
                #echo     Deleting downloaded docker image...
	        # Can also delete using image ID
                # docker image rm $ImageName:$ImageTag
            fi
        fi
    fi
done < "$ImagesFile"

if [[ "$DeleteImages" == "no" || "$DeleteImages" == "n" ]]
then
    echo " "
    echo NOTE: Docker images have not been deleted
else
    echo " "
    echo "Deleting existing Docker containers and images..."
    echo " "
    docker kill $(docker ps -q -a)
    docker rmi $(docker images -q -a)
    docker system prune -a
    echo " "
fi
