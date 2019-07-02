#! /bin/bash


if [ ! -f $OpenNMT_py/preprocess.py ]; then
    print "OpenNMT_py environment variable should be set"
    exit 1
fi
if [ ! -d $data_path ]; then
    data_path="/home/z/zimin/pfs/deepmutation_OpenNMT/data/50"
    if [ ! -d $data_path ]; then
        # For now, choose between 2 hard coded paths - Zimin's and Steve's
        data_path="/s/chopin/l/grad/steveko/p/codrep/deepmutation_OpenNMT/data/50"
    fi
fi
cd $OpenNMT_py
python train.py -data $data_path/final -encoder_type brnn -enc_layers 2 -decoder_type rnn -dec_layers 2 -rnn_size 256 -global_attention general -batch_size 32 -word_vec_size 256 -bridge -copy_attn -reuse_copy_attn -train_steps 20000 -gpu_ranks 0 -save_checkpoint_steps 10000 -save_model $data_path/final-model > $data_path/train.final.out
echo "train.sh complete" >> $data_path/train.out
