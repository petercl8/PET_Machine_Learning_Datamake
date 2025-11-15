#! /bin/bash

####
# Script for producing an Axial phantom. Activity is scaled so that the activity/cm (axial direction) for this phantom equals the activity/cm for a XCAT phantom.
####

##################
##   SET PATH   ##
##################

# Here, we set a relative path to the QAPhantoms directory. This will be different, depending on where the script is run from,
# since bash references all local paths with respect to the directory the bash script is run in.
# The file outputs will be in whatever directory the script is called from. This is awkward but it's just the way bash is.
#
# There are two options:
#   a) If this script is being called from __MAIN_SCRIPT.sh (in VoxelisedSimulation directory). In this case the output files will be in VoxelisedSimulation.
#   b) If the script is being run directly from its own working directory. In this case the output files will be in the same directory this file is in.

Path="../" # If running this script from it's own directory, the path is the parent directory (QAPhantoms)
basename=$(basename "$PWD") # Sets basename to current working directory (but not the full path)
if [ "$basename" = "VoxelisedSimulation" ]; then
    Path=../QAPhantoms/ # If running from voxelizedSimulation, the path is also QAPhantoms.
fi

#########################
##   USER PARAMETERS   ##
#########################

## Phantom Parameters
## ------------------
Mask=0  # Set to 1 to create a mask where voxel values = 1 for the hot region, 0 for the cold region.
MaskCold=0 # Set to 1 to create a mask where voxel values = 1 for the cold region, 0 for the hot region.
PhantomName=PhantomAxial
PhantomHeight=153.69 # in mm. Height of the phantom that is in the FOV of the scanner. Used to set the correct activity level.
WaterLAC=0.096 # in cm-1

## XCAT Parameters
## ---------------
XCAT_phantomPath=${Path}XCAT_phantom/male_pt141_torso_D690.hv # Path to a an XCAT phantom section (will be used to set the activity of the NEMA phantom so that the activity/slice is the same as the XCAT phantom)
XCAT_phantomHeight=153.69 # Height of the XCAT section (in mm). This is necesssary to calculate the activity/mm. For the D690, the height of each section is 153.69.

## Scanner Parameters
## ---------------------
SampleNum=1 # Set to a larger number for softer edges
RingNum=24    # For D690, RingNum=24 ||  for MMR, RingNum = 64
RingSpacing=6.54 # in mm. For D690, RingSpacing=6.54 || For MMR, RingSpacing=4.0625.
RingOffset=-1    # Offset the activity spheres this number of slices (may need to be adjusted to 0,1 or -1  to make sure the spheres are at the center of the scanner)

# Voxel sizes. Note: VoxSizeZ and VoxNumZ are determined by the scanner geometry.
VoxSizeX=3 # in mm. Currently set to the voxel size of the final reconstructed image but can be varied.
VoxSizeY=3 # in mm
VoxNumX=180 # make odd to evenly center image
VoxNumY=180 # make odd to evenly center image

## Calculations
## ------------
CenterScanner=$(echo "scale=4; ($RingNum / 2) * $RingSpacing + ($RingSpacing * 0.5 * $RingOffset)" | bc)
VoxSizeZ=$(echo "scale=4; ($RingSpacing / 2)" | bc)
VoxNumZ=$(echo "scale=4; ($RingNum * 2) - 1" | bc)

echo "CenterScanner: $CenterScanner"
echo "VoxSizeZ: $VoxSizeZ"
echo "VoxNumZ: $VoxNumZ"

## Export Variables
## ----------------
export SampleNum 
export VoxSizeX VoxSizeY VoxSizeZ 
export VoxNumX VoxNumY VoxNumZ
export CenterScanner 

## Generate Basic Shapes
## ---------------------
echo "generate shapes" 
generate_image ${Path}ParFiles/axial_basicShape-circles.par

stir_math --including-first --times-scalar 1 ${PhantomName}_act.hv BasicShape.hv
stir_math --including-first --times-scalar $WaterLAC ${PhantomName}_atn.hv BasicShape.hv # Set background attenuation

## Normalize to Correct Activity
## -----------------------------
if [ $Mask = 0 ]; then
    # Calculate activity/cm for XCAT phantom
    XCAT_sum=$(list_image_info $XCAT_phantomPath | awk -F: '/Image sum/ {print $2}' | tr -d '[:space:]')
    XCAT_sum_decimal=$(printf "%.10f" "$XCAT_sum")
    XCAT_slice_sum=$(echo "scale=10; $XCAT_sum_decimal / $XCAT_phantomHeight" | bc 2>&1)

    # Calculate activity/cm for current axial phantom
    QA_sum=$(list_image_info "${PhantomName}_act.hv" | awk -F: '/Image sum/ {print $2}' | tr -d '[:space:]')
    QA_sum_decimal=$(printf "%.10f" "$QA_sum")
    QA_slice_sum=$(echo "scale=10; $QA_sum_decimal / $PhantomHeight" | bc 2>&1)

    # Calculate the reciprocal using `bc`
    NormalizationFactor=$(echo "scale=15; $XCAT_slice_sum / $QA_slice_sum" | bc 2>&1)

    # Normalize Image
    stir_math --accumulate --including-first --times-scalar $NormalizationFactor ${PhantomName}_act.hv
fi

if [ $MaskCold = 1 ]; then
    stir_math --accumulate --including-first --add-scalar -1 ${PhantomName}_act.hv
    stir_math --accumulate --including-first --times-scalar -1 ${PhantomName}_act.hv
fi

if [ $Path = "../QAPhantoms/" ]; then # If running from VoxelizedSimulation
    sh ./SubScripts/_STIR2GATE_interfile.sh "${PhantomName}_atn.h33" "${PhantomName}_atn.hv"
    sh ./SubScripts/_STIR2GATE_interfile.sh "${PhantomName}_act.h33" "${PhantomName}_act.hv"
elif [ $Path = "../" ]; then # If running from this script's home directory
#sh ../SubScripts/_STIR2GATE_interfile.sh NEMA_background.h33 NEMA_background.hv
    sh ../../VoxelisedSimulation/SubScripts/_STIR2GATE_interfile.sh "${PhantomName}_atn.h33" "${PhantomName}_atn.hv"
    sh ../../VoxelisedSimulation/SubScripts/_STIR2GATE_interfile.sh "${PhantomName}_act.h33" "${PhantomName}_act.hv"
fi

rm *.nii

medcon -f ${PhantomName}_atn.hv -c nifti -w
medcon -f ${PhantomName}_act.hv -c nifti -w


## Display Images ##
xmedcon ${PhantomName}_act.h33
xmedcon ${PhantomName}_atn.h33