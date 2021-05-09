import csv
import logging
import pickle
import re
import tarfile
from io import TextIOWrapper
from pathlib import Path, PurePosixPath
from typing import List, Optional

import jpype
import jpype.imports
from torch.utils.data import Dataset
from tqdm import tqdm

from . import Bug2FixSingleLine, CodRep
from .utils import SingleLineFixExample, download

logger = logging.getLogger(__name__)

# Spoon get stuck when building the model for some files.
# For now I will have to just ignore those. Hopefully they aren't that many
BLACKLIST = (
    "bug2fix_f58c38e5143688f8bb824be0d5148404d5fcb427/P_dir/stag-library/src/main/java/com/vimeo/stag/KnownTypeAdapters.java",
    "bug2fix_6b10bc8f07fb19868c5494b3dc38246515ae2933/P_dir/byte-buddy-dep/src/main/java/net/bytebuddy/asm/Advice.java",
)
# BLACKLIST = []


class SequenceRDataset(Dataset):
    DATASET_NAME = "sequencer"
    CACHED_FILE_TEMPLATE = "sequencer-{split}.pkl"
    SPLITS = ("train", "test")
    PREPROCESSED_URL = (
        "https://zenodo.org/record/4739410/files/sequencer-data.tar.gz?download=1"
    )
    PREPROCESSED_FNAME = "sequencer-preprocessed.tar.gz"

    root: Path
    split: str
    examples: List[SingleLineFixExample]
    abstraction_jar_path: Optional[str]
    # transform_fn: Optional[Callable[[SingleLineFixExample], Any]]

    def __init__(self, root, *, split):
        self.root = Path(root)
        assert split in self.SPLITS
        self.split = split
        self.dataset_path.mkdir(parents=True, exist_ok=True)

    @classmethod
    def from_tar(cls, root, *, split, tarpath=None):
        dataset = cls(root, split=split)

        if dataset.cache_path.exists():
            logger.info(f"Loading cached file {dataset.cache_path}")
            with open(dataset.cache_path, "rb") as file:
                dataset.examples = pickle.load(file)
                return dataset

        if tarpath is None:
            tarpath = dataset.dataset_path / dataset.PREPROCESSED_FNAME
            try:
                download(dataset.PREPROCESSED_URL, tarpath)
            except Exception:
                pass
        else:
            tarpath = Path(tarpath)

        assert tarpath.exists(), f"{tarpath} not found"

        logger.info(f"Loading examples from {tarpath}...")
        with tarfile.open(str(tarpath)) as tar:
            buggyfiles = {}
            fixedlines = {}
            meta = {}
            for member in (
                m for m in tar.getmembers() if m.name.startswith(split) and m.isfile()
            ):
                if member.name.endswith(".java"):
                    buggyfiles[PurePosixPath(member.name).parts[1]] = (
                        tar.extractfile(member).read().decode()
                    )
                elif member.name.endswith(".txt"):
                    fixedlines[PurePosixPath(member.name).parts[1]] = (
                        tar.extractfile(member).read().decode()
                    )
                elif member.name.endswith(".tsv"):
                    reader = csv.reader(
                        TextIOWrapper(tar.extractfile(member)), delimiter="\t"
                    )
                    next(reader)  # ignore first line
                    for row in reader:
                        meta[row[0]] = row[1], int(row[2])
        examples = [
            SingleLineFixExample(
                id=meta[k][0],
                buggy_code=buggyfiles[k],
                fixed_line=fixedlines[k],
                lineno=meta[k][1],
            )
            for k in meta.keys()
        ]
        logger.info(
            f"Loaded a total of {len(examples)} examples for {dataset.split} set."
        )
        logger.info(f"Writing examples to {dataset.cache_path}")
        dataset.cache_path.parent.mkdir(parents=True, exist_ok=True)
        with open(dataset.cache_path, "wb") as file:
            pickle.dump(examples, file)

        dataset.examples = examples
        return dataset

    @classmethod
    def from_raw(cls, root, *, split, abstraction_jar_path):
        dataset = cls(root, split=split)
        assert Path(abstraction_jar_path).exists()
        dataset.abstraction_jar_path = abstraction_jar_path

        if dataset.cache_path.exists():
            logger.info(f"Loading cached file {dataset.cache_path}")
            with open(dataset.cache_path, "rb") as file:
                dataset.examples = pickle.load(file)
                return dataset

        if split == "train":
            examples = dataset._load_train()
        else:
            examples = dataset._load_test()

        logger.info(
            f"Loaded a total of {len(examples)} examples for {dataset.split} set."
        )
        logger.info(f"Writing examples to {dataset.cache_path}")
        with open(dataset.cache_path, "wb") as file:
            pickle.dump(examples, file)
        dataset.examples = examples
        return dataset

    def __getitem__(self, key):
        return self.examples[key]

    def __iter__(self):
        yield from self.examples

    def __len__(self):
        return len(self.examples)

    def __repr__(self):
        return (
            type(self).__name__ + f"({repr(str(self.root))}, split={repr(self.split)})"
        )

    @property
    def cache_path(self):
        return self.dataset_path / self.CACHED_FILE_TEMPLATE.format(split=self.split)

    @property
    def dataset_path(self):
        return Path(self.root) / self.DATASET_NAME

    def _load_test(self):
        examples = [
            example._replace(id="codrep4_" + example.id)
            for example in CodRep(self.root, split=4)
        ]
        return self._preprocess(examples)

    def _load_train(self):
        codrep_splits = (1, 2, 3, 5)
        codrep_datasets = [CodRep(self.root, split=split) for split in codrep_splits]
        bug2fix = Bug2FixSingleLine(self.root)
        # Rename the ids so that they are consistent within this new dataset,
        # since between different codrep splits there are name collisions.
        # Throw bug2fix in there just for the lulz.
        examples = [
            example._replace(id=prefix + example.id)
            for dataset, prefix in zip(
                codrep_datasets + [bug2fix],
                [f"codrep{i}_" for i in codrep_splits] + ["bug2fix_"],
            )
            for example in dataset
        ]
        return self._preprocess(examples)

    def _preprocess(self, examples):
        # Filter examples that are blacklisted
        examples = (example for example in examples if example.id not in BLACKLIST)

        # Filter examples where the fix contains a comment (cases where the buggy line
        # contains a comment will be handled by spoon)
        # The second part of this re is kinda tricky to parse, since asterisk
        # are part of the comment delimiter
        is_comment = re.compile(r"//.*$|/\*.*\*/")
        examples = [
            example
            for example in examples
            if not is_comment.match(example.fixed_line.strip())
        ]

        abstracted = abstract(examples, abstraction_jar_path=self.abstraction_jar_path)
        return abstracted


