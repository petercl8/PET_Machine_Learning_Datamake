#! /bin/bash
##################################################################
## Convert STIR-only sinogram interfiles (.hs) to interfile 3.3 ##
##################################################################
# $path_to_file $PhantomSpecificDataFolder $SectionNum $label

path_to_file=$1
PhantomSpecificDataFolder=$2
SectionNum=$3
label=$4

stir_math -s --including-first --times-scalar 1 "intermediateSino_${label}.hs" $path_to_file # Should copy the sinogram from it's original location to VoxelisedSimulation. It renames it in the process.

# extract_segments prompts 'Extract as SegmentByView (0) or BySinogram (1)?[0,1 D:0]'
# Piping 'echo "0/1"' into extract_segments accepts the number as input and no longer requires user input.

echo "1" | extract_segments "intermediateSino_${label}.hs"  # Converts from a .hs to a stack of .hv files. Enters "1" to the prompt to extract sinogram.

medcon -f "intermediateSino_${label}seg0_by_sino.hv" -c nifti -w

extracted_nifti=m000-intermediateSino_${label}seg0_by_sino.nii

cp "../VoxelisedSimulation/${extracted_nifti}" "${DatasetDir}/${PhantomSpecificDataFolder}/intermediate_sino_${label}_${SectionNum}.nii"

exit 0