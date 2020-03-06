#! /bin/bash

set -e
set -x

if ! command -v sshpass &>/dev/null; then
  echo "sshpass is not installed"
  exit 1
fi

CONTINUOUS_LEARNING_PATH="$HOME/sequencer/src/Continuous_Learning"
DIFFS_DIR="$HOME/continuous-learning-data"
DATA_PATH="$CONTINUOUS_LEARNING_PATH/public"
TRAIN_SOURCE_FILE="$DATA_PATH/src-train.txt"
VALIDATION_SOURCE_FILE="$DATA_PATH/src-val.txt"
DATA_POINT_THRESHOLD=10000

mkdir -p $DATA_PATH

while :
do
  
  NUMBER_OF_DATA_POINTS=`find ~/continuous-learning-data -name "*.java-*" | wc -l`

  if [ "$NUMBER_OF_DATA_POINTS" -gt $DATA_POINT_THRESHOLD ] ; then

    cd $CONTINUOUS_LEARNING_PATH
    python3 tokenize.py $DIFFS_DIR $DATA_PATH

    FILESIZE_TRAIN=$(stat -c%s "$TRAIN_SOURCE_FILE")
    FILESIZE_VAL=$(stat -c%s "$VALIDATION_SOURCE_FILE")

    if [ "$FILESIZE_TRAIN" -gt "0" ] && [ "$FILESIZE_VAL" -gt "0" ] ; then
       
        echo "executing remote training..."

        sshpass -e ssh $TRAIN_URL '~/pfs/sequencer/src/Continuous_Learning/continuous-learning-get-and-submit.sh'

        rm -rf $DIFFS_DIR/*
    fi
  
  fi
  sleep 20m

done