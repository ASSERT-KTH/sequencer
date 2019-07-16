# SequenceR

SequenceR is a seq2seq model designed to predict source code change on line level.

If you use SequenceR for academic purposes, please cite the following publication:
```
@article{chen2018sequencer,
  title={SequenceR: Sequence-to-Sequence Learning for End-to-End Program Repair},
  author={Chen, Zimin and Kommrusch, Steve and Tufano, Michele and Pouchet, Louis-No{\"e}l and Poshyvanyk, Denys and Monperrus, Martin},
  journal={arXiv preprint arXiv:1901.01808},
  year={2018}
}
```

# Java repair usage

## Docker

Simply run the following two commands to set up use of the SequenceR Golden model:
```bash
docker build --tag=sequencer .
docker run -it sequencer
```

And now all dependecies are installed (including defects4j).

## Without docker

### Install dependencies

First run `src/setup_env.sh` to setup enviroment and clone/compile project. Please view `src/setup_env.sh` for more details.

### Usage

Then run `src/sequencer-predict.sh` with the following parameters:
```bash
./sequencer-predict.sh --buggy_file=[abs path] --buggy_line=[int] --beam_size=[int] --output=[abs path]
```
* --buggy_file: Absolute path to buggy file
* --buggy_line: Line number indicating where the bug is, or just want it get changed.
* --beam_size: Beam size for prediction
* --output: Output directory to store the generated patches

### Defects4J experiment

In `results/Defects4J_patches` you can find all patches that are found by SequencerR. Patches that are stored in `*_compiled` are patches that compiled. Patches that are stored in `*_passed` are patches that compiled and passed the test suite. Patches that are stored in `*_correct` are patches that compiled, passed the test suite and are equivalent to the human patch.

To rerun our experiment of SequenceR over [Defects4J](https://github.com/rjust/defects4j). Run `src/Defects4J_Experiment/Defects4J_experiment.sh`, make sure you have `defects4j` installed.

`Defects4J_oneLiner_metadata.csv` contains metadata for all Defects4J bugs that we consider. `src/Defects4J_Experiment/validatePatch.py` contains the precedure for running Defects4J test, we have time limit on compile time (60s) and test running time (300s).

# Model creation, training and use:

## Open NMT

SequenceR uses the OpenNMT library to set up program repair as a translation from buggy code to fixed code. Documentation on OpenNMT including parameter setup is at:

http://opennmt.net/OpenNMT-py/

## Setup

Choose a directory and:
git clone https://github.com/OpenNMT/OpenNMT-py
git clone https://github.com/kth-tcs/seq2seq4repair-experiments.git

Set up environment variables:

export CUDA_VISIBLE_DEVICES=0
export THC_CACHING_ALLOCATOR=0
export seq2seq4repair=.../seq2seq4repair-experiments
export OpenNMT_py=.../OpenNMT-py
export data_path=.../results/Golden  # Or a new directory path as desired

## Train

For details on model training, refer to OpenNMT documentation. To run SequenceR training:

cd src
sequencer-train.sh

## Test

For details on model usage (translation), refer to OpenNMT documentation. To run SequenceR testing:

cd src
sequencer-test.sh
