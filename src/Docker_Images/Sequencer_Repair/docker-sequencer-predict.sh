#!/bin/bash

echo "sequencer-predict.sh start"

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ROOT_DIR="$(dirname "$CURRENT_DIR")"

HELP_MESSAGE=$'Usage: ./sequencer-predict.sh --buggy_file=[absolute path] --buggy_line=[int] --models_dir=[absolute path] --beam_size=[int] --output=[absolute path]
buggy_file: Absolute path to the buggy file
buggy_line: Line number of buggy line
models_dir: Absolute path to the models direcotry
beam_size: Beam size used in seq2seq model
output: Absolute path for output'
for i in "$@"
do
case $i in
    --buggy_file=*)
    BUGGY_FILE_PATH="${i#*=}"
    shift # past argument=value
    ;;
    --buggy_line=*)
    BUGGY_LINE="${i#*=}"
    shift # past argument=value
    ;;
    --models_dir=*)
    MODELS_DIR="${i#*=}"
    shift # past argument=value
    ;;
    --beam_size=*)
    BEAM_SIZE="${i#*=}"
    shift # past argument=value
    ;;
    --output=*)
    OUTPUT="${i#*=}"
    shift # past argument=value
    ;;
    --real_file_path=*)
    REAL_FILE_PATH="${i#*=}"
    shift # past argument=value
    ;;
    *)
          # unknown option
    ;;
esac
done

if [ -z "$BUGGY_FILE_PATH" ]; then
  echo "BUGGY_FILE_PATH unset!"
  echo "$HELP_MESSAGE"
  exit 1
elif [[ "$BUGGY_FILE_PATH" != /* ]]; then
  echo "BUGGY_FILE_PATH must be absolute path"
  echo "$HELP_MESSAGE"
  exit 1
fi

if [ -z "$BUGGY_LINE" ]; then
  echo "BUGGY_LINE unset!"
  echo "$HELP_MESSAGE"
  exit 1
fi

if [ -z "$MODELS_DIR" ]; then
  echo "MODELS_DIR unset!"
  echo "$HELP_MESSAGE"
  exit 1
elif [[ "$MODELS_DIR" != /* ]]; then
  echo "MODELS_DIR must be absolute path"
  echo "$HELP_MESSAGE"
  exit 1
fi

if [ -z "$BEAM_SIZE" ]; then
  echo "BEAM_SIZE unset!"
  echo "$HELP_MESSAGE"
  exit 1
fi

if [ -z "$OUTPUT" ]; then
  echo "OUTPUT unset!"
  echo "$HELP_MESSAGE"
  exit 1
elif [[ "$OUTPUT" != /* ]]; then
  echo "OUTPUT must be absolute path"
  echo "$HELP_MESSAGE"
  exit 1
fi

echo "Input parameter:"
echo "BUGGY_FILE_PATH = ${BUGGY_FILE_PATH}"
echo "BUGGY_LINE = ${BUGGY_LINE}"
echo "MODELS_DIR = ${MODELS_DIR}"
echo "BEAM_SIZE = ${BEAM_SIZE}"
echo "OUTPUT = ${OUTPUT}"
echo

BUGGY_FILE_NAME=${BUGGY_FILE_PATH##*/}
BUGGY_FILE_BASENAME=${BUGGY_FILE_NAME%.*}

echo "Creating temporary working folder"
mkdir -p $CURRENT_DIR/tmp
echo

echo "Abstracting the source file"
# the code of abstraction-1.0-SNAPSHOT-jar-with-dependencies.jar is in https://github.com/KTH/sequencer/tree/master/src/Buggy_Context_Abstraction/abstraction
java -jar ./tools/abstraction.jar $BUGGY_FILE_PATH $BUGGY_LINE $CURRENT_DIR/tmp
retval=$?
if [ $retval -ne 0 ]; then
  echo "Cannot generate abstraction for the buggy file"
  rm -rf $CURRENT_DIR/tmp
  exit 1
fi
echo

echo "Tokenizing the abstraction"
python3 ./tools/tokenize.py $CURRENT_DIR/tmp/${BUGGY_FILE_BASENAME}_abstract.java $CURRENT_DIR/tmp/${BUGGY_FILE_BASENAME}_abstract_tokenized.txt
retval=$?
if [ $retval -ne 0 ]; then
  echo "Tokenization failed"
  rm -rf $CURRENT_DIR/tmp
  exit 1
fi
echo

echo "Truncate the abstraction to 1000 tokens"
perl ./tools/trimCon.pl $CURRENT_DIR/tmp/${BUGGY_FILE_BASENAME}_abstract_tokenized.txt $CURRENT_DIR/tmp/${BUGGY_FILE_BASENAME}_abstract_tokenized_truncated.txt 1000
retval=$?
if [ $retval -ne 0 ]; then
  echo "Truncation failed"
  rm -rf $CURRENT_DIR/tmp
  exit 1
fi
echo

for MODEL_PATH in ${MODELS_DIR}/*.pt;
do
  rm -f $CURRENT_DIR/tmp/predictions.txt

  echo "Generating predictions from ${MODEL_PATH}"
  python3 ./tools/OpenNMT-py/translate.py -model $MODEL_PATH -src $CURRENT_DIR/tmp/${BUGGY_FILE_BASENAME}_abstract_tokenized_truncated.txt -output $CURRENT_DIR/tmp/predictions.txt -beam_size $BEAM_SIZE -n_best $BEAM_SIZE 1>/dev/null
  echo

  echo "Post process predictions from ${MODEL_PATH}"
  python3 ./tools/postProcessPredictions.py $CURRENT_DIR/tmp/predictions.txt $CURRENT_DIR/tmp
  echo
done

echo "Creating output directory ${OUTPUT}"
mkdir -p $OUTPUT
echo

echo "Generating patches"
python3 ./tools/generatePatches.py $BUGGY_FILE_PATH $BUGGY_LINE $CURRENT_DIR/tmp/predictions_JavaSource.txt $OUTPUT
echo

echo "Generating diffs"
for patch in $OUTPUT/*; do
  echo "--- a/$REAL_FILE_PATH" > $patch/diff
  echo "+++ b/$REAL_FILE_PATH" >> $patch/diff
  diff -u -w $BUGGY_FILE_PATH $patch/$BUGGY_FILE_NAME | tail -n +3 >> $patch/diff
  chmod 777 $patch
  chmod -R 666 $patch/diff
done
echo

chmod 777 $OUTPUT

echo "Cleaning tmp folder"
rm -rf $CURRENT_DIR/tmp
echo

echo "Found $(ls $OUTPUT | wc -l | awk '{print $1}') patches for $BUGGY_FILE_NAME stored in $OUTPUT"
echo "sequencer-predict.sh done"
echo
exit 0
