#!/bin/bash

set -e

mkdir -p tools
cp ../../Buggy_Context_Abstraction/abstraction/lib/abstraction-1.0-SNAPSHOT-jar-with-dependencies.jar tools/abstraction.jar
cp ../../Buggy_Context_Abstraction/tokenize.py tools
cp ../../Buggy_Context_Abstraction/trimCon.pl tools
cp ../../Patch_Preparation/generatePatches.py tools
cp ../../Patch_Preparation/postProcessPredictions.py tools

mkdir -p models
cp ../../../results/Golden/golden-model.pt models/

docker build . --tag repairnator/sequencer:2.0

rm -rf tools/
rm -rf models/
