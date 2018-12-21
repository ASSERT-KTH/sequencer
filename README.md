# SequenceR

Todos:

* upload golden model
* upload 950 successfull diffs in CR4
* create real end-2-end sequencer.py
* add arxiv info in bibtex below

SequenceR is a seq2seq model designed to predict source code change on line level. (TODO, add result from our paper).

If you use SequenceR for academic purposes, please cite the following publication:
```
@techreport{sequencer2018,

}
```

# Usage

First run `setup_env.sh` to setup enviroment and clone/compile project. Please view `setup_env.sh` for more details.

Then run `end-to-end.sh` with the following parameters:
```bash
./end-to-end.sh --buggy_file=[abs path] --buggy_line=[int] --beam_size=[int] --output=[abs path]
```
* --buggy_file: Absolute path to buggy file
* --buggy_line: Line number indicating where the bug is, or just want it get changed.
* --beam_size: Beam size for prediction
* --output: Output directory to store the generated patches

# Defects4J experiment

In `Defects4J_patches/` you can find all patches that are found by SequencerR, In `Defects4J_patches/Defects4J_patches_beam[x]` means that the beam size was set to `x` during the execution. Patches that are stored in `*_compiled` are patches that compiled. Patches that are stored in `*_passed` are patches that compiled and passed the test suite. 

To rerun our experiment of SequenceR over [Defects4J](https://github.com/rjust/defects4j). Run `Defects4J/Defects4J_oneLinerFix.sh`, make sure you have `defects4j` installed.

`Defects4J_oneLiner_metadata.csv` contains metadata for all Defects4J bugs that we consider. `src/validatePatch.py` contains the precedure for running Defects4J test, we have time limit on compile time (30s) and test running time (120s).
