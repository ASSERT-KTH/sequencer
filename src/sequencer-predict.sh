#!/bin/bash

echo "sequencer-predict.sh start"

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ROOT_DIR="$(dirname "$CURRENT_DIR")"

HELP_MESSAGE=$'Usage: ./sequencer-predict.sh --model=[model path] --buggy_file=[abs path] --buggy_line=[int] --beam_size=[int] --output=[abs path]
model: Absolute path to the model
buggy_file: Absolute path to the buggy file
buggy_line: Line number of buggy line
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
    --beam_size=*)
    BEAM_SIZE="${i#*=}"
    shift # past argument=value
    ;;
    --output=*)
    OUTPUT="${i#*=}"
    shift # past argument=value
    ;;
    --model=*)
    MODEL="${i#*=}"
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

if [ -z "$MODEL" ]; then
  echo "MODEL unset!"
  echo "$HELP_MESSAGE"
  exit 1
elif [[ "$MODEL" != /* ]]; then
  echo "MODEL must be absolute path"
  echo "$HELP_MESSAGE"
  exit 1
fi

echo "Input parameter:"
echo "BUGGY_FILE_PATH = ${BUGGY_FILE_PATH}"
echo "BUGGY_LINE = ${BUGGY_LINE}"
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
java -jar $CURRENT_DIR/Buggy_Context_Abstraction/abstraction/lib/abstraction-1.0-SNAPSHOT-jar-with-dependencies.jar $BUGGY_FILE_PATH $BUGGY_LINE $CURRENT_DIR/tmp
retval=$?
if [ $retval -ne 0 ]; then
  echo "Cannot generate abstraction for the buggy file"
  rm -rf $CURRENT_DIR/tmp
  exit 1
fi
echo

echo "Tokenizing the abstraction"
python3 $CURRENT_DIR/Buggy_Context_Abstraction/tokenize.py $CURRENT_DIR/tmp/${BUGGY_FILE_BASENAME}_abstract.java $CURRENT_DIR/tmp/${BUGGY_FILE_BASENAME}_abstract_tokenized.txt
retval=$?
if [ $retval -ne 0 ]; then
  echo "Tokenization failed"
  rm -rf $CURRENT_DIR/tmp
  exit 1
fi
echo

echo "Truncate the abstraction to 1000 tokens"
perl $CURRENT_DIR/Buggy_Context_Abstraction/trimCon.pl $CURRENT_DIR/tmp/${BUGGY_FILE_BASENAME}_abstract_tokenized.txt $CURRENT_DIR/tmp/${BUGGY_FILE_BASENAME}_abstract_tokenized_truncated.txt 1000
retval=$?
if [ $retval -ne 0 ]; then
  echo "Truncation failed"
  rm -rf $CURRENT_DIR/tmp
  exit 1
fi
echo

echo "Generating predictions"
python3 $CURRENT_DIR/lib/OpenNMT-py/translate.py -model $MODEL -src $CURRENT_DIR/tmp/${BUGGY_FILE_BASENAME}_abstract_tokenized_truncated.txt -output $CURRENT_DIR/tmp/predictions.txt -beam_size $BEAM_SIZE -n_best $BEAM_SIZE 1>/dev/null
echo

echo "Post process predictions"
python3 $CURRENT_DIR/Patch_Preparation/postPrcoessPredictions.py $CURRENT_DIR/tmp/predictions.txt $CURRENT_DIR/tmp
retval=$?
if [ $retval -ne 0 ]; then
  echo "Post process generates none valid predictions"
  rm -rf $CURRENT_DIR/tmp
  exit 1
fi
echo

echo "Creating output directory ${OUTPUT}"
mkdir -p $OUTPUT
echo

echo "Generating patches"
python3 $CURRENT_DIR/Patch_Preparation/generatePatches.py $BUGGY_FILE_PATH $BUGGY_LINE $CURRENT_DIR/tmp/predictions_JavaSource.txt $OUTPUT
echo

echo "Generating diffs"
for patch in $OUTPUT/*; do
  diff -u -w $BUGGY_FILE_PATH $patch/$BUGGY_FILE_NAME > $patch/diff
done
echo


echo "Cleaning tmp folder"
rm -rf $CURRENT_DIR/tmp
echo

echo "Found $(ls $OUTPUT | wc -l | awk '{print $1}') patches for $BUGGY_FILE_NAME stored in $OUTPUT"
echo "sequencer-predict.sh done"
echo
exit 0
