#! /bin/bash

echo "sequencer-train.sh start"

HELP_MESSAGE=$'Usage: ./sequencer-train.sh
Depends on environment variable settings
export OpenNMT_py=.../OpenNMT-py
export data_path=.../results/Golden  # Or a new directory path as desired'

if [ ! -f $OpenNMT_py/preprocess.py ]; then
  echo "OpenNMT_py environment variable should be set"
  echo "$HELP_MESSAGE"
  exit 1
fi
if [ ! -f $data_path/train.sh ]; then
  echo "data_path environment variable should be set"
  echo "$HELP_MESSAGE"
  exit 1
fi

cd $data_path
echo "Starting data preprocessing"
# Change code in preprocess.sh to adjust OpenNMT parameters (like vocab size)
./preprocess.sh
echo "Starting training"
# Change code in train.sh to adjust OpenNMT parameters (like LSTM layer count)
./train.sh

echo "sequencer-train.sh done"
echo
exit 0
