#! /bin/sh
## AUTHOR: Robert Twyman
## Copyright (C) 2020 University College London
## Licensed under the Apache License, Version 2.0


## This script is used to generate STIR-GATE activity and attenuation images.
## Any STIR reable voxelised phantoms (activity and attenuation files) are processed into a GATE readable file formates (.h33) for simulation.
## If parameter files for generating new image using STIR are provided, these will be generated.
## A modification is made to the scale of the attenuation file. GATE requires integer attenuation factors. This script copies the phantoms and performs STIR math to increase the attenuation factors.


if [ $# -ne 2 ]; then
  echo "Usage:"$0 "Activity(.par/.hv) AttenuationPar(.par/.hv)" 1>&2 #P To StdErr
  echo "Returns Activity and Attenuation filenames." #P To StdOut
  exit 1
fi

set -e # exit on error
trap "echo ERROR in $0" ERR

echo "Samplename1.h33" "Samplename2.h33"

Activity=$1  ## Activity parameter file (#P These are paths.)
Attenuation=$2  ## Attenuation parameter file
STIRGATEHome=$PWD


#P Grabs the output filenames from /output filename/ fields in the the *.par files and adds extension: *.hv
#P Then, it generates the images (STIR documentation for this is nearly nonexistent)
if [ "${Activity##*.}" == "par" -a "${Attenuation##*.}" == "par" ]; then
	# If .par files are given, generate the data
	ActivityFilename=`awk -F:= '/output filename/ { print $2 }' $Activity`".hv"
	AttenuationFilename=`awk -F:= '/output filename/ { print $2 }' $Attenuation`".hv"
	## Generate images
	generate_image $Activity 		#P $Activity & $Attentuation are full paths to .par files, not just the Filenames.
	generate_image $Attenuation		#P Later, $ActivityFilename & $AttuationFilename map to images generated here.

else
	# Set filenames
	ActivityFilename=$Activity
	AttenuationFilename=$Attenuation
fi

## Create a new copy of the image, this is to ensure the file format is consistant when going into GATE 
ActivityFilenamePrefix="${ActivityFilename%%.*}"
AttenuationFilenamePrefix="${AttenuationFilename%%.*}"
ActivityFilenameGATE=$ActivityFilenamePrefix"_GATE"
AttenuationFilenameGATE=$AttenuationFilenamePrefix"_GATE"
# E next lines perform multiplication of the scalar with $*Filename then put into variable *FilenameGATE
stir_math --including-first --times-scalar 1 $ActivityFilenameGATE".hv" $ActivityFilename #P At this point, $ActivityFilename refers to a real file.
## Modify the scale of the attenuation file for GATE (requires int values).
stir_math --including-first --times-scalar 10000 $AttenuationFilenameGATE".hv" $AttenuationFilename

## Process file into .h33 files.
## This adds fields: "!number of slices :=" and "slice thickness (pixels) :=".
sh ./SubScripts/_STIR2GATE_interfile.sh $ActivityFilenameGATE".h33" $ActivityFilenameGATE".hv" # E Here we have files with endings .hv.h33 and .hv.hv?
sh ./SubScripts/_STIR2GATE_interfile.sh $AttenuationFilenameGATE".h33" $AttenuationFilenameGATE".hv" 

echo $ActivityFilenameGATE".h33" $AttenuationFilenameGATE".h33"

exit 0