def abstract(examples, *, abstraction_jar_path):
    """This should be read as a verb, so absTRACT instead of ABStract."""
    if not jpype.isJVMStarted():
        # Sadly, whenever this function is called, the JVM is started and it will
        # remain running until the end of program execution.
        # Since the JVM cannot be restarted, stopping the JVM at the end of the
        # function would mean that it cannot be used again at all.

        classpath = [abstraction_jar_path]
        logger.info(f"Starting JVM with classpath {classpath}")
        jpype.startJVM(classpath=classpath)

    from java.util import ArrayList
    from se.kth.abstraction import AbstractionItem
    from se.kth.abstraction.ContextAbstraction import COMMENT_STRING
    from se.kth.abstraction.ContextAbstraction import runMany as run_abstraction

    COMMENT_STRING = str(COMMENT_STRING)

    logger.info(
        f"Abstracting buggy context for {len(examples)} examples. "
        "This might take a while. (SLF4J saying it was unable to load"
        " is fine)"
    )

    abstracted_sources = []
    with tqdm(desc="Progress", total=len(examples), disable=False) as progress:
        batch_size = 1000
        for batch in _batchify(examples, size=batch_size):
            # print(batch[0].id)
            abstracted = run_abstraction(
                ArrayList([AbstractionItem(e.buggy_code, e.lineno) for e in batch])
            )
            for source in abstracted:
                if source:
                    # Some java Strings come back messed up somehow
                    try:
                        abstracted_sources.append(str(source))
                    except UnicodeDecodeError:
                        abstracted_sources.append(None)
                else:
                    abstracted_sources.append(None)
            progress.update(len(batch))

    # Replace the buggy code and the line number with the abstracted sources
    assert len(examples) == len(abstracted_sources)
    abstracted_examples = []
    for example, abstracted in zip(examples, abstracted_sources):
        if abstracted is not None:
            lines = abstracted.splitlines(keepends=True)
            index = next(i for i, l in enumerate(lines) if COMMENT_STRING in l)
            del lines[index]
            abstracted_examples.append(
                example._replace(buggy_code="".join(lines), lineno=index + 1)
            )

    if len(abstracted_examples) < len(examples):
        logger.warning(
            "Failed to create buggy context for "
            + str(len(examples) - len(abstracted_examples))
            + f" out of {len(examples)} examples."
        )
    return abstracted_examples


def _batchify(elements, *, size):
    start = 0
    while start < len(elements):
        yield elements[start : start + size]
        start += size
