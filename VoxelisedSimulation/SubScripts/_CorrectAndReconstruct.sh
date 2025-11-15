#! /bin/sh
## When expeimenting with different correction or reconstruction parameters, you can set some of the flags below to zero. This will save some time if if it's not the thing you're messing with.

CalcRandoms=1
CalcAttenMap=1
CalcACFs=1
CalcNormSino=1
CalcScatter=1
CalcPrecorrect=1 # 0 = don't run precorrection (leaves any written data alone), 1 = run precorrection using STIR utility, 2 = run precorrection using a simple subtraction & multiplication of sinograms, 3 = don't run precorrrection and set the "precorrected data" equal to the prompt sinogram. This is useful for seeing the difference that corrections make.
CalcFORE=1
ReconFORE=1
ReconOblique=1
SaveFilesToDataset=1

GlobalAttenScaleFactor=1	# You can vary this and check to see how well the attenuatio correction is working (0.87 seems best for AttenCheck QA phantom).
RandomsScaleFactor=0.635        # 0.635 is required to match it with empirical results (no idea why)

## These variables change for each XCAT section run
SectionNum=$1
ROOT_FILENAME_PREFIX=Sim_${SectionNum}
atnimg_fromGATE=m000-Phantom${SectionNum}-MuMap.hv


## SETUP of variables: No need to change stuff here, setup for exports and files will be deleted with cleanup
# These files are created and used by STIR. Changing them could cause problems in .par files.
acf3d_scatter=my_attenuation_coefficients_scatter.hs
acf3d=my_attenuation_coefficients.hs
scatter_prefix=my_scatter
total_additive_prefix=my_total_additive
mask_image=my_mask
mask_projdata_filename=my_sino_mask
randoms3d_prefix=my_randoms
randoms3d=${randoms3d_prefix}.hs
factors=singles_from_delayed
atnimg=atnimg_toSTIR.hv
atnimg_scatter=my_atten_image_scatter.hv

## Assignments based on previously defined variables:
prompt_sinogram="${GateOutputFilesDirectory}/Unlisted/Coincidences/Sino_${ROOT_FILENAME_PREFIX}.hs" # The unlisted coincidences sinogram (*.hs)
delayed_sinogram="${GateOutputFilesDirectory}/Unlisted/Delayed/Sino_${ROOT_FILENAME_PREFIX}.hs" # The unlisted delayeds sinogram filename (*.hs)

# Output filename of the multiplicative factors and additive sinogram
OutputMultiplicativeSinogramHS="${PhantomFilenameStem}_Mult_${SectionNum}.hs"
OutputAdditiveSinogramFilenameHS="${PhantomFilenameStem}_Add_${SectionNum}.hs"
OutputScatterSinogramFilenameHS="${PhantomFilenameStem}_Scatter_${SectionNum}.hs"

echo "==========================="
echo "Calculate Randoms"
echo "==========================="

if [ $CalcRandoms = 1 ]; then
	num_randoms_iters=10 # [Default (SGC): 10]

	#Find singles (and hence randoms) from delayed events using an ML approach. 
	find_ML_singles_from_delayed ${factors} ${delayed_sinogram} ${num_randoms_iters} < /dev/null # /dev/null tells to not expect input. ${factors} is the output.
	construct_randoms_from_singles ${randoms3d} ${factors} ${delayed_sinogram} ${num_randoms_iters} #Construct ${randoms3d} from singles estimate.
	stir_math -s --accumulate --including-first --times-scalar ${RandomsScaleFactor} ${randoms3d}

fi

echo "========================================="
echo "Alter Attenuation Map?"
echo "========================================="

