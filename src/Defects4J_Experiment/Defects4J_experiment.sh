#! /bin/bash

USE_TIMESTAMP=0
LOG_RESULT=0

while [ "$1" != "" ]; do
  case $1 in
    -l | --log-result )
      LOG_RESULT=1      
      ;;
    -t | --timestamp )
      USE_TIMESTAMP=1
      ;;
  esac
  shift
done

echo "Defects4J_oneLinerFix.sh start"

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DEFECTS4J_DIR=$CURRENT_DIR/Defects4J_projects
CONTINUOUS_LEARNING_DATA=$CURRENT_DIR/../Continuous_Learning/public/single_run_data

echo "Creating directory 'Defects4J_projects'"
mkdir -p $DEFECTS4J_DIR
echo

if [ $USE_TIMESTAMP -eq 1 ]; then
  TIMESTAMP=`date +"%d%m%Y-%H%M"`
  DEFECTS4J_PATCHES_DIR=$CURRENT_DIR/Defects4J_patches/$TIMESTAMP
else
  DEFECTS4J_PATCHES_DIR=$CURRENT_DIR/Defects4J_patches
fi

echo "Creating directory 'Defects4J_patches'"
mkdir -p $DEFECTS4J_PATCHES_DIR
echo

echo "Reading from Defects4J_oneLiner_metadata.csv"
while IFS=, read -r col1 col2 col3 col4
do
  BUG_PROJECT=${DEFECTS4J_DIR}/${col1}_${col2}
  mkdir -p $BUG_PROJECT
  echo "Checking out ${col1}_${col2} to ${BUG_PROJECT}"
  defects4j checkout -p $col1 -v ${col2}b -w $BUG_PROJECT &>/dev/null
  echo

  echo "Generating patches for ${col1}_${col2}"
  $CURRENT_DIR/../sequencer-predict.sh --buggy_file=$BUG_PROJECT/$col3 --buggy_line=$col4 --beam_size=50 --output=$DEFECTS4J_PATCHES_DIR/${col1}_${col2}
  echo

  echo "Running test on all patches for ${col1}_${col2}"
  python3 $CURRENT_DIR/validatePatch.py $DEFECTS4J_PATCHES_DIR/${col1}_${col2} $BUG_PROJECT $BUG_PROJECT/$col3
  echo

  echo "Deleting ${BUG_PROJECT}"
  rm -rf $BUG_PROJECT
  echo
done < Defects4J_oneLiner_metadata.csv

echo "Deleting Defects4J_projects"
rm -rf $DEFECTS4J_DIR
echo

if [ $LOG_RESULT -eq 1 ]; then
  CREATED=`find $DEFECTS4J_PATCHES_DIR -name '*' -type d | wc -l | awk '{print $1}'`
  COMPILED=`find $DEFECTS4J_PATCHES_DIR -name '*_compiled' | wc -l | awk '{print $1}'`
  PASSED=`find $DEFECTS4J_PATCHES_DIR -name '*_passed' | wc -l | awk '{print $1}'`
  echo "$CREATED,$COMPILED,$PASSED,$TIMESTAMP" > $CONTINUOUS_LEARNING_DATA
fi

echo "Found $(find $DEFECTS4J_PATCHES_DIR -name '*_passed' | wc -l | awk '{print $1}') test-suite adequate patches in total."
echo "Found passing patches for $(find $DEFECTS4J_PATCHES_DIR -name '*_passed' -exec dirname {} \; | sort -u | wc -l | awk '{print $1}') projects"
echo "Defects4J_oneLinerFix.sh done"
echo
exit 0
