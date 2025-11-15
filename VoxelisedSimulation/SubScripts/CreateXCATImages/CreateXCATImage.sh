#! /bin/sh

# $1 = SectionNum
# $2 = small_activity_variation
# $3 = large_activity_variation
# $4 = organ_symmetry_variation
# $5 = max_SUV_diseased
# $6 = fraction_diseased
# $7 = name for XCAT phantom

# ============================================
# === Deal with XCAT parameter (.par) file ===

xcat_parfile_path=./SubScripts/CreateXCATImages/general.samp_random_act.par
export xcat_parfile_path

# The following script takes the unedited xcat_parfile (located: /SubScripts/CreateXCATImages/XCAT_V2_LINUX/general.samp_3mmVox-SUVs.par),
# makes alterations to vary the activity, and copies it to $xcat_parfile_path specified above.
# The number of slices is the height of the XCAT phantom divided by the thickness/slice. In general.samp_random_act.par,
# 	the thickness is assigned by the line: slice_width = 0.327  (0.327 cm)

python ./SubScripts/ChangeXCATPars.py $total_activity_variation $2 $3 $4 $5 $6 $XCAT_PATH $normalize_xcat 

# Edit the .nrb file entries in general.samp.par file at two locations:
# {XCAT_phantom}.nrb and {XCAT_phantom}_heart.nrb
# These sed commands are very brittle and editing them or their lines in the parameter file could break the code.

sed -i "s|gender = .*	|gender = ${gender}	|" ./${xcat_parfile_path}
sed -i "s|which_breast = .*	|which_breast = ${which_breast}	|"	./${xcat_parfile_path}
sed -i "s|.*heart_base.*|heart_base = ${XCAT_PATH}/${NRB_FOLDER_NAME}/${PhantomFilenameStem}_heart.nrb |" \
./${xcat_parfile_path}
sed -i "s|.*organ_file.*|organ_file = ${XCAT_PATH}/${NRB_FOLDER_NAME}/${PhantomFilenameStem}.nrb |" \
./${xcat_parfile_path}
sed -i "s|{XCAT_PATH}|$XCAT_PATH|g" ./${xcat_parfile_path}


## Change the slice number (section of the phantom you are imaging)
## ----------------------------------------------------------------
NewStartSlice=$((1 + ( $voxelZ-$overlap )*$1))
NewEndSlice=$(($voxelZ + ( $voxelZ-$overlap )*$1))

sed -i "s/startslice = .*/startslice = $NewStartSlice/" $xcat_parfile_path
sed -i "s/endslice = .*/endslice = $NewEndSlice/" $xcat_parfile_path


# ==========================================
# === GENERATE 2 XCAT BINARY FILES + LOG ===
#	Output:
# 		Datafiles:	 	PhantomFilenameStem_act_1.bin, AttenuationFilenameStemGATE_1.bin
#		Log file:		PhantomFilenameStem_log
# ===========================================


${XCAT_PATH}/dxcat2_linux_64bit \
 ${xcat_parfile_path} \
 $7