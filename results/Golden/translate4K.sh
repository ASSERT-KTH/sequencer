#! /bin/bash

cd $OpenNMT_py
python translate.py -model $data_path/final-model_step_10000.pt -src $data_path/src4K-test.txt -beam_size 50 -n_best 50 -output $data_path/pred4K-test_beam50.txt -dynamic_dict 2>&1 > $data_path/translate4K50.out
