#! /bin/bash

set -e
set -x

export PATH=$PATH:"$HOME/defects4j/framework/bin"

OpenNMT_py="$HOME/OpenNMT-py"
CONTINUOUS_LEARNING_PATH="$HOME/sequencer/src/Continuous_Learning"
DEFECTS4J_EXPERMENT_PATH="$HOME/sequencer/src/Defects4J_Experiment"

DIFFS_DIR="$HOME/continuous-learning-data"
TOKENIZER="$CONTINUOUS_LEARNING_PATH/tokenizer.pl"
VOCABULARY="$HOME/sequencer/results/Golden/vocab.txt"

DATA_PATH="$CONTINUOUS_LEARNING_PATH/processed"
MODEL_PATH="$CONTINUOUS_LEARNING_PATH/models"
MODEL_TESTING_PATH="$HOME/sequencer/model"

TRAIN_SOURCE_FILE="$DATA_PATH/src-train.txt"
TRAIN_TARGET_FILE="$DATA_PATH/tgt-train.txt"

VALIDATION_SOURCE_FILE="$DATA_PATH/src-val.txt"
VALIDATION_TARGET_FILE="$DATA_PATH/tgt-val.txt"

mkdir -p $DATA_PATH

while :
do
    cd $CONTINUOUS_LEARNING_PATH
    python3 tokenize.py $DIFFS_DIR $DATA_PATH

    FILESIZE_TRAIN=$(stat -c%s "$TRAIN_SOURCE_FILE")
    FILESIZE_VAL=$(stat -c%s "$VALIDATION_SOURCE_FILE")

    if [ "$FILESIZE_TRAIN" -gt "0" ] && [ "$FILESIZE_VAL" -gt "0" ] ; then
       
        rm -rf $DIFFS_DIR/*

        cd $OpenNMT_py
        python3 preprocess.py -src_vocab $VOCABULARY -train_src $DATA_PATH/src-train.txt -train_tgt $DATA_PATH/tgt-train.txt -valid_src $DATA_PATH/src-val.txt -valid_tgt $DATA_PATH/tgt-val.txt -src_seq_length 1010 -tgt_seq_length 100 -src_vocab_size 1000 -tgt_vocab_size 1000 -dynamic_dict -share_vocab -save_data $DATA_PATH/final 2>&1 > $DATA_PATH/preprocess.out

        TRAIN_STEPS_DIRECTIVE="-train_steps 10000"
        TRAIN_FROM_DIRECTIVE=""
        if ls $MODEL_PATH/final-model_step_*; then
            LAST_MODEL=`ls -t $MODEL_PATH/final-model_step_* | head -n1`
            TRAIN_FROM_DIRECTIVE="-train_from $LAST_MODEL"
            
            LAST_STEP=`echo $LAST_MODEL | sed 's/.*final-model_step_\([0-9]*\).*/\1/'`
            TRAIN_STEPS_DIRECTIVE="-train_steps $(( $LAST_STEP + 10000 ))"
        fi

        python3 train.py -data $DATA_PATH/final -encoder_type brnn -enc_layers 2 -decoder_type rnn -dec_layers 2 -rnn_size 256 -global_attention general -batch_size 32 -word_vec_size 256 -bridge -copy_attn -reuse_copy_attn $TRAIN_STEPS_DIRECTIVE -gpu_ranks 0 -save_checkpoint_steps 10000 $TRAIN_FROM_DIRECTIVE -save_model $MODEL_PATH/final-model > $MODEL_PATH/train.final.out

        cd $CONTINUOUS_LEARNING_PATH

        NEW_MODEL=`ls -Art models/final-model_step_* | tail -n 1`

        DATE=`date +"%d%m%Y-%H%M"`
        cp $NEW_MODEL $MODEL_TESTING_PATH/model.pt
        cp $NEW_MODEL $MODEL_PATH/model-$DATE.pt

        cd $DEFECTS4J_EXPERMENT_PATH

        ./Defects4J_experiment.sh -l -t


        rm $DATA_PATH/*
    fi


    sleep 8h

done