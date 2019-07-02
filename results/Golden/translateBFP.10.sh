#! /bin/bash

cd $OpenNMT_py
python translate.py -model $data_path/final-model_step_10000.pt -src $data_path/srcBFP-test.txt -beam_size 50 -n_best 50 -output $data_path/predBFP-test_beam50.10.txt -dynamic_dict 2>&1 > $data_path/translateBFP50.10.out
