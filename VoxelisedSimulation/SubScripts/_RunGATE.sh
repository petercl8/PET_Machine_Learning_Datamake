#! /bin/sh

SectionNum=$1
ROOT_FILENAME_PREFIX=Sim_${SectionNum}


##### ==================================
## Create files for GATE simulation
##### ==================================

# === GENERATE 6 HEADERS + 2 IMAGES ===
#	Input: .hv header files (+ .v or .bin data files), NOTE: These were created in __MAIN_SCRIPT.sh
#	Output:
#	 	Activity:	$ActivityFilenameStem"_GATE".ahv,   $ActivityFilenameStem"_GATE".hv,    $ActivityFilenameStem"_GATE".v,    ActivityFilenameStem"_GATE".h33
#		Attenuation:$AttenuationFilenameStem"_GATE".ahv,$AttenuationFilenameStem"_GATE".hv,	$AttenuationFilenameStem"_GATE".v, $AttenuationFilenameStem"_GATE".h33
# =====================================

## Create names for the GATE versions of these files. ##
ActivityFilenameStemGATE=$ActivityFilenameStem"_GATE"
AttenuationFilenameStemGATE=$AttenuationFilenameStem"_GATE"

## Perform scalar multiplication --> create *_GATE.ahv, *_GATE.hv, *_GATE.v ##
#  "--including-first" means the input (e.g. ActivityFilenameStem.hv + datafile) and the output (e.g. ActivityFilenameStemGATE.hv + datafile) 
# 	are multiplied by the scalar. The output are two files (one header, one data) identical to the inputs (now multiplied) but with different names. 
#	Stir_math also creates a .ahv file for both input & output, yeilding six files in total.

stir_math --including-first --times-scalar $ActivityScaleFactor $ActivityFilenameStemGATE".hv" $ActivityFilenameStem".hv" # Here we change the name of the file and also, by using stir_math, the extension of the data file is changed from .bin to .v

stir_math --including-first --times-scalar 10000 $AttenuationFilenameStemGATE".hv" $AttenuationFilenameStem".hv" # Modify the scale of the attenuation file for GATE. This guaranties that the file has integers. GATE won't accept decimals when mapping to materials.


## Create .h33 from .hv headers
#	To do this, we read in a couple of lines from the *.hv files and add the fields: 
#	    "!number of slices :=" and "slice thickness (pixels) :=".
#   This process only alters header files.
sh ./SubScripts/_STIR2GATE_interfile.sh $ActivityFilenameStem".h33" $ActivityFilenameStem".hv"
sh ./SubScripts/_STIR2GATE_interfile.sh $ActivityFilenameStemGATE".h33" $ActivityFilenameStemGATE".hv"

sh ./SubScripts/_STIR2GATE_interfile.sh $AttenuationFilenameStem".h33" $AttenuationFilenameStem".hv" 
sh ./SubScripts/_STIR2GATE_interfile.sh $AttenuationFilenameStemGATE".h33" $AttenuationFilenameStemGATE".hv" 

# ===========================================================================================
# Copy phantom activity and attenuation maps (before sending to GATE) to the Dataset Directory
# ===========================================================================================

### Copy ground truth XCAT activity maps to DatasetDir.

