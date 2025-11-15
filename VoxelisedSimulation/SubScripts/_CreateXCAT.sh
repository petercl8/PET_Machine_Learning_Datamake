#! /bin/sh

SectionNum=$1

##### ================
## Create XCAT Phantom
##### ================

# Create a default phantom with all activities set to default SUVs
sh ./SubScripts/CreateXCATImages/CreateXCATImage.sh $SectionNum 0 0 0 $max_SUV_diseased 0 ${PhantomFilenameStem}

# Determine the total activity of this default phantom
XCAT_sum=$(list_image_info $ActivityFilenameStem".hv" | awk -F: '/Image sum/ {print $2}' | tr -d '[:space:]')
default_activity=$(printf "%.10f" "$XCAT_sum")

echo "Default Activity: $default_activity"

if [ $(echo "$default_activity > 0" | bc -l) -eq 1 ]; then
	# Determine the thresholds between which the new phantom, with varied activity, must lie
	low_threshold=$(echo "scale=10; $default_activity - $default_activity * $total_activity_variation" | bc)
	high_threshold=$(echo "scale=10; $default_activity + $default_activity * $total_activity_variation" | bc)

	# Create the new phantom with varied activities.
	# We run a while loop until the phantom with varied activities is within the allowed range
	new_activity=0
	while [ $(echo "$new_activity > $high_threshold" | bc -l) -eq 1 ] || [ $(echo "$new_activity < $low_threshold" | bc -l) -eq 1 ]; do
		# Create a new phantom with activity variations
		sh ./SubScripts/CreateXCATImages/CreateXCATImage.sh $SectionNum $small_activity_variation $large_activity_variation $organ_symmetry_variation $max_SUV_diseased $fraction_diseased ${PhantomFilenameStem}

		XCAT_sum=$(list_image_info $ActivityFilenameStem".hv" | awk -F: '/Image sum/ {print $2}' | tr -d '[:space:]')
		new_activity=$(printf "%.10f" "$XCAT_sum")
		#new_activity=$(echo "scale=10; $XCAT_sum" | bc)

		echo "Running Acitivity While Loop"
		echo "============================"
		echo "Low Threshold: "$low_threshold
		echo "High Threshold: "$high_threshold
		echo "Default Activity: "$default_activity
		echo "New Activity: "$new_activity
	done
	exit 1
else
	echo "We've reached the end of the line! No more activity here!"
	# Next we set some run variables = 0 so that all scripts terminate.
	exit 0
fi