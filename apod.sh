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
#
# Cancels messages based on their importance
# Values: 0 (and less) --- No canceled messages
#         1            --- Non error messages are canceled
#         2 (and more) --- No messages are sent
QUIET=0
# Creates a copy at the file's location
# Values: 0 --- No file is created
#         1 --- File will be copied to script location
LOCALCOPY=0
# Changes the final file's location to this one
OUTPUTFILE=""

# Echoes information messages
# The '--quiet' flag stops these messages
function log {
  if [[ $QUIET -lt 1 ]]; then
    echo "$*"
  fi
}

# Echoes error messages based on an error code
# The '--quiet-errors' flag stops these messages
# Messages follow this format: "Error #(Code) --- (Message)"
function logerr {
  if [[ $QUIET -lt 2 ]]; then
    errorMessage="Error #"$2" --- "
    case $2 in
    0) # Invalid error number
      errorMessage=$errorMessage"Invalid error code."
      ;;
    1) # Invalid flag/s
      errorMessage=$errorMessage"Invalid flag/s."
      ;;
    2)
      errorMessage=$errorMessage"Cannot find config file or config file does not exist."
      ;;
    3)
      errorMessage=$errorMessage"Final location does not exist."
      ;;
    4)
      errorMessage=$errorMessage"No valid image found."
      ;;
    5)
      errorMessage=$errorMessage"Cannot successfully correct file."
      ;;
    *)
      logerr 1 0
      ;;
    esac
    echo $errorMessage
  fi

  # Stop program
  if [[ $1 -eq 1 ]]; then
    exit
  fi
}

# Parse flags
while [[ $# -gt 0 ]]; do
  case $1 in
  -q | --quiet)
    QUIET=1
    shift
    ;;
  -Q | --quiet-errors)
    QUIET=2
    shift
    ;;
  -q=* | --quiet=* | -Q=* | --quiet-error=*)
    QUIET=${1##*=}
    shift
    ;;
  -l | --local-copy)
    LOCALCOPY=1
    shift
    ;;
  -o=* | --output-file=*)
    OUTPUTFILE=${1##*=}
    shift
    ;;
  *)
    logerr 1 1
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
    rm -r $temporaryFileLocation
  fi
  exit
}

# Check for '--output-file' flag
if ! [[ $OUTPUT == "" ]]; then
  log Changing final location to output...
  finalLocation=$OUTPUT
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
  logerr 1 4
elif [[ $index -ne 1 ]]; then
  logerr 1 5
else
  log Moving and converting file...
  mv $fileName$finalExtension "$finalLocation/$finalName.$finalExtension"
fi

# Final sentence
eval $finalCommand

# The end it all
stop
