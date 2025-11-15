#! /bin/sh

## AUTHOR: Robert Twyman
## Copyright (C) 2020, 2021 University College London
## Licensed under the Apache License, Version 2.0

# This file will make a altered copy of "lm_to_projdata_template.par" and 
# "root_header_template.par" before unlisting a root file into an interfile.

# The Required Args:
# - $1: Root files directory
# - $2: ROOT_FILENAME_PREFIX
# - $3: Which data to unlist ("Coincidences" or "Delayed") 

## Optional Args:
# - $4: Include Scatter flag (0 or 1. Default:1)
# - $5: Include Random flag (0 or 1. Default:1)
# - $6: Acceptance Probability (range 0-1. Default:1). The probability an event is accepted to be unlisted. If 1, all events are accepted.
# - $7: Lower Energy Threshold in keV (Default: 0) Note: if kept as default, this causes an error.
# - $8: Upper Energy Threshold in keV (Default: 1000)
# - $9: The Maximum Number of Events to Unlist into a Sinogram. (Default: -1, no limit)


# NOTE: this file has been modified from its original form in the STIR-GATE Connection project.

## Input arguments
GateOutputFilesDirectory=$1		# default = Output
ROOT_FILENAME_PREFIX=$2		# default = Sim_$SectionNum 
EventDataType=$3			# Will be set to "Coincidences" and then "Delayed"
ScatterFlag=$4				# $UnlistScatteredCoincidences = 1
RandomFlag=$5				# $UnlistRandomCoincidences

AcceptanceProb=1			# default = 1
LowerEnergyThreshold=425	# Set below to default to 0
UpperEngeryThreshold=650	# Set below to default to 1000
NumEventsToStore=-1			# default = -1 (store all)


UnlistingDirectory="${GateOutputFilesDirectory}/Unlisted/${EventDataType}"

echo "###############################################"
echo "STIR-GATE-Connection Unlisting ROOT data script"
echo "###############################################"


## Ensure ScatterFlag and RandomFlag are 0 or 1. Set Exclude versions respectively
if [ $ScatterFlag -eq 0 ]; then
	ExcludeScatterFlag=1
else
	ExcludeScatterFlag=0 
fi

if [ $RandomFlag -eq 0 ]; then
	ExcludeRandomFlag=1
else
	ExcludeRandomFlag=0 
fi 

## Check EventDataType is Coincidences or Delayed 
if [ $EventDataType != "Coincidences" ] && [ $EventDataType != "Delayed" ]; then
	echo "Error UnlistRoot can currently only handle Coincidences and Delayed"
	exit 1
fi

# Get a random seed int
seed=${RANDOM}

## Rename the interpration of the ROOT file to have "*.EventDataType" in the name.
ROOT_FILENAME=$ROOT_FILENAME_PREFIX"."$EventDataType  # either Sim_$SectionNum.Coincidences OR Sim_$SectionNum.Delayed

## Name of the sinogram file ID, uses Scatter and Random Flags
SinogramID="Sino_${ROOT_FILENAME}_S${ScatterFlag}R${RandomFlag}" # e.g. Sino_Sim_$TASKID.Coincidences_S1R1

## ============= Console ouput regarding unlisting configuration =============

echo "Unlisting ${GateOutputFilesDirectory}/${ROOT_FILENAME}.root"	# Data file has .root extension
echo "Unlisting with EXCLUDESCATTER = ${ExcludeScatterFlag}"
echo "Unlisting with EXCLUDERANDOM = ${ExcludeRandomFlag}"
if [ ${NumEventsToStore} != -1 ]; then
	echo "Unlisting a maximum of ${NumEventsToStore} events."
fi

## Ensure the UnlistingDirectory exists.
# -d returns true if file is a directory only
# mkdir -p creates the entire directory tree if it doesn't already exist
if [ ! -d $UnlistingDirectory ]; then
	echo "creating directory $UnlistingDirectory"
	mkdir -p $UnlistingDirectory  # e.g. Output/Unlisted/${EventDataType}, where {EventDataType} = "Coincidences" or "Delayed"
fi


## ============= Create parameter file from template =============

###################################################################################
## Copy lm_to_projdata parameter file (template) to $GateOutputFilesDirectory & edit ##
###################################################################################

LM_TO_PROJDATA_PAR_PATH=$GateOutputFilesDirectory/lm_to_projdata_${ROOT_FILENAME}.par # e.g. Output/lm_to_projdata_Sim_$SectionNum.{$EventDataType}.par. This is a relative path (relative to VoxelisedSimulation/). This works because the current working directory (CWD) remains constant (which is the CWD for the initial bash script), even if directories in which daughter scripts are placed differ.

cp  UnlistingTemplates/lm_to_projdata_template.par ${LM_TO_PROJDATA_PAR_PATH}	# This copies the par file to the path specified in the line above (which depends on EventDataType).

