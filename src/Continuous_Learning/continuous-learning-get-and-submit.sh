#!/bin/bash

set -x

export DATE=`date +"%d%m%Y-%H%M"`
export HOME=/pfs/nobackup$HOME

while [ "$1" != "" ]; do
  case $1 in
    -t | --thread-id )
      THREAD_ID=$2
      shift
      ;;
    -l | --learning-rate )
      LEARNING_RATE=$2
      shift
      ;;
  esac
  shift
done

OpenNMT_py="$HOME/OpenNMT-py"
CONTINUOUS_LEARNING_PATH="$HOME/sequencer/src/Continuous_Learning"
DEFECTS4J_EXPERMENT_PATH="$HOME/sequencer/src/Defects4J_Experiment"

export DATA_PATH="$CONTINUOUS_LEARNING_PATH/processed/$DATE/$THREAD_ID"
VOCABULARY="$HOME/sequencer/results/Golden/vocab.txt"

MODEL_PATH="$CONTINUOUS_LEARNING_PATH/models"
MODEL_TESTING_PATH="$HOME/sequencer/model"

FILE_SERVER_URL="http://sequencer.westeurope.cloudapp.azure.com:8080"

TRAIN_SOURCE_FILE="$DATA_PATH/src-train.txt"
TRAIN_TARGET_FILE="$DATA_PATH/tgt-train.txt"

VALIDATION_SOURCE_FILE="$DATA_PATH/src-val.txt"
VALIDATION_TARGET_FILE="$DATA_PATH/tgt-val.txt"

SNIC_JOB_FILE="$CONTINUOUS_LEARNING_PATH/jobscript"

if [ -z "$THREAD_ID" ]; then
    echo "THREAD_ID must be set through '-t'"
    exit 1
fi

if [ -z "$LEARNING_RATE" ]; then
    echo "LEARNING_RATE must be set through '-l'"
    exit 1
fi

export LEARNING_RATE=$LEARNING_RATE
export THREAD_ID=$THREAD_ID

mkdir -p $DATA_PATH

curl $FILE_SERVER_URL/src-train > $TRAIN_SOURCE_FILE

if [ $? -ne 0 ]; then
    echo "Could not GET $FILE_SERVER_URL/src-train"
    exit
fi

curl $FILE_SERVER_URL/tgt-train > $TRAIN_TARGET_FILE

if [ $? -ne 0 ]; then
    echo "Could not GET $FILE_SERVER_URL/tgt-train"
    exit
fi

curl $FILE_SERVER_URL/src-val > $VALIDATION_SOURCE_FILE

if [ $? -ne 0 ]; then
    echo "Could not GET $FILE_SERVER_URL/src-val"
    exit
fi

curl $FILE_SERVER_URL/tgt-val > $VALIDATION_TARGET_FILE

if [ $? -ne 0 ]; then
    echo "Could not GET $FILE_SERVER_URL/tgt-val"
    exit
fi


TRAIN_SOURCE_LINES=`wc -l < $TRAIN_SOURCE_FILE`
TRAIN_TARGET_LINES=`wc -l < $TRAIN_TARGET_FILE`

if [ $TRAIN_SOURCE_LINES -ne $TRAIN_TARGET_LINES ]; then
    echo "Training dataset files do not match!"
    exit
fi

VALIDATION_SOURCE_LINES=`wc -l < $VALIDATION_SOURCE_FILE`
VALIDATION_TARGET_LINES=`wc -l < $VALIDATION_TARGET_FILE`

if [ $VALIDATION_SOURCE_LINES -ne $VALIDATION_TARGET_LINES ]; then
    echo "Validation dataset files do not match!"
    exit
fi


JOBS=`squeue -u javierro | tail -n +2`

if ! [ -z "$JOBS" ]; then

  touch last_"$THREAD_ID"_job
  LAST_THREAD_ID_JOB=`cat last_"$THREAD_ID"_job | head -n1`

  if ! [ -z "$LAST_THREAD_ID_JOB" ]; then
      FOUND=`echo $JOBS | grep -o -w $LAST_THREAD_ID_JOB`

      if ! [ -z "$FOUND" ]; then
          echo $FOUND
          DEPENDENCY_PARAM="--dependency=afterok:$FOUND"
      fi
  fi

fi

echo "executing: sbatch $DEPENDENCY_PARAM jobscript"

RET=`sbatch $DEPENDENCY_PARAM $SNIC_JOB_FILE`
JOB_ID=`echo $RET | sed 's/Submitted batch job \([0-9]*\)/\1/'`
echo $JOB_ID > last_"$THREAD_ID"_job

