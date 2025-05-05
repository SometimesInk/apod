#!/bin/bash
#  █████  ██████   ██████  ██████
# ██   ██ ██   ██ ██    ██ ██   ██
# ███████ ██████  ██    ██ ██   ██
# ██   ██ ██      ██    ██ ██   ██
# ██   ██ ██       ██████  ██████
#    SCRIPT
#
#
#
# DESCRIPTION
# This script downloads NASA's daily image and sets it as your wallpaper

# Initialize flags

# Location of the final file
OUTPUT=""

# Echoes to the stderr
#
# @param * Error message
function err {
  >&2 echo "E:" "$@"
}

# Parse flags
while [[ $# -gt 0 ]]; do
  case $1 in
  -q | --quiet)
    echo off
    shift
    ;;
  -o=* | --output-file=*)
    OUTPUTFILE=${1##*=}
    shift
    ;;
  *)
    err "Invalid flag $1"
    ;;
  esac
done

# Initialize variables
#
# The URL used to download the image
siteUrl="https://apod.nasa.gov/apod/astropix.html"
# Types to download
allowedTypes="png,jpg,jpeg"
# Additional flags to the Wget command
additionalFlags="-q"
# Command used to convert the image from its original extension to the wanted one
conversion="magick" # Either 'convert' [which is deprecated] or 'magick'
# The name of the output image
finalName="apod"
# The extension of the output image
finalExtension="png"
# The location of the output image
finalLocation=""
# A final command ran at the very end of the file before closing
finalCommand="hyprpaper"
# The location used for temporary files (which are automatically deleted)
temporaryFileLocation="/tmp/apod/"

# Find this file's location
thisLocation=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"/"

# Parse config file to find variables' values
if [[ -f $thisLocation"apod.ini" ]]; then
  while read line; do
    # Ignored commented lines
    if ! [[ ${line%;*} == "" ]]; then
      # Find key and value of the KVp
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
      "finalCommand")
        finalCommand=$value
        ;;
      "temporaryFileLocation")
        temporaryFileLocation=$value
        ;;
      esac
    fi
  done <$thisLocation"apod.ini"
else
  logerr 1 2
fi

# Stop function to remove temporary files before exiting
function stop {
  if [[ -e $temporaryFileLocation ]]; then
    log Removing temporary files...
    rm -r "$temporaryFileLocation"
  fi
  exit
}

# Check for '--output-file' flag
if ! [[ $OUTPUTFILE == "" ]]; then
  log Changing final location to output...
  finalLocation=$OUTPUTFILE
fi

# Check if final location exists
if ! [[ -d $finalLocation ]]; then
  logerr 1 3
fi

# Empty temporary directory if it is already created
if [[ -e $temporaryFileLocation ]]; then
  log Emptying temporary directory tree...
  rm -r $temporaryFileLocation
fi

# Create temporary directory
log Creating temporary directory tree...
mkdir -p $temporaryFileLocation"dl" # Download directory
mkdir -p $temporaryFileLocation"pr" # Processing directory

# Download all images of wanted image types while rejecting thumbnail images (which have a lesser quality)
log Downloading files...

# -p ; download all images necessary to render the page
# --no-parent ; don't ascend the parent directory tree
# -nd ; don't create directory when downloading recusively
# -P ; download file to that specific directory "./tp/dl"
# -e robots=off ; don't download robot file
# -R ; don't download any file matching the string "*_1024.*" (thumbnail images)
# -A ; only download files of accepted file extensions
# --convert-links ; fix web links to make for usable images
wget -p --no-parent -nd -P $temporaryFileLocation"dl" -e robots=off -R "*_1024.*" -A $allowedTypes --convert-links $additionalFlags $siteUrl

# Rename image/s to wanted outname followed by the index of the image
# This it done to make it easier to handle files without having to deal with different file extensions
log Renaming files...
index=0
for file in $temporaryFileLocation"dl"/*; do
  ext="${file##*.}"
  fileName=$temporaryFileLocation"pr/"$finalName"_"$index"."
  mv $file $fileName$ext                                  # Rename and move file
  eval $conversion $fileName$ext $fileName$finalExtension # Change file extension
  rm $fileName$ext
  index=$index+1
done

# Check for '--local-copy' flag
if [[ LOCALCOPY -eq 1 ]]; then
  log Copying local copy...
  cp $fileName$finalExtension $finalName"."$finalExtension
fi

# Move file to its final location
if [[ $index -eq 0 ]]; then
  err "No file found."
elif [[ $index -ne 1 ]]; then
  err "Too many file found"
else
  log Moving and converting file...
  mv $fileName$finalExtension "$finalLocation/$finalName.$finalExtension"
fi

# Final sentence
eval $finalCommand

# The end it all
stop
