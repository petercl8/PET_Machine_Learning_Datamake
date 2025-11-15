#! /bin/bash

####
# Script for producing a NEMA phantom. Activity is scaled so that the activity/cm (axial direction) for this phantom equals the activity/cm for a XCAT phantom.
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
Mask=0 # Set to 1 to make a mask for ROI analysis. In this case the activity is not scaled but is absolute, defined below.
NEMA_phantomHeight=147 # in mm. Height of the phantom that is in the FOV of the scanner. Used to set the correct activity level.
PhantomName=PhantomNEMA
WaterLAC=0.096 # in cm^-1
LungLAC=0.0288 # in cm^-1


# Activities for hot regions. Ordinarily, BackgroundActivity and the "Background_ROI.." variables are set to the same activity, so that the background is uniform. However, if you are creating a "mask" for ROI analysis, you'll want all voxels set to 0 except for the region that you are interested in, where the voxels should equal 1. In this case, set BackgroundActivity=0. Then, set one of the "Sphere..." or "Background_Sphere.." variables equal to 1 (the other variables should be set to zero) to isolate reconstructed activity in the appropriate ROI.
BackgroundActivity=1   # arbitrary units
Sphere_10_Activity=8   # arbitrary units
Sphere_13_Activity=8   # arbitrary units...
Sphere_17_Activity=8
Sphere_22_Activity=8
Sphere_28_Activity=0
Sphere_37_Activity=0

Background_ROI_Sphere_10_Activity=1
Background_ROI_Sphere_13_Activity=1
Background_ROI_Sphere_17_Activity=1
Background_ROI_Sphere_22_Activity=1
Background_ROI_Sphere_28_Activity=1
Background_ROI_Sphere_37_Activity=1

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

## Voxel sizes. Note: VoxSizeZ and VoxNumZ are determined by the scanner geometry.
## ----------------------
VoxSizeX=3 # in mm. Currently set to the voxel size of the final reconstructed image but can be varied.
VoxSizeY=3 # in mm
VoxNumX=180 # make odd to evenly center image
VoxNumY=180 # make odd to evenly center image


######################
##   CALCULATIONS   ##
######################

CenterScanner=$(echo "scale=4; ($RingNum / 2) * $RingSpacing + ($RingSpacing * 0.5 * $RingOffset)" | bc)
BackgroundOffset=$(echo "scale=4; ($NEMA_phantomHeight / 2) - 70" | bc)
#BackgroundOffset=$(echo "scale=4; ($NEMA_phantomHeight / 2)" | bc)
#BackgroundOffset=0

CenterBackground=$(echo "scale=2; $CenterScanner - $BackgroundOffset" | bc) # Changing the - to a + sign here simply reflects the phantom in the z-axis. If BackgroundOffset equaled zero, the phantom would be centered/symmetrical.

echo "NEMA_phantomHeight: $NEMA_phantomHeight"
echo "BackgroundOffset: $BackgroundOffset"
echo "CenterBackground: $CenterBackground"
echo "CenterScanner: $CenterScanner"


VoxSizeZ=$(echo "scale=4; ($RingSpacing / 2)" | bc)
VoxNumZ=$(echo "scale=4; ($RingNum * 2) - 1" | bc)
echo "VoxSizeZ: $VoxSizeZ"
echo "VoxNumZ: $VoxNumZ"

Sphere_10_ExcessActivity=$(echo "scale=4; $Sphere_10_Activity - $BackgroundActivity" | bc)
Sphere_13_ExcessActivity=$(echo "scale=4; $Sphere_13_Activity - $BackgroundActivity" | bc)
Sphere_17_ExcessActivity=$(echo "scale=4; $Sphere_17_Activity - $BackgroundActivity" | bc)
Sphere_22_ExcessActivity=$(echo "scale=4; $Sphere_22_Activity - $BackgroundActivity" | bc)
Sphere_28_ExcessActivity=$(echo "scale=4; $Sphere_28_Activity - $BackgroundActivity" | bc)
Sphere_37_ExcessActivity=$(echo "scale=4; $Sphere_37_Activity - $BackgroundActivity" | bc)