if [ $RunSim = 1 ]; then
	cp $ActivityFilenameStemGATE".h33" "${DatasetDir}/${PhantomSpecificDataFolder}/act_map_toGATE_${SectionNum}.h33"
	cp $ActivityFilenameStemGATE".v" "${DatasetDir}/${PhantomSpecificDataFolder}/act_map_toGATE_${SectionNum}.v"
	# Edit the copied header to point to the correct binary file (now that we've changed the name).
	sed -i "s/.*GATE.*/name of data file := act_map_toGATE_${SectionNum}.v/" "${DatasetDir}/${PhantomSpecificDataFolder}/act_map_toGATE_${SectionNum}.h33"

	if [ $SaveNiftiFilesToDataset = 1 ]; then
		medcon -f $ActivityFilenameStemGATE".h33" -c nifti -w
		cp "m000-${ActivityFilenameStemGATE}.nii" "${DatasetDir}/${PhantomSpecificDataFolder}/act_map_toGATE_${SectionNum}.nii"
	fi

	if [ $SaveIntermediateFilesToDataset = 1 ]; then
		if [ $SaveNiftiFilesToDataset = 1 ]; then
		# Create nifti files (that can be read in slicer) and copy to DatasetDir.
		medcon -f $ActivityFilenameStem".h33" -c nifti -w
		cp "m000-${ActivityFilenameStem}.nii" "${DatasetDir}/${PhantomSpecificDataFolder}/act_map_prescaled_${SectionNum}.nii"

		medcon -f $AttenuationFilenameStem".h33" -c nifti -w
		cp "m000-${AttenuationFilenameStem}.nii" "${DatasetDir}/${PhantomSpecificDataFolder}/atten_map_prescaled_${SectionNum}.nii"

		medcon -f $AttenuationFilenameStemGATE".h33" -c nifti -w
		cp "m000-${AttenuationFilenameStemGATE}.nii" "${DatasetDir}/${PhantomSpecificDataFolder}/atten_map_scaled_${SectionNum}.nii"
		fi
	fi
fi

##### ===========================================
## Create GATE distance map using GATE simulation
##### ===========================================

# The Dmap is required for our specific type of parametrization, which is the most efficient for our phantoms.

# === GENERATE 2 FILES =========================
#	Inputs:	GATE attenuation .h33 header + the associated data file (.v or .bin)
#			GateOutputFilesDirectory
#	Outputs: dmap.hdr, dmap.img
#		-Saved to: GateOutputFilesDirectory/images/
# ==============================================

# Create a couple of shortcut filenames
ActivityFilenameH33=$ActivityFilenameStemGATE".h33"
AttenuationFilenameH33=$AttenuationFilenameStemGATE".h33"

## Run a very short simulation to setup and save dmap.hdr & dmap.img.
Gate GATE/SetupDmap.mac -a [AttenuationFilename,$AttenuationFilenameH33][GateOutputFilesDirectory,$GateOutputFilesDirectory]

##### ====================================================================
## Get GATE activity source position (x,y,z) from image interfile header.
##### ====================================================================

# Position GATE input geometry correctly, since the origins in STIR/XCAT and GATE are at different places.

FirstEdges=$(list_image_info $ActivityFilenameH33| awk -F: '/Physical coordinate of first edge in mm/ {print $2}'|tr -d '{}'|awk -F, '{print $3, $2, $1}') 1>&2
LastEdges=$(list_image_info $ActivityFilenameH33| awk -F: '/Physical coordinate of last edge in mm/ {print $2}'|tr -d '{}'|awk -F, '{print $3, $2, $1}') 1>&2

## Compute x,y
SourcePositionX=$(echo "$FirstEdges" | awk '{print $1}')
SourcePositionY=$(echo "$FirstEdges" | awk '{print $2}')

## Compute z = -(lz-fz)/2
FirstEdgeZ=$(echo "$FirstEdges" | awk '{print $3}')
LastEdgeZ=$(echo "$LastEdges" | awk '{print $3}')
SourcePositionZ=$(echo "$FirstEdgeZ $LastEdgeZ" | awk '{print -($2-$1)/2}')


##########
## Get attenuation map translation in x,y,z
##########

## Get first and last edge positions
FirstEdges=$(list_image_info $AttenuationFilenameH33| awk -F: '/Physical coordinate of first edge in mm/ {print $2}'|tr -d '{}'|awk -F, '{print $3, $2, $1}') 1>&2
LastEdges=$(list_image_info $AttenuationFilenameH33| awk -F: '/Physical coordinate of last edge in mm/ {print $2}'|tr -d '{}'|awk -F, '{print $3, $2, $1}') 1>&2


## Extract x,y first and last edges
FirstEdgeX=$(echo "$FirstEdges" | awk '{print $1}')
LastEdgeX=$(echo "$LastEdges" | awk '{print $1}')
FirstEdgeY=$(echo "$FirstEdges" | awk '{print $2}')
LastEdgeY=$(echo "$LastEdges" | awk '{print $2}')

