#!/bin/bash
# build.sh -- builds JAR and XPI files for mozilla extensions
#   by Nickolay Ponomarev <asqueella@gmail.com>
#   (original version based on Nathan Yergler's build script)
# Most recent version is at <http://kb.mozillazine.org/Bash_build_script>
# based on Nathan Yergler's build script
# Modified to work on OS X by Mike Chambers (http://mesh.typepad.com)

# This script assumes the following directory structure:
# ./
#   chrome.manifest (optional - for newer extensions)
#   install.rdf
#   (other files listed in $ROOT_FILES)
#
#   content/    |
#   locale/     |} these can be named arbitrary and listed in $CHROME_PROVIDERS
#   skin/       |
#
#   defaults/   |
#   components/ |} these must be listed in $ROOT_DIRS in order to be packaged
#   ...         |
#
# It uses a temporary directory ./build when building; don't use that!
# Script's output is:
# ./$APP_NAME.xpi
# ./$APP_NAME.jar  (only if $KEEP_JAR=1)
# ./files -- the list of packaged files
#
# Note: It modifies chrome.manifest when packaging so that it points to 
#       chrome/$APP_NAME.jar!/*

#
# default configuration file is ./config_build.sh, unless another file is 
# specified in command-line. Available config variables:
APP_NAME=          # short-name, jar and xpi files name. Must be lowercase with no spaces
CHROME_PROVIDERS=  # which chrome providers we have (space-separated list)
CLEAN_UP=          # delete the jar / "files" when done?       (1/0)
ROOT_FILES=        # put these files in root of xpi (space separated list of leaf filenames)
ROOT_DIRS=         # ...and these directories       (space separated list)
BEFORE_BUILD=      # run this before building       (bash command)
AFTER_BUILD=       # ...and this after the build    (bash command)

if [ -z $1 ]; then
  . ./config_build.sh
else
  . $1
fi

if [ -z $APP_NAME ]; then
  echo "You need to create build config file first!"
  echo "Read comments at the beginning of this script for more info."
  exit;
fi

ROOT_DIR=`pwd`
TMP_DIR=build

#uncomment to debug
#set -x

# remove any left-over files
rm $APP_NAME.jar
rm $APP_NAME.xpi
rm -rf $TMP_DIR

# create xpi directory layout and populate it
mkdir $TMP_DIR
mkdir $TMP_DIR/chrome

if [ $HAS_COMPONENTS ]; then
  mkdir $TMP_DIR/components
  cp components/* $TMP_DIR/components
fi

if [ -d "./defaults" ]; then
  DEFAULT_FILES="`find ./defaults -path '*DS_Store*' -prune -o -type f -print | grep -v \~`"
  cp --parents $DEFAULT_FILES $TMP_DIR
fi

# Copy other files to the root of future XPI.
cp $ROOT_FILES $TMP_DIR

# generate the JAR file, excluding .DS_Store and temporary files
zip -0 -r $TMP_DIR/chrome/$APP_NAME.jar `find content -path '*DS_Store*' -prune -o -type f -print | grep -v \~`
if [ -d "./locale" ]; then
  zip -0 -r $TMP_DIR/chrome/$APP_NAME.jar `find locale -path '*DS_Store*' -prune -o -type f -print | grep -v \~`
fi
if [ -d "./skin" ]; then
  zip -0 -r $TMP_DIR/chrome/$APP_NAME.jar `find skin -path '*DS_Store*' -prune -o -type f -print | grep -v \~`
fi

# generate the XPI file
cd $TMP_DIR
zip -r ../$APP_NAME.xpi *
cd ..

if [ $KEEP_JAR ]; then
  # save the jar file
  mv $TMP_DIR/chrome/$APP_NAME.jar .
fi

# remove the working files
rm -rf $TMP_DIR

$AFTER_BUILD
