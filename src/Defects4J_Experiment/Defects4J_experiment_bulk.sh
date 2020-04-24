#! /bin/bash

echo "Defects4J_experiment_bulk.sh start"

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DEFECTS4J_DIR=$CURRENT_DIR/Defects4J_projects
CONTINUOUS_LEARNING_DATA=$CURRENT_DIR/../Continuous_Learning/public/single_run_data
MODELS_DIR="$HOME/sequencer/src/Continuous_Learning/models/model-*"


echo "Creating directory 'Defects4J_projects'"
mkdir -p $DEFECTS4J_DIR
echo

MODEL_LIST=($(ls -v $MODELS_DIR))

PARSED_MODEL_LIST=()

for i in "${MODEL_LIST[@]}"
do
   : 
   PARSED_MODEL_LIST+=( `echo $i | sed 's/.*model-\([0-9]*-[0-9]*\).*/\1/'`)
done

for j in ${PARSED_MODEL_LIST[@]}
do
   : 
   mkdir -p "$CURRENT_DIR/Defects4J_patches/$j"
done


echo "Creating directory 'Defects4J_patches'"
echo

echo "Reading from Defects4J_oneLiner_metadata.csv"
while IFS=, read -r col1 col2 col3 col4
do
  BUG_PROJECT=${DEFECTS4J_DIR}/${col1}_${col2}
  mkdir -p $BUG_PROJECT
  echo "Checking out ${col1}_${col2} to ${BUG_PROJECT}"
  defects4j checkout -p $col1 -v ${col2}b -w $BUG_PROJECT &>/dev/null
  echo

  for k in ${PARSED_MODEL_LIST[@]}
  do
    :
    DEFECTS4J_PATCHES_DIR="$CURRENT_DIR/Defects4J_patches/$k"
    echo "Generating patches for ${col1}_${col2}"
    $CURRENT_DIR/../sequencer-predict.sh --model="$MODELS_DIR$k.pt" --buggy_file=$BUG_PROJECT/$col3 --buggy_line=$col4 --beam_size=50 --output=$DEFECTS4J_PATCHES_DIR/${col1}_${col2}
    echo

    echo "Running test on all patches for ${col1}_${col2}"
    python3 $CURRENT_DIR/validatePatch.py $DEFECTS4J_PATCHES_DIR/${col1}_${col2} $BUG_PROJECT $BUG_PROJECT/$col3
    echo
  done

  echo "Deleting ${BUG_PROJECT}"
  rm -rf $BUG_PROJECT
  echo
done < Defects4J_oneLiner_metadata.csv

echo "Deleting Defects4J_projects"
rm -rf $DEFECTS4J_DIR
echo

for j in ${PARSED_MODEL_LIST[@]}
do
    : 
    DEFECTS4J_PATCHES_DIR="$CURRENT_DIR/Defects4J_patches/$k" 
    CREATED=`find $DEFECTS4J_PATCHES_DIR -name '*' -type d | wc -l | awk '{print $1}'`
    COMPILED=`find $DEFECTS4J_PATCHES_DIR -name '*_compiled' | wc -l | awk '{print $1}'`
    PASSED=`find $DEFECTS4J_PATCHES_DIR -name '*_passed' | wc -l | awk '{print $1}'`
    echo "$CREATED,$COMPILED,$PASSED,$TIMESTAMP" >> $CONTINUOUS_LEARNING_DATA
done

echo "Defects4J_oneLinerFix.sh done"
echo
exit 0
