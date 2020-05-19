set -e
set -x

while [ "$1" != "" ]; do
  case $1 in
    -m | --model-path )
      MODEL_PATH=$2
      shift
      ;;
  esac
  shift
done

if [ -z "$DATE" ]; then
    echo "DATE is not set!"
    exit
fi

if [ -z "$THREAD_ID" ]; then
    echo "THREAD_ID is not set!"
    exit
fi

if [ -z "$MODEL_PATH" ]; then
    echo "MODEL_PATH is not set!"
    exit
fi

CONTINUOUS_LEARNING_PATH="$HOME/sequencer/src/Continuous_Learning"
OpenNMT_py="$HOME/OpenNMT-py"
DATA_PATH="$HOME/sequencer/results/Golden"
RESULT_PATH="$CONTINUOUS_LEARNING_PATH/Codrep_Results/$THREAD_ID/$DATE"

mkdir -p $RESULT_PATH

cd $OpenNMT_py
python3 translate.py -model $MODEL_PATH -src $DATA_PATH/src-test.txt -beam_size 50 -n_best 50 -output $RESULT_PATH/predictions.txt -dynamic_dict > $RESULT_PATH/translate.out 2>&1 

cd $CONTINUOUS_LEARNING_PATH
python3 codrep-compare.py $RESULT_PATH/predictions.txt $DATA_PATH/tgt-test.txt $RESULT_PATH/result.txt > $RESULT_PATH/compare.out 2>&1
