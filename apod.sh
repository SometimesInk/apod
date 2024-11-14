#!/bin/bash

siteUrl="https://apod.nasa.gov/apod/astropix.html"
allowedTypes="png,jpg,jpeg,webp" # TODO: Config for this
additionalFlags="-q --show-progress" # TODO: Config for this
outputName="apod" # TODO: Config for this

# Empty temporary directory if it is already created
if [[ -e ".temp/" ]]; then
    echo "Emptying temporary directory..."
    rm -r .temp/
fi

# Create temporary directory
mkdir .temp/

# Download all images of wanted image types while rejecting thumbnail images (which have a lesser quality)
wget -r -l1 -H -R "*_1024.*" -nd -A $allowedTypes -P ./.temp/ --no-parent --convert-links $additionalFlags $siteUrl

# Rename image/s to wanted outname followed by the index of the image
index=0
for file in ".temp"/*; do
    mv $file "$outputName_$index"
    index=$index+1
done