if [ $CalcAttenMap = 1 ]; then

	###########
	### Manipulate the attenuation map from GATE
	###########

	# According to the original STIR-GATE Connection, GATE outputs with an offset and inverted z axis, and therefore you must invert the attenuation
	# map using a STIR utility. However, we found this to be unnecessary and so this code is disabled.
	# To double check this for yourself, reconstruct images using the AttenCheck QA phantom. It should be obvious whether or not you need to invert
	# the attenuation map along the z-axis. If you do, change the if statement below so it inverts. This code inverts the attenuation map that is used by STIR
	# for reconstructions. It does not invert the original file ouput by GATE. This way, you can run as many reconstructions as you like using the original
	# STIR output files, without fear these are being altered by this script.

	atnimg_invert="atten_map_invert.hv"	# This variable is only used here, so it is not defined at the beginning of the script.

	if [ "$phantom_type" = 3 ] || [ "$phantom_type" = 3 ]; then
		# Invert the z axis
		invert_axis y $atnimg_invert $atnimg_fromGATE		# invert_axis z <output_image> <input_image> 
		echo "Inverting attenuation map about y axis"
	else
		# Rename image, but don't invert.
		stir_math --including-first --times-scalar 1 $atnimg_invert $atnimg_fromGATE # Merely copies $atnimg_fromGATE to a new filename. This is so that if you change reconstruction parameters, the original attenuation map is left unchanged.
		echo "Not inverting attenuation map about Z axis"
	fi

	# Scale the attenuation map. Use reconstruct AttenCheck QA phantom to experimentally determine a good value for $AttenuationScaleFactorForRecon. 
	#stir_math --accumulate --including-first --times-scalar ${AttenuationScaleFactorForRecon} ${atnimg}

	stir_math --including-first --times-scalar ${GlobalAttenScaleFactor} ${atnimg} ${atnimg_invert}

	# Optionally copies the altered attenuation map to the dataset directory. NOTE: if the attenuation map has been reflected along the z-axis this will NOT show up when viewing in 3D Slicer. No idea why.
	if [ $SaveIntermediateFilesToDataset = 1 ]; then
		medcon -f $atnimg -c nifti -w
		cp "m000-atnimg_toSTIR.nii" "${DatasetDir}/${PhantomSpecificDataFolder}/atten_map_toSTIR_${SectionNum}.nii"
	fi
fi

echo "========================================"
echo "Compute Attenuation Correction Factors"
echo "========================================"

if [ $CalcACFs = 1 ]; then
	# Calculates attenuation coefficients (as an alternative to correct_projdata)
	# –ACF calculates the attenuation correction factors, –AF calculates the attenuation factor (i.e. the reciprocal of the ACFs).
	# in cm-1
	# <output filename > <input image file name> <template_proj_data>


	echo "Compute attenuation coefficient factors"
	calculate_attenuation_coefficients --ACF ${acf3d} ${atnimg} ${prompt_sinogram} # The ACFs are in sinograms with dimensions determined by scanner geometry.
fi


echo "========================================="
echo "Normalization Sinogram"
echo "========================================="

# Normalisation depends on the projector used, and must use the same projector as the image reconstruction
# The files below are output from DataCorrectionsComputation/EstimateGATESTIRNorm (*.hs)
# They use an activity scan to compute the normalization sinograms, and you only need to run this once for each scanner geometry and projector used.
# Normalization scans for the D690 are in the NormalisationInterfiles folder.

if [ $parproj = 1 ]; then
	normalization_sinogram="./NormalisationInterfiles/parallelproj_D690.hs"
else
	normalization_sinogram="./NormalisationInterfiles/ray_tracing_D690.hs"
fi

# multiplies normalization_sinogram and attn coeffs and outputs.
# -s tells STIR that it's projection data, otherwise it assumes it's image data

if [ $CalcNormSino = 1 ]; then
	echo "Creating Multiplicative Factors: ${OutputMultiplicativeSinogramHS}"
	stir_math -s --mult ${OutputMultiplicativeSinogramHS} ${normalization_sinogram} ${acf3d}
fi

echo "========================================="
echo "Estimate scatter. This takes time..."
echo "========================================="

num_scat_iters=5 # Default: 5 [[Number of iterations for scatter estimation. Usually 2-3 is adequate]
scatter_recon_num_subiterations=10 # Default: 10 [Default value from original STIR-GATE Connection (SGC) was 18, though no justification was given]
scatter_recon_num_subsets=9 # Default: 9 [Default (SGC): 18.]
scatter_sinogram="${scatter_prefix}_${num_scat_iters}.hs"
total_additive_sinogram="${total_additive_prefix}_${num_scat_iters}.hs"

