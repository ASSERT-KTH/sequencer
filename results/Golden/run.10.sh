#! /bin/bash

hostname
data_path=`/bin/pwd`
translateBFP.10.sh 2>&1 > translateBFP.10.nohup.out
translate1klim.10.sh 2>&1 > translate1klim.10.nohup.out
translate.10.sh 2>&1 > translate.10.nohup.out
