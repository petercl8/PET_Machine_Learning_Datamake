#! /bin/bash

##### ==============================================================
## Main Changeable Parameters
##### =============================================================

StartFromScratch=1 # Delete all files in ../VoxelisedSimulation before starting your run. This can be useful when running a full XCAT phantom, to save space.
RunGATE=1 # Set to 1 to run the GATE script. This script can be run with or without the main (long simulation time) GATE simulation (set below).
RunSim=1 # Run main GATE simulation? If you set this to zero (but set RunGATE = 1) the code will create the phantoms & run a short GATE simulation to create the attenuation map, but it won't run the main GATE simulation. This is useful if you want to mess with reconstruction parameters for previously simulated phantoms, but you don't want to wait hours for a new simulation to run.
RunUnlist=1 # Unlist ROOT files? This only needs to be done once per QA phantom or XCAT section, unless you switch XCAT sections or phantom type.
RunRecon=1	# Run data corrections and recostructions. You need to have run a simulation and unlisting first.

phantom_type=2 # Generate phantom from: 0 = Simple STIR par file for cylinders (ex: FOV cylinder for sensitivity calculation), 1 = QA Phantom generation (NEMA, etc.), 2 =  XCAT phantom generation
QT=0	 # Enable QT visualization? To check geometry. To visualize: /vis/disable must be commented out in the first line of the GATE main macro.
StartTime=0  # Start time(s) in GATE time
EndTime=60 # For a good CPU, 1 s simulaton takes on the order of 5 min.
TimeSlice=1 # Duration for a single time slice. This should divide evenly into (StartTime-EndTime).
ActivityScaleFactor=21 # Multiply activity in phantom by this scale factor. To double the number of counts in the sinogram, you can either double this scalar, or else double the acquisition time. For equal counts, you will have more randoms with a higher ACtivityScaleFactor.
SaveNiftiFilesToDataset=0 # Set to 0 to only copy interfiles (and possibly ROOT files) to the Phantom Specific Dataset directory. To also copy Nifti versions of the interfiles (that one can opened in 3D Slicer), set to 1.
SaveIntermediateFilesToDataset=0 # Save intermediate files (used in reconstructions, etc.) to dataset. This is useful for debugging.
SaveROOTfilesToDataset=1 # Save ROOT files to dataset? ROOT files can be large, so only save them if you need them.
DatasetDir="/home/peter/dataset3" # Dataset directory. Files are saved in phantom-specific folders in this directory.

## ---------------------
## QA phantom parameters
## ---------------------
QAType="NEMA" # Set to: "NEMA", "Radial", "Axial", "Pinwheel", "SquareStraight", "SquareRotated", or "AttenCheck" --> PhantomFilenameStem=Phantom${QAType}
PhantomSpecificQAFolder=QA-testing # Name of subfolder in DatasetDir to which all QA output files are saved (if phantom_type=1). Therefore, each phantom has it's own data directory. This directory is created, if it doesn't exist already.


## -------------------------------------------------------
## XCAT parameters (can ignore if not using XCAT phantoms)
## -------------------------------------------------------
# Notes:
#	-An average-sized patient (BMI=28) is: male_pt141. This is useful for determining the average activity per section.
#	-The most rotund patient is likely: male_pt184. This is useful to know for setting your voxelized volume size. For this patient:
#		-the largest torso width is approx. 43 cm in diameter.
#		-the largest distance across, when including the arms, is approx. 74 cm.

# PhantomFilenameStem is the beginning of .nrb files (each patient has a specific .nrb file which, when combined with a .par file, produces the phantom.) If not using XCAT, this is set automatically.

#PhantomFilenameStem="male_pt141" # This is an average phantom
#PhantomFilenameStem="male_pt168" # This is the tallest phantom 
#PhantomFilenameStem="male_pt184" # This is the most corpulent phantom.

PhantomFilenameStem="female_pt86"
PhantomSpecificXCATFolder="XCAT_female_pt86" # Name of subfolder in DatasetDir to which all the output files are saved. Each phantom has it's own data directory. This directory is created, if it doesn't exist already.
XCATsections="0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16" # Sections of the XCAT phantom to be simulated. Each section is 47 slices high for the D690 scanner. The sections are numbered starting from the feet (0 = feet, 16 = head). You can choose to simulate only certain sections if you wish. Once you set this variable, the script will loop through each section and simulate them one at a time. If a section above the head is created (which has zero activity), the script will terminate the simulation.
gender="0" #0 = male, 1 = female. This must match the gender of the phantom specified in PhantomFilenameStem.

