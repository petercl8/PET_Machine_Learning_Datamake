#! /bin/bash
##################################################################
## Convert STIR-only sinogram interfiles (.hs) to interfile 3.3 ##
##################################################################
# $rebinned_filename $PhantomSpecificDataFolder $SectionNum $count_label

rebinned_filename=$1
PhantomSpecificDataFolder=$2
SectionNum=$3
count_label=$4

Path="../VoxelisedSimulation"

## Files to read
HeaderFile="${Path}/${rebinned_filename}_${count_label}.hs"
# Split key on ':= ' with space included - since STIR generates the header file there should always be a space.
#DataFile="${Path}/$(awk -F':= ' '/name of data file/ { print $2 }' $HeaderFile)"

# extract_segments prompts 'Extract as SegmentByView (0) or BySinogram (1)?[0,1 D:0]'
# Piping 'echo "0/1"' into extract_segments accepts the number as input and no longer requires user input.
echo "1" | extract_segments $( basename $HeaderFile ) # Converts from a .hs to a stack of .hv files. Enters "1" to the prompt to extract sinogram.

# Copy sinograms to save to DatasetDir and delete unneeded files

cp "../VoxelisedSimulation/${rebinned_filename}_${count_label}seg0_by_sino.hv" "${DatasetDir}/${PhantomSpecificDataFolder}/rebin_${count_label}CountSino_${SectionNum}.hv"
cp "../VoxelisedSimulation/${rebinned_filename}_${count_label}seg0_by_sino.v" "${DatasetDir}/${PhantomSpecificDataFolder}/rebin_${count_label}CountSino_${SectionNum}.v"

sed -i "s/.*seg0.*/!name of data file := rebin_${count_label}CountSino_${SectionNum}.v/" "${DatasetDir}/${PhantomSpecificDataFolder}/rebin_${count_label}CountSino_${SectionNum}.hv"

exit 0