sed -i.bak "s|{ROOT_FILENAME}|$GateOutputFilesDirectory/${ROOT_FILENAME}|g" ${LM_TO_PROJDATA_PAR_PATH} # Here we have the relative path (relative to VoxelizedSimulation/) to the root file (e.g. Output/Sim_$SectionNum.{$EventDataType}. This links the new .par file to the root files (.hroot, .hroot). The .hroot file is edited below.

sed -i.bak "s/{SinogramID}/${SinogramID}/g" ${LM_TO_PROJDATA_PAR_PATH}	 # Here, SinogramID is replaced with e.g. Sino_Sim_$TASKID.{$EventDataType}_S1R1. A full path is not given because the sinogram is an output file and STIR creates it in the unlisting directory (specified in next line).

sed -i.bak "s|{UNLISTINGDIRECTORY}|${UnlistingDirectory}|g" ${LM_TO_PROJDATA_PAR_PATH} # e.g. UnlistingDirectory=Output/Unlisted/${EventDataType}

sed -i.bak "s|{seed}|${seed}|g" ${LM_TO_PROJDATA_PAR_PATH}	# seed=${RANDOM}

sed -i.bak "s|{NumEventsToStore}|${NumEventsToStore}|g" ${LM_TO_PROJDATA_PAR_PATH}	# NumEventsToStore = -1

###########################################################################################
## Copy ROOT header file (a scanner specific template) to $GateOutputFilesDirectory & edit 	  #
## After running GATE, this data file already exists: Sim_$SectionNum.$EventDataType.root    #
## We now add the appropriate header file:			  Sim_$SectionNum.$EventDataType.hroot   #
###########################################################################################

ROOT_FILENAME_PATH="${GateOutputFilesDirectory}/${ROOT_FILENAME}.hroot"  # This will be Output/Sim_$SectionNum.$EventDataType.hroot

cp  UnlistingTemplates/root_header_template.hroot ${ROOT_FILENAME_PATH} # Earlier, in PrepareScannerFiles.sh, two scanner files were copied from the appropriate scanner directory to two files (root_header_template.hroot & STIR_scanner.hs) in /UnlistingTemplates. This line copies root_header_template.hroot to yet another path (Output/Sim_$SectionNum.$EventDataType.hroot. This operation is done twice, but because $EventDataType is different for the two calls, two header files are created.

sed -i.bak "s/{ROOT_FILENAME}/${ROOT_FILENAME}/g" ${ROOT_FILENAME_PATH} # Here, {ROOT_FILENAME} is replaced by $ROOT_FILENAME (Sim_$SectionNum.$EventDataType) and does not include the full path (unlike above). I assume this is because the root header file is always placed in the same directory as the root file, whereas the BASH command which takes the .par file as an argument is effectively run from the VoxelizedSimulation working directory, and so needs the full path.

sed -i.bak "s/{LOWTHRES}/${LowerEnergyThreshold}/g" ${ROOT_FILENAME_PATH} # Replace {LOWTHRES} with $LowerEnergyThreshold
sed -i.bak "s/{UPTHRES}/${UpperEngeryThreshold}/g" ${ROOT_FILENAME_PATH}
sed -i.bak "s/{EXCLUDESCATTER}/${ExcludeScatterFlag}/g" ${ROOT_FILENAME_PATH}
sed -i.bak "s/{EXCLUDERANDOM}/${ExcludeRandomFlag}/g" ${ROOT_FILENAME_PATH}
sed -i.bak "s/{EXCLUDENONRANDOM}/0/g" ${ROOT_FILENAME_PATH}  	# Hardcoded to include non-random events
sed -i.bak "s/{EXCLUDEUNSCATTERED}/0/g" ${ROOT_FILENAME_PATH} # Hardcoded to include unscattered events #P I think he really means include scattered events/not exclude unscattered events.

## Remove sed temporary files
rm $GateOutputFilesDirectory/*.bak


## ============= Perform ROOT file unlisting =============

		# default AcceptProb = 1 (accept all events)
if [ -z "$AcceptanceProb" ] || [ "$AcceptanceProb" -eq 1 ]; then
    # Code to execute if AcceptanceProb is unset, empty, or equals 1
	echo "No AcceptanceProb given or AcceptanceProb=1, unlist all using standard to lm_to_projdata"
	lm_to_projdata ${LM_TO_PROJDATA_PAR_PATH}	# runs  lm_to_projdata using the first .par file
	if [ $? -ne 0 ]; then
		echo "Error in ./SubScripts/_UnlistRoot.sh: lm_to_projdata failed, see error."
		exit 1
	fi
else
	echo "AcceptanceProb = ${AcceptanceProb}, unlisting with random rejection"
	lm_to_projdata_with_random_rejection ${LM_TO_PROJDATA_PAR_PATH} ${AcceptanceProb}
	if [ $? -ne 0 ]; then
		echo "Error in ./SubScripts/_UnlistRoot.sh: lm_to_projdata_with_random_rejection failed, see error."
		exit 1
	fi
fi

## Echo sinogram filepath
echo "Sinogram saved as ./${GateOutputFilesDirectory}/Unlisted/UnlistedSinograms/${SinogramID}"

exit 0