# XCAT organ activities are made to vary between simulations
# ----------------------------------------------------------
# Percentage variation allowed in activities of XCAT phantom organs. The average will be a clinically determined SUV for the particular organ.
# total_activity_variation = +/- variation allowed in total sum of activities [default: 0.25]. If set to 0.25, the total activity in the phantom will vary between 75% and 125% of the default total activity.
# small_activity_variation = +/- variation allowed in default activities smaller than 10 [default: 0.75]
# large_activity_variation = +/- variation allowed in default activities larger than 10 [default: 0.75]
# organ_symmetry_variation = +/- difference allowed between Left/Right of the same organ (ex. left kidney and right kidney).
# normalize = normalize the XCAT phantom to clinical acquisition activity levels?
total_activity_variation=0.25
small_activity_variation=0.75 # 0.75 # Fractional variation for small activity organs (not diseased).
large_activity_variation=0.75 # 0.75 # Fractional variation for large activity organs (not diseased).
organ_symmetry_variation=0.3 # 0.3  # Fractional variation for symmetrical organs (not diseased).

fraction_diseased=0.9 # Fraction of organs which are diseased.
max_SUV_diseased=17.48 # Maximum SUV for diseased organs. Diseased organs will have random SUVs between max_SUV_diseased and min_SUV_diseased.
min_SUV_diseased=1.49

# Slices at the edge of the axial FOV are worse than in the centre due to a known STIR issue and also due to fewer oblique LORs being present.
# Therefore, We want to overlap sections to ensure that all slices are reconstructed with good data.
overlap=12 # number of slices on either end of the phantom that are run twice. 12 is a good default.
voxelZ=47 # number of z slices per section scanned. voxelZ = num_scanner_rings*2 - 1

## ---------------------
## Persistent Parameters
## ---------------------
# Path to folder holding XCAT executable and config key.
# NRB folder with all phantom .nrb files should be in XCAT folder.
normalize_xcat=0	# We set this equal to 0 because clinical activity levels take a prohibitively long time to run.
which_breast="1" #0 = none, 1 = both, 2 = right only, 3 = left only
XCAT_PATH="/home/peter/software/XCAT" # Path to XCAT software. Update this for your system.
NRB_FOLDER_NAME="xcat_adult_nrb_files" # ${XCAT_PATH}/${NRB_FOLDER_NAME} should lead to the nrb files passed to XCAT for each phantom
ScannerType="D690"  # Selection of scanner from Examples (eg. D690/mMR)
parproj=1 # Variable to enable use of parallelproject (1) or use a ray tracing matrix (0). Parallelproject is faster.
ReplaceAttenMapWithAir=0 # This is useful for examining to what degree scattered & random coincidences contribute to image degradation. If you set this flag to 1, the simulation & reconstruction will run with the attenuation map replaced with air.

UnlistScatteredCoincidences=1  ## Unlist Scattered photon coincidence events (0 or 1)
UnlistRandomCoincidences=1  ## Unlist Random coincidence events (0 or 1)
UnlistDelayedEvents=1 ## Unlist Delayed coincidence event data. This is used in the randoms estimation.

CleanupFiles=0 # Cleanup files at end of reconstruction
GateOutputFilesDirectory=Output  ## Save location for root & unlisted data, etc. Do not change this value.


######==================
## Assignments & Copying
######==================

# Execute the code block only if a variable is passed, which means multiple phantoms are being run.
if [ -n "$1" ]; then
  echo "This script has been called by another script. Assigning the appropriate variables."
	PhantomFilenameStem=$1
	PhantomSpecificXCATFolder=XCAT_"${1}"
fi

# Optionally clear previous files
if [ $StartFromScratch = 1 ]; then 
	find . -maxdepth 1 -type f ! -name "__MAIN_SCRIPT.sh" ! -name "__RunMultiplePhantoms.sh" -delete
fi

GATEMainMacro="MainGATE-${ScannerType}.mac" ## Main macro script for GATE
cp ./GATE/$GATEMainMacro . # Copy main gate macro to this directory.

