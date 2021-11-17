#!/bin/bash

    SrchSrcPath="/arcgis"

    JarFileList="$(find $SrchSrcPath -name "*.jar")"
    EsriJarFileList=""
    #echo "Jar Files found: " $JarFileList

    for JarFileName in $JarFileList; do

        if grep -q esri "$JarFileName"; then
            #echo " Esri Jar : $JarFileName"
	    echo "$JarFileName" >> /arcgis/EsriJarFileList.txt
        #else
        #    echo " Not Esri Jar : $JarFileName"
        fi
    done
