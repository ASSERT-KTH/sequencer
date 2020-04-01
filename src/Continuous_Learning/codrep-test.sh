set -e
set -x


if [ -z "$DATE" ]; then
    echo "DATE is not set!"
    exit
fi

CONTINUOUS_LEARNING_PATH="$HOME/sequencer/src/Continuous_Learning"
OpenNMT_py="$HOME/OpenNMT-py"
# MODEL_PATH="$CONTINUOUS_LEARNING_PATH/models"
MODEL_PATH="$HOME/sequencer/model/model.pt"
DATA_PATH="$HOME/sequencer/results/Golden"
RESULT_PATH="$CONTINUOUS_LEARNING_PATH/Codrep_Results/$DATE"

mkdir -p $RESULT_PATH


cd $OpenNMT_py
python3 translate.py -model $MODEL_PATH -src $DATA_PATH/src-test.txt -beam_size 50 -n_best 50 -output $RESULT_PATH/predictions.txt -dynamic_dict > $RESULT_PATH/translate.out 2>&1 

cd $CONTINUOUS_LEARNING_PATH
python3 codrep-compare.py $RESULT_PATH/predictions.txt $DATA_PATH/tgt-test.txt $RESULT_PATH/result.txt > $RESULT_PATH/compare.out 2>&1