if [ $CalcScatter = 1 ]; then

	# These values cannot be arbitrarily set, but are related to each other. See STIR documentation. We chose these values to give good iterative reconstructions.

	current_dir=$(pwd)            # Get the current directory
	scatter_pardir="$current_dir/OurParFiles/ScatterCorrection" # Append the subdirectory to the current directory
	template_projdata_path="$current_dir/NormalisationInterfiles/parallelproj_D690.hs"

	## Outputs
	export total_additive_prefix scatter_prefix
	## Input data
	export prompt_sinogram atnimg normalization_sinogram acf3d randoms3d scatter_pardir template_projdata_path
	## Scatter simulation arguments
	export num_scat_iters scatter_recon_num_subiterations scatter_recon_num_subsets
	## mask filenames (not yet assigned to data)
	export mask_projdata_filename mask_image

	rm scatter_activity_estimate* # remove files about to be copied below
	cp ./CopyToParent/scatter_activity_estimate_0.hv . # This is a blank image of zeros which serves as the first estimate of the activity for scatter correction later.
	cp ./CopyToParent/scatter_activity_estimate_0.v .
	cp ./CopyToParent/scatter_activity_estimate_1.hv . # This is a blank image of 1s which serves as the first estimate of the activity for scatter correction later.
	cp ./CopyToParent/scatter_activity_estimate_1.v .

	# Compute scatter and additive sinogram
	# Outputs AdditiveSinogram (randoms and scatter) and scatter (scatter only, deleted during cleanup)

	estimate_scatter ./OurParFiles/ScatterCorrection/scatter_estimation.par

	# Rename total additive sinogram to the OutputAdditiveSinogramFilename
	# doesn't do any math - just renames from temp files
	# NOTE: the scatter correction already takes into account the normalization_sinogram sinogram.

	if [ $SaveIntermediateFilesToDataset = 1 ]; then
		medcon -f "./extras/recon_1.hv" -c nifti -w
		medcon -f "./extras/recon_2.hv" -c nifti -w
		medcon -f "./extras/recon_3.hv" -c nifti -w
		medcon -f "./extras/recon_4.hv" -c nifti -w
		medcon -f "./extras/recon_5.hv" -c nifti -w
		cp m000-recon_1.nii "${DatasetDir}/${PhantomSpecificDataFolder}/scatter_recon_estimate_1.nii"
		cp m000-recon_2.nii "${DatasetDir}/${PhantomSpecificDataFolder}/scatter_recon_estimate_2.nii"
		cp m000-recon_3.nii "${DatasetDir}/${PhantomSpecificDataFolder}/scatter_recon_estimate_3.nii"
		cp m000-recon_4.nii "${DatasetDir}/${PhantomSpecificDataFolder}/scatter_recon_estimate_4.nii"
		cp m000-recon_5.nii "${DatasetDir}/${PhantomSpecificDataFolder}/scatter_recon_estimate_5.nii"

		medcon -f ${mask_image} -c nifti -w
		cp m000-${mask_image}.nii "${DatasetDir}/${PhantomSpecificDataFolder}/scatter_mask.nii"
	fi

stir_math -s --including-first --times-scalar 1 ${OutputAdditiveSinogramFilenameHS} "${total_additive_prefix}_${num_scat_iters}.hs"
stir_math -s --including-first --times-scalar 1 ${OutputScatterSinogramFilenameHS} "${scatter_prefix}_${num_scat_iters}.hs"
fi



echo "========================================="
echo "Data Precorrection"
echo "========================================="

if [ "$CalcPrecorrect" -ne 0 ]; then

	if [ $CalcPrecorrect = 1 ]; then
		#stir_math -s "ScatterSinogram.hs" ${OutputScatterSinogramFilenameHS} ${randoms3d}
		#stir_math -s --accumulate --including-first --times-scalar 0 --add-scalar 1 ${OutputMultiplicativeSinogramHS}
		#stir_math -s --accumulate --including-first --times-scalar 0 ${OutputAdditiveSinogramFilenameHS}
		export prompt_sinogram PhantomFilenameStem OutputMultiplicativeSinogramHS OutputAdditiveSinogramFilenameHS
		correct_projdata ./OurParFiles/correct_projdata.par
	fi

	if [ $CalcPrecorrect = 2 ]; then
		stir_math -s --including-first --times-scalar 1 mult_scaled.hs ${OutputMultiplicativeSinogramHS}
		stir_math -s scatter_plus_randoms.hs ${randoms3d} ${scatter_sinogram}
		stir_math -s --times-scalar -1 prompts_minus_additive.hs ${prompt_sinogram} scatter_plus_randoms.hs
		stir_math -s --mult ${PhantomFilenameStem}_precorrected.hs mult_scaled.hs prompts_minus_additive.hs
	fi

	if [ $CalcPrecorrect = 3 ]; then
		stir_math -s --including-first --times-scalar 1 ${PhantomFilenameStem}_precorrected.hs ${prompt_sinogram}
	fi

