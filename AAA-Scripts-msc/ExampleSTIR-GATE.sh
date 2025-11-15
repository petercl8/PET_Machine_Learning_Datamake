#! /bin/sh
## AUTHOR: Robert Twyman
## Copyright (C) 2020 University College London
## Licensed under the Apache License, Version 2.0

## An example of how to use this STIR-GATE-Connection project.

# Tutorial
# ===========
# New to the project? This example script will work through the basic usage. 
# This script aims to use each of the three main aspects of this project: voxelised phantom creation, GATE simulation, and unlisting of a root file.
# This script requries one argument input that is a simulation unique identifier (e.g. `./ExampleSTIR-GATE.sh "test"`). 


## Job index for parallel GATE simulations
# E Task ID is the name of the simulation we pass
if [ $# != 1 ]
then
	echo "ExampleSTIR-GATE Usage: SectionNum"
	exit 1
else
	SectionNum=$1
	echo "SectionNum = "
fi

set -e # exit on error
trap "echo ERROR in $0" ERR  #P Sets a trap. If ERR = error occurs, it gives a message that an error occured in $O ($0 script name in which error ccured)


echo "Script initialised:" `date +%d.%m.%y-%H:%M:%S`

##### ==============================================================
## Parameters,GATE Arguments and files
##### ==============================================================

## Activity and Attenuation files. 
## There are two main options here: 
##		1. define `.par` files, or 
##		2. provide interfile images (i.e. precreated voxelised phantoms) and as long as STIR can read them, they are usable in this project. 
Activity=../ExamplePhantoms/STIRparFiles/generate_uniform_cylinder.par
Attenuation=../ExamplePhantoms/STIRparFiles/generate_atten_cylinder.par

## OPTIONAL: Editable fields required by the GATE macro scripts
GATEMainMacro="MainGATE.mac" ## Main macro script for GATE - links to many GATESubMacro/ files 
StartTime=0  ## Start time (s) in GATE time
EndTime=1  ## End time (s) in GATE time
GateOutputFilesDirectory=Output  ## Save location of root data (default: `Output/`)
ScannerType="D690"  # Selection of scanner from Examples (eg. D690/mMR)
ROOT_FILENAME_PREFIX=Sim_$SectionNum ## This is the output filename of the root file from GATE. We suggest the usage of the $SectionNum variable in this naming

## Unlisting Coincidence data into sinograms
## STIR can reject certain types of events based upon event infomation.
UnlistScatteredCoincidences=1  ## Unlist Scattered photon coincidence events (0 or 1)
UnlistRandomCoincidences=1  ## Unlist Random coincidence events (0 or 1)

## Unlist Delayed coincidence event data. This can be used in randoms estimation
UnlistDelayedEvents=1


##### ==============================================================
## Create activity and attenuation files for GATE simulation
##### ==============================================================

## This could be done by SetupSimulation.sh, but we need the $ActivityFilename and 
## $AttenuationFilename for this example
SourceFilenames=`SubScripts/GenerateSTIRGATEImages.sh $Activity $Attenuation 2>/dev/null` #P This sends the standard error file to /dev/null, effectively supressing any error messages.
if [ $? -ne 0 ] ;then
	echo "Error in SubScripts/GenerateSTIRGATEImages.sh"
	echo $GenerateSTIRGATEImagesOUTPUT
	exit 1
fi
## Get activity and attenuation filenames from the output of SubScripts/GenerateSTIRGATEImages.sh
ActivityFilename=`echo $SourceFilenames | awk '{print $(NF-1)}'`$SectionNum
AttenuationFilename=`echo $SourceFilenames | awk '{print $NF}'`

## Setup Simulation. Copy files, (possibly generate phantom), and create GATE density map
./SetupSimulation.sh $ScannerType $GateOutputFilesDirectory $ActivityFilename $AttenuationFilename
if [ $? -ne 0 ] ;then
	echo "Error in SetupSimulation.sh"
	exit 1
fi


##### ==============================================================
## RunGATE
##### ==============================================================

## Here many arguments are given to the script ./RunGATEandUnlist.sh 
## This script does computation to center the voxelised phantom on the origin (center of scanner).
## This script will also handle a lot of the GATE macro variables.
./RunGATEandUnlist.sh $GATEMainMacro $ROOT_FILENAME_PREFIX $ActivityFilename $AttenuationFilename\
			$ $GateOutputFilesDirectory $SectionNum $StartTime $EndTime #P All these were set above.
if [ $? -ne 0 ]; then
	echo "Error in RunGATEandUnlist.sh"
	exit 1
fi

##### ==============================================================
## Unlist GATE data
##### ==============================================================

## Unlist Coincidences, ROOT_FILENAME_PREFIX should be same as above, ignore "*.Coincidences.root" addition
./SubScripts/_UnlistRoot.sh $GateOutputFilesDirectory $ROOT_FILENAME_PREFIX "Coincidences" $UnlistScatteredCoincidences $UnlistRandomCoincidences 
if [ $? -ne 0 ]; then
	echo "Error in ./SubScripts/_UnlistRoot.sh for Coincidences"
	exit 1
fi

if [ $UnlistDelayedEvents == 1 ]; then
	## Unlist Delayed, ROOT_FILENAME_PREFIX should be same as above, ignore "*.Delayed.root" addition
	./SubScripts/_UnlistRoot.sh $GateOutputFilesDirectory $ROOT_FILENAME_PREFIX "Delayed" $UnlistScatteredCoincidences $UnlistRandomCoincidences 
	if [ $? -ne 0 ]; then
		echo "Error in ./SubScripts/_UnlistRoot.sh for Delayed."
		echo "Sometimes with the Example single voxel this can happen becasue there are no Delayed events."
	fi
else 
	echo "Unlisting of Delayed events has been disabled by [UnlistDelayedEvents = ${UnlistDelayedEvents}]."
fi

echo "Script finished: " `date +%d.%m.%y-%H:%M:%S`

exit 0