## Compute Translation
AttenuationTranslationX=$(echo "$FirstEdgeX $LastEdgeX" | awk '{print ($1+$2)/2}')
AttenuationTranslationY=$(echo "$FirstEdgeY $LastEdgeY" | awk '{print ($1+$2)/2}')
AttenuationTranslationZ=0.  ## Z translation should be zero.


#########
## Get voxel number & sizes
#########

## Get the number of voxels in x,y,z (get_num_voxels.sh is found: $STIRINSTALLPATH/bin/get_num_voxels.sh)
NumberOfVoxels=$( get_num_voxels.sh $AttenuationFilenameH33 2>/dev/null ) 
NumberOfVoxelsX=$(echo "${NumberOfVoxels}" |awk '{print $1}')
NumberOfVoxelsY=$(echo "${NumberOfVoxels}" |awk '{print $2}')
NumberOfVoxelsZ=$(echo "${NumberOfVoxels}" |awk '{print $3}')


## Get the voxel size in x,y,z (stir_print_voxel_sizes.sh is found: $STIRINSTALLPATH/bin/stir_print_voxel_sizes.sh)
AttenuationVoxelSize=$( stir_print_voxel_sizes.sh $AttenuationFilenameH33 2>/dev/null ) 
## stir_print_voxel_sizes returns z,y,x, these are reversed here
AttenuationVoxelSizeX=$(echo "${AttenuationVoxelSize}" |awk '{print $3}')
AttenuationVoxelSizeY=$(echo "${AttenuationVoxelSize}" |awk '{print $2}')
AttenuationVoxelSizeZ=$(echo "${AttenuationVoxelSize}" |awk '{print $1}')

##### ==============================================================
## RunGATE
##### ==============================================================

# === GENERATE 6 FILES ===
#	In GateOutputFilesDirectory:
#		$ROOT_FILENAME_PREFIX.Coincidences.root
#		$ROOT_FILENAME_PREFIX.Delayed.root
#		digit_summary_tests.txt		(log file)
#	GateOutputFilesDirectory/images
#		Phantom[$SectionNum]-MuMap.hdr + Phantom[$SectionNum]-MuMap.img
#		Phantom[$SectionNum]-SourceMap.hdr + Phantom[$SectionNum]-Sourcemap.img
#==========================


if [ "$RunSim" -eq 0 ]; then
	echo "Not running simulation!"
else

if [ $QT -eq 1 ]; then

	echo "Running Gate with visualisation."
	Gate --qt $GATEMainMacro -a \
[SimuId,$SectionNum][ROOT_FILENAME_PREFIX,$ROOT_FILENAME_PREFIX]\
[StartTime,$StartTime][EndTime,$EndTime][TimeSlice,$TimeSlice]\
[GateOutputFilesDirectory,$GateOutputFilesDirectory]\
[NumberOfVoxelsX,$NumberOfVoxelsX][NumberOfVoxelsY,$NumberOfVoxelsY][NumberOfVoxelsZ,$NumberOfVoxelsZ]\
[ActivityFilename,$ActivityFilenameH33][AttenuationFilename,$AttenuationFilenameH33]\
[SourcePositionX,$SourcePositionX][SourcePositionY,$SourcePositionY][SourcePositionZ,$SourcePositionZ]\
[AttenuationTranslationX,$AttenuationTranslationX][AttenuationTranslationY,$AttenuationTranslationY][AttenuationTranslationZ,$AttenuationTranslationZ]\
[AttenuationVoxelSizeX,$AttenuationVoxelSizeX][AttenuationVoxelSizeY,$AttenuationVoxelSizeY][AttenuationVoxelSizeZ,$AttenuationVoxelSizeZ]

else

	echo "Running Gate."
	Gate $GATEMainMacro -a \
[SimuId,$SectionNum][ROOT_FILENAME_PREFIX,$ROOT_FILENAME_PREFIX]\
[StartTime,$StartTime][EndTime,$EndTime][TimeSlice,$TimeSlice]\
[GateOutputFilesDirectory,$GateOutputFilesDirectory]\
[NumberOfVoxelsX,$NumberOfVoxelsX][NumberOfVoxelsY,$NumberOfVoxelsY][NumberOfVoxelsZ,$NumberOfVoxelsZ]\
[ActivityFilename,$ActivityFilenameH33][AttenuationFilename,$AttenuationFilenameH33]\
[SourcePositionX,$SourcePositionX][SourcePositionY,$SourcePositionY][SourcePositionZ,$SourcePositionZ]\
[AttenuationTranslationX,$AttenuationTranslationX][AttenuationTranslationY,$AttenuationTranslationY][AttenuationTranslationZ,$AttenuationTranslationZ]\
[AttenuationVoxelSizeX,$AttenuationVoxelSizeX][AttenuationVoxelSizeY,$AttenuationVoxelSizeY][AttenuationVoxelSizeZ,$AttenuationVoxelSizeZ]
fi

