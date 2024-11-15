#!/bin/bash

siteUrl="https://apod.nasa.gov/apod/astropix.html"
allowedTypes="png,jpg,jpeg,webp" # TODO: Config for this
additionalFlags="-q" # TODO: Config for this
outputName="apod" # TODO: Config for this

# Empty temporary directory if it is already created
if [[ -e ".tp/" ]]; then
    echo "Emptying temporary directory tree..."
    rm -r .tp/
fi

# Create temporary directory
echo "Creating temporary directory tree..."
mkdir -p .tp/dl # Download directory
mkdir -p .tp/pr # Processing directory

# Download all images of wanted image types while rejecting thumbnail images (which have a lesser quality)
echo "Downloading images..."
wget -r -l1 -H -R "*_1024.*" -nd -A $allowedTypes -P ./.tp/dl --no-parent --convert-links $additionalFlags $siteUrl

# Rename image/s to wanted outname followed by the index of the image
echo "Renaming files..."
index=0
for file in ".tp/dl"/*; do
    ext="${file##*.}"
    mv $file ".tp/pr/"$outputName"_"$index"."$ext # Rename and move file
    index=$index+1
done
