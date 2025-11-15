#! /bin/sh
# Convert GATE output (.hdr) to interfile (.h33) then to STIR interfile (.hv)
# $1 = full file path to MuMap
# $2 = SectionNum
# $3 = full file path to SourceMap


## Deal with Source Map
## --------------------

# Convert the SourceMap hdr file to interfile (.h33) and saves as m000-Phantom{$SectionNum}-SourceMap.h33 in VoxelisedSimulation
medcon -f $3 -c intf -w


## Deal with MuMap
## ---------------

# Converts MuMap hdr file to interfile (.h33) and saves as m000-Phantom{$SectionNum}-MuMap.h33 in VoxelisedSimulation
medcon -f $1 -c intf -w

# Next, we need to convert the MuMap .h33 header to a .hv header, so that STIR can use it in reconstruction.
# z slice thickness depends on scanner used
if [ $ScannerType = "D690" ]; then
    scaling_factor=3.27
elif [ $ScannerType = "mMR" ]; then
    scaling_factor=2.03125
fi

# Converts h33 header to hv header, automatically naming it according to the SectionNum
sed -e "s/total number of images *:=\(.*\)/matrix size[3] := \1/i" -e "s/data offset in bytes/data offset in bytes[1]/i" \
 -e "s#slice thickness (pixels) := .*#scaling factor (mm/pixel) [3] := ${scaling_factor}#i" \
 -e "s/INTERFILE *:=/INTERFILE :=\nnumber of dimensions := 3\nnumber of time frames := 1/i" \
 -e "s/short float/float/i" -e "s/.*matrix axis label.*//i" -e "s/type of data *:= *tomographic/type of data := PET/i" \
 -e "s/.*nucmed.*/imaging modality := PT/i" "../VoxelisedSimulation/m000-Phantom${2}-MuMap.h33" > "../VoxelisedSimulation/m000-Phantom${2}-MuMap.hv"

