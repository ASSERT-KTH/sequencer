#! /bin/bash

cd $OpenNMT_py
python translate.py -model $data_path/final-model_step_20000.pt -src $data_path/src1klim-test.txt -beam_size 50 -n_best 50 -output $data_path/pred1klim-test_beam50.txt -dynamic_dict 2>&1 > $data_path/translate1klim50.out