stir_math -s --including-first --times-scalar 1 precorrected_for_oblique.hs ${PhantomFilenameStem}_precorrected.hs
stir_math -s --including-first --times-scalar 1 precorrected_for_FORE.hs ${PhantomFilenameStem}_precorrected.hs

fi
precorrected_for_oblique=precorrected_for_oblique.hs
precorrected_for_FORE=precorrected_for_FORE.hs


echo "========================================="
echo "Fourier Rebinning"
echo "========================================="

rebinned_filename="${PhantomFilenameStem}_rebinned_${SectionNum}"

export precorrected_for_FORE rebinned_filename # Exporting unlisted coincidences sinogram filename and output filename for the FORE parameter file

if [ $CalcFORE = 1 ]; then
	# Fourier Rebinning is done through a parameter file
	# Example parameter file in STIR user's guide

	# Three different acceptance angles/ring differences are used for rebinning:
	# The maximum ring difference for the D690 (23), half, and a quarter of the maximum.

	acceptance_angle=23
	count_label="high"
	export acceptance_angle count_label
	rebin_projdata ./OurParFiles/FORE.par
	bash ./SubScripts/ExtractSegments/extract_rebinned_segments.sh $rebinned_filename $PhantomSpecificDataFolder $SectionNum $count_label

	acceptance_angle=$(($acceptance_angle / 2))
	count_label="med"
	export acceptance_angle count_label
	rebin_projdata ./OurParFiles/FORE.par
	bash ./SubScripts/ExtractSegments/extract_rebinned_segments.sh $rebinned_filename $PhantomSpecificDataFolder $SectionNum $count_label

	acceptance_angle=$(($acceptance_angle / 2))
	count_label="low"
	export acceptance_angle count_label
	rebin_projdata ./OurParFiles/FORE.par
	bash ./SubScripts/ExtractSegments/extract_rebinned_segments.sh $rebinned_filename $PhantomSpecificDataFolder $SectionNum $count_label
fi


##### ==============================================================
## Image Reconstruction
##### ==============================================================

# We use the OSEM script and .par file from ExampleReconstruction (original STIR-GATE Connection)
# NumSubsets must be a divisor of the number of views (512 views for rebinned data, 576 for non-rebinned) (multiples of two work).
# 	Note: for default projectors (not ray tracing or parallelproject, which we use) the number of views must be a multiple of NumSubsets * 4


echo "========================================="
echo "Reconstruct rebinned data"
echo "========================================="

# These parameters were chosen to optimize image quality
NumSubsets=8
NumSubiterations=40

NumSubiterationsFORE=$NumSubiterations # This used later for copying to the dataset
# Set corrections sinogram names. Corrections have been applied so these only have to be sinograms of ones and zeroes with the right size.
MultFactors=./OnesSinogramFORE.hs		# This sinogram is created below. This variable is used by OSEM_ParallelprojFORE.par
AdditiveSinogram=./EmptySinogramFORE.hs # This sinogram is created below. This variable is used by OSEM_ParallelprojFORE.par

export NumSubsets NumSubiterations SectionNum AdditiveSinogram MultFactors

