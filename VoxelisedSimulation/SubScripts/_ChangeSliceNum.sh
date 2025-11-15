#! /bin/sh

# NOTE: this file has been modified from its original form in the STIR-GATE Connection project.

# Change the 47-slice section of the phantom used in the GATE simulation and image reconstruction

## Passed variables:
xcat_parfile_path=SubScripts/CreateXCATImages/general.samp_random_act.par
#   SectionNum=${SectionNum} [integer number]

SectionNum=$1

# Calculate the new slices
# XCAT phantom slice count is start and end inclusive so [1,47] is 47 slices
# It's a good idea to increment by 41 since approx. 5 slices on either end in the rebinned data look odd and will be cut out.

NewStartSlice=$((1 + ( $voxelZ-$overlap )*$SectionNum))
NewEndSlice=$(($voxelZ + ( $voxelZ-$overlap )*$SectionNum))

sed -i "s/startslice = .*/startslice = $NewStartSlice/" $xcat_parfile_path
sed -i "s/endslice = .*/endslice = $NewEndSlice/" $xcat_parfile_path