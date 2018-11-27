#! /bin/bash

echo "Defects4J_oneLinerFix.sh start"

CURRENT_DIR=$(pwd)
DEFECTS4J_DIR=$CURRENT_DIR/Defects4J_projects
echo "Creating directory 'Defects4J_projects'"
mkdir -p $DEFECTS4J_DIR
echo

DEFECTS4J_PATCHES_DIR=$CURRENT_DIR/Defects4J_patches
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

  echo "Generating patches for ${col1}_${col2}"
  $CURRENT_DIR/../end-to-end.sh --buggy_file=$BUG_PROJECT/$col3 --buggy_line=$col4 --beam_size=50 --output=$DEFECTS4J_PATCHES_DIR/${col1}_${col2}

  echo "Running test on all patches for ${col1}_${col2}"
  python3 $CURRENT_DIR/../src/validatePatch.py $DEFECTS4J_PATCHES_DIR/${col1}_${col2} $BUG_PROJECT $BUG_PROJECT/$col3

  echo "Deleting ${BUG_PROJECT}"
  rm -rf $BUG_PROJECT
done < Defects4J_oneLiner_metadata.csv

echo "Deleting Defects4J_projects"
rm -rf $DEFECTS4J_DIR

echo "Found $(find $DEFECTS4J_PATCHES_DIR -name '*_passed' | wc -l | awk '{print $1}') test-suite adequate patches in total."
echo "Found passing patches for $(find $DEFECTS4J_PATCHES_DIR -name '*_passed' -exec dirname {} \; | sort -u | wc -l | awk '{print $1}') projects"
echo "Defects4J_oneLinerFix.sh done"
exit 0