if [ $ReconFORE = 1 ]; then

	for count_label in "low" "med" "high"; do
	#for count_label in "high"; do
		InputSinogram="${rebinned_filename}_${count_label}.hs" # Rebinned data, created above.

		# Different ring differences need different sized sinograms. These must be re-generated for each rebinned sinogram reconstruction.
		# Make the zeroes/ones sinogram the size of the rebinned sinogram.

		# Create a sinogram full of zeros
		stir_math -s --including-first --times-scalar 0 EmptySinogramFORE.hs "${InputSinogram}"
		# Create a sinogram full of ones
		stir_math -s --including-first --times-scalar 0 --add-scalar 1 OnesSinogramFORE.hs "${InputSinogram}"

		# Export variables for the parameter files
		export InputSinogram count_label

		if [ $parproj = 1 ]; then
			#FBP2D ./OurParFiles/FBP2D.par
			OSMAPOSL ./OurParFiles/OSEM_parallelprojFORE.par # Requires variables: NumSubsets, NumSubiterations, SectionNum, AdditiveSinogram, MultFactors, InputSinogram
		else
			OSMAPOSL ./OurParFiles/OSEM_ray_tracingFORE.par # Requires variables: NumSubsets, NumSubiterations, SectionNum, AdditiveSinogram, MultFactors, InputSinogram
		fi

		echo "Image reconstruction complete! Image saved in ${DatasetDir}/${PhantomSpecificDataFolder} as 'rebin_image_${count_label}CountImage_${SectionNum}'"

		# Copy final OSEM iteration to DatasetDir folder and rename
		cp "OSEM_${PhantomFilenameStem}_${SectionNum}_${count_label}_FORE_${NumSubiterationsFORE}.hv" "${DatasetDir}/${PhantomSpecificDataFolder}/rebin_${count_label}CountImage_${SectionNum}.hv"
		cp "OSEM_${PhantomFilenameStem}_${SectionNum}_${count_label}_FORE_${NumSubiterationsFORE}.v" "${DatasetDir}/${PhantomSpecificDataFolder}/rebin_${count_label}CountImage_${SectionNum}.v"
		sed -i "s/.*data file :=.*/name of data file := rebin_${count_label}CountImage_${SectionNum}.v/" "${DatasetDir}/${PhantomSpecificDataFolder}/rebin_${count_label}CountImage_${SectionNum}.hv"
	done

fi


echo "========================================="
echo "Reconstruct oblique data"
echo "========================================="

# Chosen to optimize image quality
NumSubsets=8 # Default: [8] Must evenly go into the # of views (288)
NumSubiterations=40 # 40 good, Default: [40]
NumSubiterationsOblique=$NumSubiterations # Used later for copying to the dataset directory

## If using precorrected data, uncomment the three lines below
#InputSinogram=precorrected_for_oblique.hs
#AdditiveSinogram=./EmptySinogram.hs
#MultFactors=./OnesSinogram.hs

## If doing corrections in reconstruction, uncomment the three lines below
InputSinogram=${prompt_sinogram} # set to precorrected data or uncorrected data (prompt_sinogram)
AdditiveSinogram=${OutputAdditiveSinogramFilenameHS}	# If using precorrected data, set to EmptySinogram.hs
MultFactors=${OutputMultiplicativeSinogramHS}					# If using precorrected data, set to OnesSinogram.hs

if [ $ReconOblique = 1 ]; then

	#stir_math -s --including-first --times-scalar 1 mult_scaled.hs ${OutputMultiplicativeSinogramHS}
	#stir_math -s scatter_plus_randoms.hs ${randoms3d} ${scatter_sinogram}
	stir_math -s --including-first --times-scalar 0 EmptySinogram.hs "${InputSinogram}"
	stir_math -s --including-first --times-scalar 0 --add-scalar 1 OnesSinogram.hs "${InputSinogram}"

	export NumSubsets NumSubiterations SectionNum AdditiveSinogram MultFactors InputSinogram

	if [ $parproj = 1 ]; then
		#FBP3DRP ./OurParFiles/FBP3DRP.par
		#OSMAPOSL ./OurParFiles/OSEM_parallelproj_precorrected.par # If using precorrected data, set AdditiveSinogram=EmptySinogram.hs and InputSinogram=OnesSinogram.hs
		OSMAPOSL ./OurParFiles/OSEM_parallelproj.par
	else
		OSMAPOSL ./OurParFiles/OSEM_ray_tracing.par
	fi
	echo "Image reconstruction complete! Image saved in ${DatasetDir}/${PhantomSpecificDataFolder} as 'oblique_image_${SectionNum}'"

	# Save the oblique reconstructions to DatasetDir
	cp "OSEM_${PhantomFilenameStem}_${SectionNum}_oblique_${NumSubiterationsOblique}.hv" "${DatasetDir}/${PhantomSpecificDataFolder}/oblique_image_${SectionNum}.hv"
	cp "OSEM_${PhantomFilenameStem}_${SectionNum}_oblique_${NumSubiterationsOblique}.v" "${DatasetDir}/${PhantomSpecificDataFolder}/oblique_image_${SectionNum}.v"
	sed -i "s/.*data file :=.*/name of data file := oblique_image_${SectionNum}.v/" "${DatasetDir}/${PhantomSpecificDataFolder}/oblique_image_${SectionNum}.hv"
