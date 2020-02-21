
OpenNMT_py=$HOME/OpenNMT_py
MODEL_PATH=$HOME/sequencer/src/Continuous_Learning/models
DATA_PATH=$HOME/sequencer/results/Golden/
RESULT_PATH=$HOME/sequencer/src/Continuous_Learning/Codrep_Results/$DATE

LAST_MODEL=`ls -t $MODEL_PATH/final-model_step_* | head -n1`

cd $OpenNMT_py
python translate.py -model $LAST_MODEL -src $DATA_PATH/src-test.txt -beam_size 50 -n_best 50 -output $RESULT_PATH/codrep-result.txt -dynamic_dict 2>&1 > $RESULT_PATH/translate.out