######==============
## Generate Phantoms
######==============

if [ $phantom_type = 0 ]; then 
	# If using simple cylindrical phantoms generated from STIR .par files.

	# Overwrite XCAT parameters (set above)
	PhantomFilenameStem="cylinder" # Overwrite PhantomFilenameStem. This is used when naming the Additive Sinogram and Multiplicative Factors.
	PhantomSpecificDataFolder="cylinders" # Name of subfolder in Voxelisedsimulation/DatasetDir to which all output files are saved.

	# ====================================
	# === GENERATE 4 HEADERS + 2 IMAGES ==
	#	Input:	.par files
	#	Output:
	#		Activity: 		my_activity_cylidner.ahv, my_activity_cylidner.hv, my_activity_cylinder.v
	#		Attenuation:	my_atten_cylinder.ahv, my_atten_cylinder.hv & my_atten_cylinder.v
	# ====================================
	# -The names of the generated images are found after "/output filename/" in the .par files ("my_atten_cylinder", "my_activity_cylinder")
	# .hv = header for newly proposed version of Interfile
	# .ahv = header which uses Interfile 3.3. with a tweak for slice thickness to work around an Analyze bug. Allows no scale factors but writes with scale factor = 1. Therefore, if writing with float output (and your program reads with float output), everything should be fine.	
	# .v = data file
	ActivityParfilePath=../ExamplePhantoms/STIRparFiles/generate_activity_cylinder.par	# This is currently a regular cylindrical phantom (not FOV phantom for calculating normalization coefficients)
	AttenuationParfilePath=../ExamplePhantoms/STIRparFiles/generate_atten_cylinder.par
	generate_image $ActivityParfilePath
	generate_image $AttenuationParfilePath

	# ===========================================
    # === Create Activity & Attenuation Stems ===
	# -These are found in the *.par files, after "/output filename/"
	# -The filenames are just the prefixes with extensions (.hv, .ahv, .v) added.

	ActivityFilenameStem=$(awk -F:= '/output filename/ { print $2 }' $ActivityParfilePath)
	AttenuationFilenameStem=$(awk -F:= '/output filename/ { print $2 }' $AttenuationParfilePath)

	# ==========================================================
	# === Copy appropriate attenuation map to GATE directory ===
	cp ./GATE/AttenuationMaps/AttenuationConv_TrueScale.dat ./GATE/AttenuationConv.dat

elif [ $phantom_type = 1 ]; then
	# Generate a phantom through STIR (ex. QA phantoms), where a script is used to generate them.
	PhantomFilenameStem=Phantom${QAType} 	# Overwrite PhantomFilenameStem. QAType = Radial, Axial, Pinwheel, or NEMA
	PhantomSpecificDataFolder=$PhantomSpecificQAFolder	# Name of subfolder in DatasetDir to which all output files (from simulation) are saved.

	# =====================================
    # === Generate Phantom Binary Files ===
	ScriptPath=../QAPhantoms/CreatePhantoms/_Create${QAType}.sh
	sh $ScriptPath

	# ===========================================
    # === Create Activity & Attenuation Stems ===
	ActivityFilenameStem=${PhantomFilenameStem}_act
	AttenuationFilenameStem=${PhantomFilenameStem}_atn

	# ==========================================================
	# === Copy appropriate attenuation map to GATE directory ===
	cp ./GATE/AttenuationMaps/AttenuationConv_TrueScale.dat ./GATE/AttenuationConv.dat

