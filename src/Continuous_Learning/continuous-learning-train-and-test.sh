#! /bin/bash

set -e
set -x

if [ -z "$DATA_PATH" ]; then
    echo "DATA_PATH is not set!"
    exit
fi

if [ -z "$DATE" ]; then
    echo "DATE is not set!"
    exit
fi

export PATH=$PATH:"$HOME/defects4j/framework/bin"

OpenNMT_py="$HOME/OpenNMT-py"
CONTINUOUS_LEARNING_PATH="$HOME/sequencer/src/Continuous_Learning"
DEFECTS4J_EXPERMENT_PATH="$HOME/sequencer/src/Defects4J_Experiment"

VOCABULARY="$HOME/sequencer/results/Golden/vocab.txt"

MODEL_PATH="$CONTINUOUS_LEARNING_PATH/models"
MODEL_TESTING_PATH="$HOME/sequencer/model"

FILE_SERVER_URL="http://sequencer.westeurope.cloudapp.azure.com:8080" # set this up

TRAIN_SOURCE_FILE="$DATA_PATH/src-train.txt"
TRAIN_TARGET_FILE="$DATA_PATH/tgt-train.txt"

VALIDATION_SOURCE_FILE="$DATA_PATH/src-val.txt"
VALIDATION_TARGET_FILE="$DATA_PATH/tgt-val.txt"

TRAIN_SOURCE_LINES=`wc -l < $TRAIN_SOURCE_FILE`
TRAIN_TARGET_LINES=`wc -l < $TRAIN_TARGET_FILE`

TRAINING_STEPS=500
LEARNING_RATE=0.25

if [ $TRAIN_SOURCE_LINES -ne $TRAIN_TARGET_LINES ]; then
    echo "Training dataset files do not match!"
    exit
fi

VALIDATION_SOURCE_LINES=`wc -l < $VALIDATION_SOURCE_FILE`
VALIDATION_TARGET_LINES=`wc -l < $VALIDATION_TARGET_FILE`

if [ $VALIDATION_SOURCE_LINES -ne $VALIDATION_TARGET_LINES ]; then
    echo "Validation dataset files do not match!"
    exit
fi

cd $CONTINUOUS_LEARNING_PATH


cd $OpenNMT_py
python preprocess.py -src_vocab $VOCABULARY -train_src $TRAIN_SOURCE_FILE -train_tgt $TRAIN_TARGET_FILE -valid_src $VALIDATION_SOURCE_FILE -valid_tgt $VALIDATION_TARGET_FILE -src_seq_length 1010 -tgt_seq_length 100 -src_vocab_size 1000 -tgt_vocab_size 1000 -dynamic_dict -share_vocab -save_data $DATA_PATH/final 2>&1 > $DATA_PATH/preprocess.out

TRAIN_STEPS_DIRECTIVE="-train_steps $TRAINING_STEPS"
LEARNING_RATE_DIRECTIVE="-train_steps $TRAINING_STEPS"
TRAIN_FROM_DIRECTIVE=""
if ls $MODEL_PATH/final-model_step_*; then
    LAST_MODEL=`ls -t $MODEL_PATH/final-model_step_* | head -n1`
    TRAIN_FROM_DIRECTIVE="-train_from $LAST_MODEL"
    
    LAST_STEP=`echo $LAST_MODEL | sed 's/.*final-model_step_\([0-9]*\).*/\1/'`
    TRAIN_STEPS_DIRECTIVE="-train_steps $(( $LAST_STEP + $TRAINING_STEPS ))"
fi

python train.py -data $DATA_PATH/final -encoder_type brnn -enc_layers 2 -decoder_type rnn -dec_layers 2 -rnn_size 256 -global_attention general -batch_size 32 -word_vec_size 256 -bridge -copy_attn -reuse_copy_attn $TRAIN_STEPS_DIRECTIVE $LEARNING_RATE_DIRECTIVE -gpu_ranks 0 -save_checkpoint_steps 10000 $TRAIN_FROM_DIRECTIVE -save_model $MODEL_PATH/final-model > $MODEL_PATH/train.final.out

cd $CONTINUOUS_LEARNING_PATH

NEW_MODEL=`ls -Art models/final-model_step_* | tail -n 1`

cp $NEW_MODEL $MODEL_TESTING_PATH/model.pt
cp $NEW_MODEL $MODEL_PATH/model-$DATE.pt

./codrep-test.sh

echo ",$DATE\n" >> $CONTINUOUS_LEARNING_PATH/Codrep_Results/$DATE/result.txt

curl -X POST -d @$CONTINUOUS_LEARNING_PATH/Codrep_Results/$DATE/result.txt $FILE_SERVER_URL/data-codrep


# cd $DEFECTS4J_EXPERMENT_PATH
# ./Defects4J_experiment.sh -l -t
# curl -X POST -d @$CONTINUOUS_LEARNING_PATH/public/single_run_data $FILE_SERVER_URL/data


