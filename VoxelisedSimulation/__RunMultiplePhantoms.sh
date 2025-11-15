#! /bin/bash

##### ==============================================================
## Main Changeable Parameters
##### =============================================================

log_label=1
phantoms="male_pt184 male_pt141" # Sample list of phantoms

for phantom in $phantoms; do
	echo "Starting phantom ${phantom}: " $(date +%d.%m.%y-%H:%M:%S:%) >> "${DatasetDir}/AAA-RunLog_${log_label}.txt"
	sh ./__MAIN_SCRIPT.sh $phantom
	echo "Done with phantom ${phantom}: " $(date +%d.%m.%y-%H:%M:%S:%) >> "${DatasetDir}/AAA-RunLog_${log_label}.txt"
done