else
	# Deal with XCAT phantoms
	#
	# NOTE: While we get the XCAT phantom ready to be generated, we don't generate it here. This is because the phantoms must be generated multiple times
	# 	as we do a full-body scan, section by section. Instead, the binary files are created in _RunGATE.sh.
	#
	# The XCAT attenuation header was originally provided (in STIR-GATE Connection) in /SubScripts/CreateXCATImages. We copied this to make the activity header,
	# 	and modified it for 2.5 mm x2.5 mm x 3.7 mm voxels (or 3x3x3.7).
	# XCAT_phantom header files have been edited to have the correct scaling factors and dimensions for all simulations with the provided full-body phantoms.
	# 	and are now found in ./CopyToParent
	# Extra slices (z dimension) were added to accommodate the tallest phantom while keeping the voxel to mm scaling factor unchanging from phantom to phantom.

	PhantomSpecificDataFolder=$PhantomSpecificXCATFolder # Name of subfolder in DatasetDir to which all output files (from simulation) are saved.
	cp $XCAT_PATH/xcat2.cfg . 	# Copy Valication Key. The .cfg validation key must be in directory you run the script from (VoxelisedSimulation) otherwise XCAT errors occur.

	# ===================================
	# === Deal with XCAT header files ===

	# Copy template header files to the root directory, and rename them in the process.
	# Note: to change the voxel sizes, you must change:
	#	1) the header files (copied below)
	#	2) the .par file used to construct the binary XCAT file. This file is specified in ./SubScripts/ChangeXCATPars.py
	# The scanner is 81 cm wide. For XCAT phantoms, it's recommended to fill this space with a square volume of voxels so that the corners of the
	# 	square volume do not intersect the scanner. Otherwise, artifacts may result.

	ActivityFilenameStem=${PhantomFilenameStem}_act_1
	AttenuationFilenameStem=${PhantomFilenameStem}_atn_1

	#cp ./CopyToParent/XCAT_phantom_act_2p5mmVox.hv ./${ActivityFilenameStem}.hv	
	#cp ./CopyToParent/XCAT_phantom_atn_2p5mmVox.hv ./${AttenuationFilenameStem}.hv
	cp ./CopyToParent/XCAT_phantom_act_3mmVox.hv ./${ActivityFilenameStem}.hv	
	cp ./CopyToParent/XCAT_phantom_atn_3mmVox.hv ./${AttenuationFilenameStem}.hv

	# Edit the copied interfile headers to include the correct name for the generated binary files (generated in _RunGATE.sh).
	sed -i "s/XCAT_phantom/${PhantomFilenameStem}/" ./${ActivityFilenameStem}.hv	
	sed -i "s/XCAT_phantom/${PhantomFilenameStem}/" ./${AttenuationFilenameStem}.hv

	# ===============================================================
	# === Copy appropriate XCAT attenuation map to GATE directory ===
	# We use a simplified attenuation map to speed up simulation time, but there is a more complex .dat file in the AttenuationMaps directory, should you want this.
	cp ./GATE/AttenuationMaps/AttenuationConv_XCATScale-simplified.dat ./GATE/AttenuationConv.dat

fi

if [ $ReplaceAttenMapWithAir = 1 ]; then 
	# This data files assures that, no matter the form of the attenuation map, when translated into gate all materials are replaced with air.
	cp ./GATE/AttenuationMaps/AttenuationConv_AllAir.dat ./GATE/AttenuationConv.dat
fi


#####=============================================
# Make the output directories, if they don't exist
#####=============================================
if [ ! -d $GateOutputFilesDirectory ]; then  	# Does the output directory exist? If not, create the user-defined directory in ./VoxelisedSimulation
	mkdir -p $GateOutputFilesDirectory
fi

if [ ! -d $GateOutputFilesDirectory/images ]; then
	mkdir -p $GateOutputFilesDirectory/images
fi

if [ ! -d $GateOutputFilesDirectory/Unlisted ]; then
	mkdir -p $$GateOutputFilesDirectory/Unlisted
fi


#rm -r $GateOutputFilesDirectory	# If output directory does exist, we remove it first. We save all the necessary data to DatasetDir during each run, so leaving temporary data here as well would just waste storage space.
#mkdir -p $GateOutputFilesDirectory

if [ ! -d "${DatasetDir}/$PhantomSpecificDataFolder" ]; then  # Does the phantom directory exist? If not, create the user-defined directory in ./DatasetDir
	mkdir -p "${DatasetDir}/$PhantomSpecificDataFolder"
fi


##### ===============
## Copy scanner files
##### ===============

# From: ../ExampleScanners:
#	Information for STIR for unlisting ROOT files:	root_header_templet.hroot
#	Sinogram header: 								STIR_scanner.hs
# To:
#	./UnlistingTemplates directory: root_header_templet.hroot, STIR_scanner.hs	
#
# Note: For this project, we've hardcoded the geometry and digitizer in the GATE macro for each scanner.