fi


echo "========================================="
echo "Save Files to Dataset & Cleanup"
echo "========================================="

if [ $SaveFilesToDataset = 1 ]; then
	if [ $SaveNiftiFilesToDataset = 1 ]; then
		medcon -f "OSEM_${PhantomFilenameStem}_${SectionNum}_oblique_${NumSubiterationsOblique}.hv" -c nifti -w
		medcon -f "OSEM_${PhantomFilenameStem}_${SectionNum}_low_FORE_${NumSubiterationsFORE}.hv" -c nifti -w
		medcon -f "OSEM_${PhantomFilenameStem}_${SectionNum}_med_FORE_${NumSubiterationsFORE}.hv" -c nifti -w
		medcon -f "OSEM_${PhantomFilenameStem}_${SectionNum}_high_FORE_${NumSubiterationsFORE}.hv" -c nifti -w

		medcon -f "${PhantomFilenameStem}_rebinned_${SectionNum}_lowseg0_by_sino.hv" -c nifti -w
		medcon -f "${PhantomFilenameStem}_rebinned_${SectionNum}_medseg0_by_sino.hv" -c nifti -w
		medcon -f "${PhantomFilenameStem}_rebinned_${SectionNum}_highseg0_by_sino.hv" -c nifti -w

		cp "m000-OSEM_${PhantomFilenameStem}_${SectionNum}_oblique_${NumSubiterationsOblique}.nii" "${DatasetDir}/${PhantomSpecificDataFolder}/oblique_image_${SectionNum}.nii"
		cp "m000-OSEM_${PhantomFilenameStem}_${SectionNum}_low_FORE_${NumSubiterationsFORE}.nii" "${DatasetDir}/${PhantomSpecificDataFolder}/rebin_lowCountImage_${SectionNum}.nii"
		cp "m000-OSEM_${PhantomFilenameStem}_${SectionNum}_med_FORE_${NumSubiterationsFORE}.nii" "${DatasetDir}/${PhantomSpecificDataFolder}/rebin_medCountImage_${SectionNum}.nii"
		cp "m000-OSEM_${PhantomFilenameStem}_${SectionNum}_high_FORE_${NumSubiterationsFORE}.nii" "${DatasetDir}/${PhantomSpecificDataFolder}/rebin_highCountImage_${SectionNum}.nii"

		cp "m000-${PhantomFilenameStem}_rebinned_${SectionNum}_lowseg0_by_sino.nii" "${DatasetDir}/${PhantomSpecificDataFolder}/rebin_lowCountSino_${SectionNum}.nii"
		cp "m000-${PhantomFilenameStem}_rebinned_${SectionNum}_medseg0_by_sino.nii" "${DatasetDir}/${PhantomSpecificDataFolder}/rebin_medCountSino_${SectionNum}.nii"
		cp "m000-${PhantomFilenameStem}_rebinned_${SectionNum}_highseg0_by_sino.nii" "${DatasetDir}/${PhantomSpecificDataFolder}/rebin_highCountSino_${SectionNum}.nii"
	fi

    if [ $SaveIntermediateFilesToDataset = 1 ]; then
		bash ./SubScripts/ExtractSegments/extract_oblique_segments.sh ${prompt_sinogram} $PhantomSpecificDataFolder $SectionNum PromptSinogram	
		bash ./SubScripts/ExtractSegments/extract_oblique_segments.sh ${randoms3d} $PhantomSpecificDataFolder $SectionNum RandomEstimation
		bash ./SubScripts/ExtractSegments/extract_oblique_segments.sh ${delayed_sinogram} $PhantomSpecificDataFolder $SectionNum DelayedSinogram	
		bash ./SubScripts/ExtractSegments/extract_oblique_segments.sh ${normalization_sinogram} $PhantomSpecificDataFolder $SectionNum Normalization

		bash ./SubScripts/ExtractSegments/extract_oblique_segments.sh ${OutputMultiplicativeSinogramHS} $PhantomSpecificDataFolder $SectionNum Multiplicative
		bash ./SubScripts/ExtractSegments/extract_oblique_segments.sh "${scatter_prefix}_1.hs" $PhantomSpecificDataFolder $SectionNum Scatter1
		bash ./SubScripts/ExtractSegments/extract_oblique_segments.sh "${scatter_prefix}_2.hs" $PhantomSpecificDataFolder $SectionNum Scatter2
		bash ./SubScripts/ExtractSegments/extract_oblique_segments.sh "${scatter_prefix}_3.hs" $PhantomSpecificDataFolder $SectionNum Scatter3
		bash ./SubScripts/ExtractSegments/extract_oblique_segments.sh "${scatter_prefix}_4.hs" $PhantomSpecificDataFolder $SectionNum Scatter4
		bash ./SubScripts/ExtractSegments/extract_oblique_segments.sh "${scatter_prefix}_5.hs" $PhantomSpecificDataFolder $SectionNum Scatter5
		bash ./SubScripts/ExtractSegments/extract_oblique_segments.sh "${total_additive_prefix}_5.hs" $PhantomSpecificDataFolder $SectionNum TotalAdditive
		bash ./SubScripts/ExtractSegments/extract_oblique_segments.sh "${mask_projdata_filename}.hs" $PhantomSpecificDataFolder $SectionNum ScatterMask
		bash ./SubScripts/ExtractSegments/extract_oblique_segments.sh ${acf3d} $PhantomSpecificDataFolder $SectionNum ACFs

		
		echo "PROMPT SINOGRAM INFO"
		echo "===================="
		list_projdata_info --all ${prompt_sinogram}
		echo "TOTAL ADDITIVE INFO"
		echo "====================="
		list_projdata_info --all ${total_additive_sinogram}
		echo "RANDOM SINOGRAM INFO"
		echo "===================="
		list_projdata_info --all ${randoms3d}
		echo "SCATTER SINOGRAM INFO"
		echo "====================="
		list_projdata_info --all ${scatter_sinogram}

	fi

