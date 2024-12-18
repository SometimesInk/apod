#!/bin/bash

# Flags
QUIET=0
LOCALCOPY=0

# Log function to toggle outputs with -q flag
function log {
  if [[ $QUIET -eq 0 ]]; then
    echo "$*"
  fi
}

# Stop function to remove temporary files before exiting
function stop {
  if [[ -e .tp/ ]]; then
    log Removing temporary files...
    rm -r .tp/
  fi
  exit
}

# Parse flags
while [[ $# -gt 0 ]]; do
  case $1 in
  -q | --quiet)
    QUIET=1
    shift
    shift
    ;;
  -l | --local-copy)
    LOCALCOPY=1
    shift
    shift
    ;;
  *)
    echo "Error: Invalid flag/s."
    stop
    ;;
  esac
done

# Variables
siteUrl="https://apod.nasa.gov/apod/astropix.html"
allowedTypes="png,jpg,jpeg"
additionalFlags="-q"
conversion="magick" # Either 'convert' [which is deprecated] or 'magick'
finalName="apod"
finalExtension="png"
finalLocation=""

# Find file location
thisLocation=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"/"

# Parse config file
if [[ -f $thisLocation"apod.ini" ]]; then
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
  done <$thisLocation"apod.ini"
else
  echo "Error: Cannot find config file or config file does not exist."
  stop
fi

# Check if final location exists
if ! [[ -d $finalLocation ]]; then
  echo "Error: Final location $finalLocation does not exist."
  stop
fi

# Empty temporary directory if it is already created
if [[ -e ".tp/" ]]; then
  log Emptying temporary directory tree.
  stop
fi

# Create temporary directory
log Creating temporary directory tree...
mkdir -p .tp/dl # Download directory
mkdir .tp/pr    # Processing directory

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
wget -p --no-parent -nd -P ./.tp/dl -e robots=off -R "*_1024.*" -A $allowedTypes --convert-links $additionalFlags $siteUrl

# Rename image/s to wanted outname followed by the index of the image
# This it done to make it easier to handle files without having to deal with different file extensions
log Renaming files...
index=0
for file in ".tp/dl"/*; do
  ext="${file##*.}"
  fileName=".tp/pr/"$finalName"_"$index"."
  mv $file $fileName$ext                                  # Rename and move file
  eval $conversion $fileName$ext $fileName$finalExtension # Change file extension
  rm $fileName$ext
  index=$index+1
done

# Local-copy flag
if [[ LOCALCOPY -eq 1 ]]; then
  log Copying "local" copy...
  cp $fileName$finalExtension $finalName"."$finalExtension
fi

# Select file
if [[ $index -eq 0 ]]; then
  echo "Error: No valid image found."
elif [[ $index -ne 1 ]]; then
  echo "Error: Selecting file..."
else
  log Moving and converting file...
  mv $fileName$finalExtension "$finalLocation/$finalName.$finalExtension"
fi

# End it all
stop