if [ $ScannerType = "D690" ]; then
	echo "\nPreparing D690 scanner files"
	D690_DIR="../ExampleScanners/D690"
	cp -vp $D690_DIR/root_header_template.hroot UnlistingTemplates/root_header_template.hroot
	cp -vp $D690_DIR/STIRScanner_D690_full_segment.hs UnlistingTemplates/STIR_scanner.hs

elif [ $ScannerType = "mMR" ]; then
	echo "\nPreparing mMR scanner files"
	mMR_DIR="../ExampleScanners/mMR"
	cp -vp $mMR_DIR/root_header_template.hroot UnlistingTemplates/root_header_template.hroot
	cp -vp $mMR_DIR/STIRScanner_mMR_full_segment.hs UnlistingTemplates/STIR_scanner.hs
fi


##### ===============
## Run GATE
##### ===============

## Exports for _RunGATE.sh
## -----------------------

# XCAT-specific exports	
export RunSim total_activity_variation small_activity_variation large_activity_variation organ_symmetry_variation fraction_diseased max_SUV_diseased normalize_xcat

export gender which_breast NRB_FOLDER_NAME PhantomFilenameStem


# General exports

export ActivityScaleFactor

export SaveROOTfilesToDataset SaveNiftiFilesToDataset SaveIntermediateFilesToDataset 

export DatasetDir PhantomSpecificDataFolder # Dataset

export ActivityFilenameStem AttenuationFilenameStem

export phantom_type XCAT_PATH  # Phantom parameters

export QT StartTime EndTime TimeSlice GATEMainMacro	# GATE parameters

export GateOutputFilesDirectory 	# Output directory and output filename of root file from GATE.

export UnlistScatteredCoincidences UnlistRandomCoincidences UnlistDelayedEvents	# Flags for unlisting

export overlap voxelZ	# Important slice numbers

export parproj ScannerType CleanupFiles

# SectionNum is appended to every output file from the GATE simulation.
# This loop exists to run through multiple sections of a single XCAT phantom, so that you just have to run this main script once per whole body.
# However, SectionNum can be any character or word for non-XCAT phantoms - it's just an identifier.
# If running an XCAT phantom:
# 	"Sections" must be a series of numbers. (ex. 0 1 2 3 4 5 ... 15).
# 	The slices are selected starting at the feet. You can also run only certain sections; normally sections 8-10 include high activity organs.
# 	To find the exact number of slices for a phantom, you'd take the height of the person (in cm, found in _XCAT_phantom_titles.ods), and divide by 
#	the scaling factor (3.27 mm/pixel for the D-690). The scaling factor is specified in XCAT_phantom_act_1.hv (the template header for XCAT activity 	
#	phantom intefile)


if [ $phantom_type = 2 ]; then
	Sections=$XCATsections
else
	Sections=$PhantomFilenameStem # For non-XCAT phantoms, we just run one section named after the phantom.
fi

for SectionNum in $Sections; do
	RunScripts=1

	if  [ $RunGATE = 1 ] && [ $phantom_type = 2 ] ; then
		sh ./SubScripts/_CreateXCAT.sh $SectionNum	# Creates an XCAT phantom. If the activity region is zero (you've gone past the head), it returns an exit code of 0.
		RunScripts=$?
	fi

	if [ $RunScripts = 1 ] ; then

		if [ $RunGATE = 1 ] ; then
			echo "GATE started: " $(date +%d.%m.%y-%H:%M:%S:%) >> "${DatasetDir}/${PhantomSpecificDataFolder}/AAA-RunLog_${PhantomFilenameStem}.txt"
			sh ./SubScripts/_RunGATE.sh $SectionNum
			echo "GATE finished: " $(date +%d.%m.%y-%H:%M:%S:%) >> "${DatasetDir}/${PhantomSpecificDataFolder}/AAA-RunLog_${PhantomFilenameStem}.txt"
		fi

		if [ $RunUnlist = 1 ] ; then
			# Reconstruct each section of the phantom
			sh ./SubScripts/_UnlistPromptsAndDelayeds.sh $SectionNum 
		fi

		if [ $RunRecon = 1 ] ; then
			# Reconstruct each section of the phantom
			sh ./SubScripts/_CorrectAndReconstruct.sh $SectionNum 
		fi
	fi
done

echo "Script finished: " $(date +%d.%m.%y-%H:%M:%)

exit 0