fi
echo ==============================================================
echo Copy GATE attenuation and source maps to DatasetDir
echo ==============================================================

### Convert GATE attenuation and source maps (.hdr formats) to intefile formats. Then conver the MuMap to a format that is readable by STIR (.hv)
# This is used in the image reconstruction process.
sh ../Analysis/_convert_hdr_to_hv.sh "./${GateOutputFilesDirectory}/images/Phantom${SectionNum}-MuMap.hdr" ${SectionNum} "./${GateOutputFilesDirectory}/images/Phantom${SectionNum}-SourceMap.hdr"

# Copy attenuation map to DatasetDir.
cp "m000-Phantom${SectionNum}-MuMap.h33" "${DatasetDir}/${PhantomSpecificDataFolder}/atten_map_fromGATE_${SectionNum}.h33"
cp "m000-Phantom${SectionNum}-MuMap.i33" "${DatasetDir}/${PhantomSpecificDataFolder}/atten_map_fromGATE_${SectionNum}.v"
sed -i "s/.*m000.*/!name of data file := atten_map_fromGATE_${SectionNum}.v/" "${DatasetDir}/${PhantomSpecificDataFolder}/atten_map_fromGATE_${SectionNum}.h33"

# Copy source source map to DatasetDir 
cp "m000-Phantom${SectionNum}-SourceMap.h33" "${DatasetDir}/${PhantomSpecificDataFolder}/anni_map_fromGATE_${SectionNum}.h33"
cp "m000-Phantom${SectionNum}-SourceMap.i33" "${DatasetDir}/${PhantomSpecificDataFolder}/anni_map_fromGATE_${SectionNum}.v"
sed -i "s/.*m000.*/!name of data file := anni_map_fromGATE_${SectionNum}.v/" "${DatasetDir}/${PhantomSpecificDataFolder}/anni_map_fromGATE_${SectionNum}.h33"

# Create nifti files (that can be read in slicer) and copy these to DatasetDir
if [ $SaveNiftiFilesToDataset = 1 ]; then
	medcon -f "m000-Phantom${SectionNum}-SourceMap.h33" -c nifti -w
	medcon -f "m000-Phantom${SectionNum}-MuMap.h33" -c nifti -w
	cp "m000-m000-Phantom${SectionNum}-SourceMap.nii" "${DatasetDir}/${PhantomSpecificDataFolder}/anni_map_fromGATE_${SectionNum}.nii"
	cp "m000-m000-Phantom${SectionNum}-MuMap.nii" "${DatasetDir}/${PhantomSpecificDataFolder}/atten_map_fromGATE_${SectionNum}.nii"
fi

##### ==============================================================
## Deal with ROOT Files
##### ==============================================================

if [ ${SaveROOTfilesToDataset} = 1 ]; then
	cp "./Output/Sim_${SectionNum}.Coincidences.hroot" "${DatasetDir}/${PhantomSpecificDataFolder}/Sim_${SectionNum}.Coincidences.hroot"
	cp "./Output/Sim_${SectionNum}.Coincidences.root" "${DatasetDir}/${PhantomSpecificDataFolder}/Sim_${SectionNum}.Coincidences.root"
	cp "./Output/Sim_${SectionNum}.Delayed.hroot" "${DatasetDir}/${PhantomSpecificDataFolder}/Sim_${SectionNum}.Delayed.hroot"
	cp "./Output/Sim_${SectionNum}.Delayed.root" "${DatasetDir}/${PhantomSpecificDataFolder}/Sim_${SectionNum}.Delayed.root"
fi

echo "Script _RunGATEandUnlist.sh finished running at: $(date +%T)"