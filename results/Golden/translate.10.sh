#! /bin/bash

cd $OpenNMT_py
python translate.py -model $data_path/final-model_step_10000.pt -src $data_path/src-test.txt -beam_size 50 -n_best 50 -output $data_path/pred-test_beam50.10.txt -dynamic_dict 2>&1 > $data_path/translate50.10.out
