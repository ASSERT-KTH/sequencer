
if [ -z "$DATE" ]; then
    echo "DATE is not set!"
    exit
fi

CONTINUOUS_LEARNING_PATH="$HOME/sequencer/src/Continuous_Learning"
OpenNMT_py="$HOME/OpenNMT-py"
MODEL_PATH="$CONTINUOUS_LEARNING_PATH/models"
DATA_PATH="$HOME/sequencer/results/Golden/"
RESULT_PATH="$CONTINUOUS_LEARNING_PATH/Codrep_Results/$DATE"

mkdir $RESULT_PATH

LAST_MODEL=`ls -t $MODEL_PATH/final-model_step_* | head -n1`

cd $OpenNMT_py
python3 translate.py -model $LAST_MODEL -src $DATA_PATH/src-test.txt -beam_size 50 -n_best 50 -output $RESULT_PATH/predictions.txt -dynamic_dict > $RESULT_PATH/translate.out 2>&1 

cd $CONTINUOUS_LEARNING_PATH
python3 codrep_compare.py $RESULT_PATH/predictions.txt $DATA_PATH/tgt-test.txt $RESULT_PATH/result.txt > $RESULT_PATH/compare.out 2>&1


