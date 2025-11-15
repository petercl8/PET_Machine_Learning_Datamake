#! /bin/sh
## AUTHOR: Robert Twyman
## Copyright (C) 2020 University College London
## Licensed under the Apache License, Version 2.0

## Script takes a STIR image header filename and converts it into a GATE compatable .h33 file. 
## Additionally, "!number of slices" and "slice thickness (pixels)" fields are added.

GATEFilename=$1
STIRFilename=$2

if [ "${GATEFilename##*.}" != "h33"  ]; then
	echo "Error in STIR2GATE_interfile, the GATEFilename does not end in '*.h33'"
	echo "GATEFilename = $GATEFilename"
	exit 1
fi
if [ "${STIRFilename##*.}" != "hv"  ]; then
	echo "Error in STIR2GATE_interfile, the STIRFilename does not end in '*.hv'"
	echo "STIRFilename = $STIRFilename"
	exit 1
fi

## We now grab the number of slices & slice thickness from the .hv file.

# It takes output from list_image_info, uses awk with field separator set to colon (-F:),
# grabs the wnd field for those lines (after colon), uses 'translate' (tr) to remove
# curly braces, then uses field separator "'" (comma) to grab the first number in front of
# the comma (this will be the z-coordinate).

# The number of slices is the is from the line: !matrix size [3] := 47
# This line is commented out in .hv file, and when we add a line to the .h33, it is also commented out.
NumberOfSlices=`list_image_info $STIRFilename | awk -F: '/Number of voxels / {print $2}'|tr -d '{}'|awk -F, '{print $1}'` 1>&2

# Slice thickness comes from this line: scaling factor (mm/pixel) [3] := 3.27 (not commented out in .hv file.
#Here we assume mm/pixel is the same as the slice thickness)
SliceThickness=`list_image_info $STIRFilename | awk -F: '/Voxel-size in mm / {print $2}'|tr -d '{}'|awk -F, '{print $1}'` 1>&2

## Get the line number to insert the text into. Grep searches through $STIRFilename.
# The 'n tells grep to prefix each matching line with its line number followed by a colon.
# We then cut the colon and select the first field (-f 1) to get the line number.
LineNum=`grep -n "!END OF INTERFILE" $STIRFilename | cut -d : -f 1`

# Add $NumberOfSlices and $SliceThickness at $LineNum
# sed here adds the two line and then echos(saves) into the file $GATEFilename.
# i\ = sed command to insert text before the given line number (before end of interfile)
# input file = $STIRFilename, output = $GATEFilename --> Only $GATEFilename is changed.
sed $LineNum'i\
!number of slices := '$NumberOfSlices'\
slice thickness (pixels) := '$SliceThickness'
' $STIRFilename > $GATEFilename


exit 0
