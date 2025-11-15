#! /bin/sh

SectionNum=$1
ROOT_FILENAME_PREFIX=Sim_${SectionNum}

##### ================
## Unlist Coincidences
##### ================

# ===============================
# === GENERATE UNLISTED FILES ===
# GateOutputFilesDirectory/
#	lm_to_projdata_$ROOT_FILENAME_PREFIX.Coincidences.par	(parameter file for unlisting. Points to *.hroot & sinogram files [below])
#	lm_to_projdata_$ROOT_FILENAME_PREFIX.Delayed.par		(parameter file for unlisting. Points to *.hroot & sinogram files [below])
#	$ROOT_FILENAME_PREFIX.Coincidences.hroot	(Scanner-specific header file for unlisting ROOT data)
#	$ROOT_FILENAME_PREFIX.Delayed.hroot			(Scanner-specific header file for unlisting ROOT data)
# Unlisted Coincidences:
#	GateOutputFilesDirectory/Unlisted/Coincidences	
#	 	Sinogram: 			$ROOT_FILENAME_PREFIX.Coincidences_S1R1_f1g1d0b0
#		Sinogram header:	$ROOT_FILENAME_PREFIX.hs
#	GateOutputFilesDirectory/Unlisted/Delayed
#		Sinogram:			$ROOT_FILENAME_PREFIX.Coincidences_S1R1_f1g1d0b0
#		Sinogram header:	$ROOT_FILENAME_PREFIX.hs
# ================================

./SubScripts/_UnlistRoot.sh $GateOutputFilesDirectory $ROOT_FILENAME_PREFIX "Coincidences" $UnlistScatteredCoincidences $UnlistRandomCoincidences 
if [ $? -ne 0 ]; then
	echo "Error in ./SubScripts/_UnlistRoot.sh for Coincidences"
	exit 1
fi

if [ $UnlistDelayedEvents = 1 ]; then
	## Unlist Delayed, ROOT_FILENAME_PREFIX should be same as above, ignore "*.Delayed.root" addition
	./SubScripts/_UnlistRoot.sh $GateOutputFilesDirectory $ROOT_FILENAME_PREFIX "Delayed" $UnlistScatteredCoincidences $UnlistRandomCoincidences 
	if [ $? -ne 0 ]; then
		echo "Error in ./SubScripts/_UnlistRoot.sh for Delayed."
		echo "Sometimes with the Example single voxel this can happen because there are no Delayed events."
	fi
else 
	echo "Unlisting of Delayed events has been disabled by [UnlistDelayedEvents = ${UnlistDelayedEvents}]."
fi

echo "Script _UnlistPromptsAndDelayeds.sh finished running at: $(date +%T)"