Background_ROI_Sphere_10_ExcessActivity=$(echo "scale=4; $Background_ROI_Sphere_10_Activity - $BackgroundActivity" | bc)
Background_ROI_Sphere_13_ExcessActivity=$(echo "scale=4; $Background_ROI_Sphere_13_Activity - $BackgroundActivity" | bc)
Background_ROI_Sphere_17_ExcessActivity=$(echo "scale=4; $Background_ROI_Sphere_17_Activity - $BackgroundActivity" | bc)
Background_ROI_Sphere_22_ExcessActivity=$(echo "scale=4; $Background_ROI_Sphere_22_Activity - $BackgroundActivity" | bc)
Background_ROI_Sphere_28_ExcessActivity=$(echo "scale=4; $Background_ROI_Sphere_28_Activity - $BackgroundActivity" | bc)
Background_ROI_Sphere_37_ExcessActivity=$(echo "scale=4; $Background_ROI_Sphere_37_Activity - $BackgroundActivity" | bc)

echo "Sphere_10_ExcessActivity: $Sphere_10_ExcessActivity"
echo "Background_ROI_Sphere_37_ExcessActivity: $Background_ROI_Sphere_37_ExcessActivity"


## Export Variables
## ----------------
export BackgroundActivity
export Sphere_10_ExcessActivity Sphere_13_ExcessActivity Sphere_17_ExcessActivity
export Sphere_22_ExcessActivity Sphere_28_ExcessActivity Sphere_37_ExcessActivity

export Background_ROI_Sphere_10_ExcessActivity Background_ROI_Sphere_13_ExcessActivity Background_ROI_Sphere_17_ExcessActivity
export Background_ROI_Sphere_22_ExcessActivity Background_ROI_Sphere_28_ExcessActivity Background_ROI_Sphere_37_ExcessActivity

export SampleNum RingNum RingSpacing VoxSizeX VoxSizeY
export VoxNumX VoxNumY
export CenterScanner CenterBackground VoxSizeZ VoxNumZ


########################
##   GENERATE SHAPES  ##
########################


## Generate Basic Shapes
## ---------------------
generate_image ${Path}ParFiles/NEMA_background.par
generate_image ${Path}ParFiles/NEMA_lung.par
generate_image ${Path}ParFiles/NEMA_spheres.par

## Generate Background
## -------------------
# Thresholds NEMA_background.hv so that the max value is 1.1*$BackgroundActivity. Since all areas of interset have >=2*$BackgroundActivity (prior to thresholding), all areas of interst will now have activity = 1.1*1*$BackgroundActivity.
stir_math --accumulate --including-first --max-threshold "$(echo "$BackgroundActivity * 1.1" | bc)" NEMA_background.hv

# Threshold the minimum activity so it is equal to $BackgroundActivity. The minimum activity will be set to zero in the next two lines.
stir_math --accumulate --including-first --min-threshold $BackgroundActivity NEMA_background.hv

# The activity is next reduced so the minimum activity is zero and the maximum is 0.1*$BackgroundActivity
stir_math --accumulate --including-first --add-scalar "$(echo "$BackgroundActivity * -1" | bc)" NEMA_background.hv

# After dividing by .1*$BackgroundActivity, the background now has nearly all voxels=1. Voxels with values other than 1 are due to sampling.
stir_math --accumulate --including-first --times-scalar "$(echo "scale=10; 1 / ($BackgroundActivity * .1)" | bc)" NEMA_background.hv 

# Background is altered so that voxel values=0 in the "lung". (NEMA_lung.hv has pixel values = 1 in the lung region)
stir_math --accumulate --times-scalar -1 NEMA_background.hv NEMA_lung.hv

