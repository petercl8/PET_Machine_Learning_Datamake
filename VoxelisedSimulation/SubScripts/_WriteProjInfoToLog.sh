#! /bin/bash
##############################################
## Write some sinogram info to the log file ##
##############################################

sino=$1
label=$2

sum=$(list_projdata_info --all $sino | awk -F: '/Data sum/ {print $2}' | tr -d '[:space:]')
sum_decimal=$(printf "%.0f" "$sum")


echo $sum_decimal

echo "$label: " $sum_decimal >> "${DatasetDir}/${PhantomSpecificDataFolder}/AAA-RunLog_${PhantomFilenameStem}.txt"


exit 0