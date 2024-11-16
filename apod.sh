#!/bin/bash

# Define stop function
function stop {
    if [[ -e .tp/ ]]; then
        echo "Removing temporary files..."
        rm -r .tp/
    fi
    exit
}

# Variables
siteUrl="https://apod.nasa.gov/apod/astropix.html"
allowedTypes="png,jpg,jpeg"
additionalFlags="-q"
conversion="magick" # Either 'convert' [which is deprecated] or 'magick'
finalName="apod"
finalExtension="png"
finalLocation=""

# Parse config file
if [[ -f "apod.ini" ]]; then
    while read line; do
        # Check if comment
        if ! [[ ${line%;*} == "" ]]; then
            # Find KVp
            key=${line%=*}
            value=${line##*=}
         
            # Parse keys
            case $key in
                "siteUrl")
                    siteUrl=$value
                    ;;
                "allowedTypes")
                    allowedTypes=$value
                    ;;
                "additionalFlags")
                    additionalFlags=$value
                    ;;
                "conversion")
                    conversion=$value
                    ;;
                "finalName")
                    finalName=$value
                    ;;
                "finalExtension")
                    finalExtension=$value
                    ;;
                "finalLocation")
                    finalLocation=$value
                    ;;
            esac
        fi
    done <apod.ini
fi

# Check if final location exists
if ! [[ -d $finalLocation ]]; then
    echo "Error: Final location '$finalLocation' does not exist."
    stop
fi

# Empty temporary directory if it is already created
if [[ -e ".tp/" ]]; then
    echo "Emptying temporary directory tree..."
    stop
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
    rm $fileName$ext
    index=$index+1
done

if [[ $index -ne 1 ]]; then
    # Keep files depending on configuration
    echo "Selecting file..."
elif [[ $index -eq 0 ]]; then
    echo "Error: No valid image found."
    stop
else
    echo "Moving and converting file..."
    mv "$fileName$finalExtension" "$finalLocation"
fi

# End it all
stop