# Get rid of any pixel values less than zero (due to sampling). All pixels should now be between 0 and 1.
stir_math --accumulate --including-first --min-threshold 0 NEMA_background.hv 

## Finish Activity Map
## -------------------
stir_math --including-first --times-scalar $BackgroundActivity "${PhantomName}_act.hv" NEMA_background.hv # Set background activity
# Add NEMA_spheres.hv to the background. These spheres have the excess activity defined above.
stir_math "${PhantomName}_act.hv" "${PhantomName}_act.hv" NEMA_spheres.hv 


## Finish Attenuation Map
## ----------------------
stir_math --including-first --times-scalar $WaterLAC "${PhantomName}_atn.hv" NEMA_background.hv # Set background attenuation
stir_math --accumulate --times-scalar $LungLAC "${PhantomName}_atn.hv" NEMA_lung.hv # NEMA_lung.hv is multplied by $LungLAC and then added to the attenuation map.



## Normalize to Correct Activity (if not making a mask)
## ----------------------------------------------------

if [ $Mask = 0 ]; then 
    # Calculate activity/cm for XCAT phantom
    XCAT_sum=$(list_image_info $XCAT_phantomPath | awk -F: '/Image sum/ {print $2}' | tr -d '[:space:]')
    XCAT_sum_decimal=$(printf "%.10f" "$XCAT_sum")
    XCAT_slice_sum=$(echo "scale=10; $XCAT_sum_decimal / $XCAT_phantomHeight" | bc 2>&1)

    # Calculate activity/cm for current NEMA phantom
    NEMA_sum=$(list_image_info "${PhantomName}_act.hv" | awk -F: '/Image sum/ {print $2}' | tr -d '[:space:]')
    NEMA_sum_decimal=$(printf "%.10f" "$NEMA_sum")
    NEMA_slice_sum=$(echo "scale=10; $NEMA_sum_decimal / $NEMA_phantomHeight" | bc 2>&1)

    # Calculate the reciprocal using `bc`
    NormalizationFactor=$(echo "scale=15; $XCAT_slice_sum / $NEMA_slice_sum" | bc 2>&1)

    # Normalize Image
    stir_math --accumulate --including-first --times-scalar $NormalizationFactor ${PhantomName}_act.hv
fi

echo "XCAT_sum_decimal: ${XCAT_sum_decimal}"
echo "XCAT_slice_sum: ${XCAT_slice_sum}"
echo "NEMA_sum_decimal: ${NEMA_sum_decimal}"
echo "NEMA_slice_sum: ${NEMA_slice_sum}"
echo "NormalizationFactor: ${NormalizationFactor}"

##########################
##   FILE CONVERSIONS   ##
##########################

if [ $Path = "../QAPhantoms/" ]; then
    sh ./SubScripts/_STIR2GATE_interfile.sh "${PhantomName}_atn.h33" "${PhantomName}_atn.hv"
    sh ./SubScripts/_STIR2GATE_interfile.sh "${PhantomName}_act.h33" "${PhantomName}_act.hv"
elif [ $Path = "../" ]; then 
#sh ../SubScripts/_STIR2GATE_interfile.sh NEMA_background.h33 NEMA_background.hv
    sh ../../VoxelisedSimulation/SubScripts/_STIR2GATE_interfile.sh "${PhantomName}_atn.h33" "${PhantomName}_atn.hv"
    sh ../../VoxelisedSimulation/SubScripts/_STIR2GATE_interfile.sh "${PhantomName}_act.h33" "${PhantomName}_act.hv"
fi

#rm *.nii
medcon -f NEMA_background.hv -c nifti -w
medcon -f NEMA_lung.hv -c nifti -w
medcon -f NEMA_spheres.hv -c nifti -w
medcon -f "${PhantomName}_atn.hv" -c nifti -w
medcon -f "${PhantomName}_act.hv" -c nifti -w


## Display Images ##
#xmedcon "${PhantomName}_act.h33"
#xmedcon "${PhantomName}_atn.h33"