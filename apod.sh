#!/bin/bash

# Check for sudo perms
if [ "$EUID" -ne 0 ]; then
    echo "Requires 'sudo' perms"
    exit
fi

# Variables
siteUrl="https://apod.nasa.gov/apod/astropix.html"
allowedTypes="png,jpg,jpeg,webp" # TODO: Config for this
additionalFlags="-q" # TODO: Config for this
conversion="magick" # TODO: Config for this
#finalName="active" # TODO: Config for this
finalName="apod"
finalExtension="png" # TODO: Config for this
#finalLocation="~/.config/hypr/wallpapers/" # TODO: Config for this
finalLocation=""

# TODO: Parse config

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
echo "Downloading files..."
wget -r -l1 -H -R "*_1024.*" -nd -A $allowedTypes -P ./.tp/dl --no-parent --convert-links $additionalFlags $siteUrl

# Rename image/s to wanted outname followed by the index of the image
echo "Renaming files..."
index=0
for file in ".tp/dl"/*; do
    ext="${file##*.}"
    fileName=".tp/pr/"$finalName"_"$index"."
    mv $file $fileName$ext # Rename and move file
    eval $conversion $fileName$ext $fileName$finalExtension # Change file extension
    index=$index+1
done

if [[ $index -ne 1 ]]; then
    # Keep files depending on configuration
    echo "Selecting file..."
else
    # Move file like nothing happened :D
    echo "Moving and converting file..."
    mv .tp/pr/$finalName"_0."$finalExtension $finalLocation$finalName"."$finalExtension
fi

# Remove temporary files
echo "Removing temporary files..."
rm -r .tp/