sh ./SubScripts/_WriteProjInfoToLog.sh ${prompt_sinogram} Prompt_Counts
sh ./SubScripts/_WriteProjInfoToLog.sh ${randoms3d} Randoms_Counts
sh ./SubScripts/_WriteProjInfoToLog.sh ${scatter_sinogram} Scatter_Counts

fi
# Clear out the VoxelisedSimulation folder by removing all files except for __MAIN_SCRIPT.sh. Subfolders are left alone.
# Also, delete the GATE output files in VoxelisedSimulation/Output
if [ $CleanupFiles = 1 ]; then
	#find . -maxdepth 1 -type f ! -name __MAIN_SCRIPT.sh -exec rm -f {} \;
	#rm -r ./Output

	echo "Cleaning up unneeded data!"
	rm ${acf3d%.hs}*
	rm ${mask_image}*
	rm ${scatter_prefix}*
	rm ${mask_projdata_filename}*
	rm ${total_additive_prefix}*
	rm ${randoms3d_prefix}*

	rm "fansums_for_"*
	rm ${factors}"_"*

	rm -r ./extras/
	rm "fansums_for_"*
	rm ${factors}"_"*

	rm ${atnimg%.hv}*
	rm my_zflipped_atten.hv
	rm m000-Phantom${SectionNum}-MuMap*
	rm m000-Phantom${SectionNum}-SourceMap*
fi


#xmedcon "OSEM_${PhantomFilenameStem}_${SectionNum}_oblique_${NumSubiterationsOblique}.hv" 



echo "Script _CorrectAndReconstruct.sh finished running at: $(date +%T)"