# SequenceR

Todos:

* ~~upload golden model~~
* ~~Update Defects4J result with golden model~~
* upload 950 successfull diffs in CR4
* create real end-2-end sequencer.py
* ~~add arxiv info in bibtex below~~

SequenceR is a seq2seq model designed to predict source code change on line level. (TODO, add result from our paper).

If you use SequenceR for academic purposes, please cite the following publication:
```
@article{chen2018sequencer,
  title={SequenceR: Sequence-to-Sequence Learning for End-to-End Program Repair},
  author={Chen, Zimin and Kommrusch, Steve and Tufano, Michele and Pouchet, Louis-No{\"e}l and Poshyvanyk, Denys and Monperrus, Martin},
  journal={arXiv preprint arXiv:1901.01808},
  year={2018}
}
```

# Usage

## Docker

Simply run the following two commands:
```bash
docker build --tag=sequencer .
docker run -it sequencer
```

And now all dependecies are installed (including defects4j).

## Without docker

### Install dependencies

First run `src/setup_env.sh` to setup enviroment and clone/compile project. Please view `src/setup_env.sh` for more details.

### Usage

Then run `src/end-to-end.sh` with the following parameters:
```bash
./end-to-end.sh --buggy_file=[abs path] --buggy_line=[int] --beam_size=[int] --output=[abs path]
```
* --buggy_file: Absolute path to buggy file
* --buggy_line: Line number indicating where the bug is, or just want it get changed.
* --beam_size: Beam size for prediction
* --output: Output directory to store the generated patches

### Defects4J experiment

In `results/Defects4J_patches` you can find all patches that are found by SequencerR. Patches that are stored in `*_compiled` are patches that compiled. Patches that are stored in `*_passed` are patches that compiled and passed the test suite. Patches that are stored in `*_correct` are patches that compiled, passed the test suite and are equivalent to the human patch.

To rerun our experiment of SequenceR over [Defects4J](https://github.com/rjust/defects4j). Run `src/Defects4J_Experiment/Defects4J_experiment.sh`, make sure you have `defects4j` installed.

`Defects4J_oneLiner_metadata.csv` contains metadata for all Defects4J bugs that we consider. `src/Defects4J_Experiment/validatePatch.py` contains the precedure for running Defects4J test, we have time limit on compile time (60s) and test running time (300s).
