# SequenceR: SequenceR: Sequence-to-Sequence Learning for End-to-End Program Repair

SequenceR is a seq2seq model designed to predict source code change on line level. The [paper](http://arxiv.org/pdf/1901.01808) ([doi:10.1109/TSE.2019.2940179](https://doi.org/10.1109/TSE.2019.2940179)) explains the approach.

If you use SequenceR for academic purposes, please cite the following publication:
```
@article{chen2018sequencer,
  title={SequenceR: Sequence-to-Sequence Learning for End-to-End Program Repair},
  author={Chen, Zimin and Kommrusch, Steve and Tufano, Michele and Pouchet, Louis-No{\"e}l and Poshyvanyk, Denys and Monperrus, Martin},
  journal={IEEE Transaction on Software Engineering},
  year={2019}
}
```

## Usage

### Docker

Simply run the following two commands to set up use of the SequenceR Golden model:
```bash
docker build --tag=sequencer .
docker run -it sequencer
```

And now all dependecies are installed (including defects4j).

Or, use our [this version](https://cloud.docker.com/repository/docker/zimin/sequencer) from the Docker Hub.

### Without docker

**Install dependencies**

First run `src/setup_env.sh` to setup enviroment and clone/compile project. Please view `src/setup_env.sh` for more details.

All models are versioned using [git-lfs](https://git-lfs.github.com/), make sure to configure it and correctly fetch the models before using.

**Execution**

Then run `src/sequencer-predict.sh` with the following parameters:
```bash
./sequencer-predict.sh --buggy_file=[abs path] --buggy_line=[int] --beam_size=[int] --output=[abs path]
```
* --buggy_file: Absolute path to buggy file
* --buggy_line: Line number indicating where the bug is, or just want it get changed.
* --beam_size: Beam size for prediction
* --output: Output directory to store the generated patches

## Experiments

### CodRep experiment

The training data consists of `results/Golden/src-train.txt` and `results/Golden/tgt-train.txt` (line to line correspondence).

The CodRep4 testing data consists of `results/Golden/src-test.txt` and `results/Golden/tgt-test.txt` (line to line correspondence).

### Defects4J experiment

In `results/Defects4J_patches` you can find all patches that are found by SequencerR. Patches that are stored in `*_compiled` are patches that compiled. Patches that are stored in `*_passed` are patches that compiled and passed the test suite. Patches that are stored in `*_correct` are patches that compiled, passed the test suite and are equivalent to the human patch.

To rerun our experiment of SequenceR over [Defects4J](https://github.com/rjust/defects4j). Run `src/Defects4J_Experiment/Defects4J_experiment.sh`, make sure you have `defects4j` installed.

`Defects4J_oneLiner_metadata.csv` contains metadata for all Defects4J bugs that we consider. `src/Defects4J_Experiment/validatePatch.py` contains the precedure for running Defects4J test, we have time limit on compile time (60s) and test running time (300s).

## Model creation, training and use:

### Prerequisites

SequenceR uses the OpenNMT library to set up program repair as a translation from buggy code to fixed code. Documentation on OpenNMT including parameter setup is at http://opennmt.net/OpenNMT-py/

### Setup

Choose a directory and:
```bash
git clone https://github.com/OpenNMT/OpenNMT-py
```
When testing a new configuration, copy a working data directory and modify *sh files as desired.

Set up environment variables:

```bash
export CUDA_VISIBLE_DEVICES=0
export THC_CACHING_ALLOCATOR=0
export OpenNMT_py=.../OpenNMT-py
export data_path=.../results/Golden  # Or a new directory path as desired
```

### Train

For details on model training, refer to OpenNMT documentation. To run SequenceR training:

```bash
cd src
sequencer-train.sh
```

### Test

For details on model usage (translation), refer to OpenNMT documentation. To run SequenceR testing:

```bash
cd src
sequencer-test.sh
```

## License

The code and data in this repository are under the MIT license.
