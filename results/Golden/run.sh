#! /bin/bash

hostname
data_path=`/bin/pwd`
preprocess.sh 2>&1 > preprocess.nohup.out
train.sh 2>&1 > train.nohup.out
translateBFP.sh 2>&1 > translateBFP.nohup.out
translate1klim.sh 2>&1 > translate1klim.nohup.out
translate.sh 2>&1 > translate.nohup.out
