#! /bin/sh

# list_image_info and list_projdata_info utilities

#input="../VoxelisedSimulation/Output/Unlisted/Coincidences/Sino_Sim_normalisation.hs"
#input="../VoxelisedSimulation/activity.hv"
#input="../VoxelisedSimulation/Output/Unlisted/Delayed/Sino_Sim_cyltest.hs"
#input="../VoxelisedSimulation/rebinned_tests.hs"
#input="../VoxelisedSimulation/my_attenuation_coefficients.hs"
#input="../VoxelisedSimulation/cylinder_Mult_test.hs"
#input="../VoxelisedSimulation/NormalisationInterfiles/parallelproj_D690.hs"
#input="../VoxelisedSimulation/cylinder_Mult_atntest.hs"

#input="../ExampleReconstruction/_Add_tests.hs"
#input="../ExampleReconstruction/EmptySinogram.hs"

#input="/home/evelyne/software/STIR/recon_test_pack/STIR/recon_test_pack/my_norm.hs"

#input="../DataCorrectionsComputation/eff_factors_span1.hs"
#input="../DataCorrectionsComputation/parallelproj_D690.hs"
#input="../DataCorrectionsComputation/eff_factors_span1.hs"

## REBINNING ##
#input="../VoxelisedSimulation/rebinned_tests.hs"
#input="../VoxelisedSimulation/Output/Unlisted/Coincidences/Sino_Sim_tests_correct_energy_window.hs"

## IMAGES ##
#input="../VoxelisedSimulation/male_pt168_atn_1_GATE.hv"
#input="../VoxelisedSimulation/m000-Phantomxcattest3-MuMap.hv"

#input=../VoxelisedSimulation/DatasetDir/QA/oblique_image_NEMA_8_4min.hv

input=../VoxelisedSimulation/Output/Unlisted/Coincidences/Sino_Sim_axial_120s.hs
#stir_math --including-first --times-scalar 1 temp.hv "../VoxelisedSimulation/AbstractAnalysis/4CountSino_9_120s.hv"


list_projdata_info --all $input
#list_image_info --all $input

#display_projdata $input  # Display the data by view or by segment for a defined segment number (ring difference)
#stir_write_pgm # Writes PGM for for a single slice of an image
#extract_segments # Extracts projection data by segment into a sequence of 3D image files.


# Calibration Factor (i.e. scale factor that sets the projection data to the same units as the input function