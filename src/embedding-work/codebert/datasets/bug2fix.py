import logging
import pickle
import zipfile
from difflib import unified_diff
from pathlib import Path, PurePosixPath
from typing import List

from torch.utils.data import Dataset
from tqdm import tqdm
from unidiff import PatchSet

from .utils import SingleLineFixExample

logger = logging.getLogger(__name__)


def after_patch_path(buggypath):
    buggypath = PurePosixPath(buggypath)
    return str(
        PurePosixPath(
            *("F_dir" if part == "P_dir" else part for part in buggypath.parts)
        )
    )


def decode(bytes_):
    try:
        return bytes_.decode()
    except UnicodeDecodeError:
        pass
    return bytes_.decode("latin-1")


def is_buggy_file(info):
    return not info.is_dir() and "P_dir" in PurePosixPath(info.filename).parts


def is_single_line(file_patch):
    if len(file_patch) == 1:
        hunk = file_patch[0]
        removed_lines = [line for line in hunk if line.is_removed]
        added_lines = [line for line in hunk if line.is_added]
        if len(removed_lines) == 1 and len(added_lines) == 1:
            removed, added = removed_lines[0], added_lines[0]
            if removed.source_line_no == added.target_line_no:
                return True
    return False


def get_fixed_line(file_patch):
    hunk = file_patch[0]
    added = next(line for line in hunk if line.is_added)
    return added.value, added.target_line_no


def get_buggy_pairs(myzip):
    info_pairs = []
    n_missing_fixed_pair = 0
    for buggyinfo in filter(is_buggy_file, myzip.infolist()):
        try:
            fixedinfo = myzip.getinfo(after_patch_path(buggyinfo.filename))
            info_pairs.append((buggyinfo, fixedinfo))
        except KeyError:
            n_missing_fixed_pair += 1
            continue
    if n_missing_fixed_pair:
        logger.warn(
            f"Found {n_missing_fixed_pair} buggy files without a fixed counterpart."
        )
    return info_pairs


def extract_single_line_patches(zip_path):
    logger.info(f"Extracting examples from {zip_path}, this might take a while.")
    examples = []
    with zipfile.ZipFile(zip_path) as rawzip:
        # I think the first member is the base dir
        base_path = rawzip.infolist()[0].filename

        info_pairs = get_buggy_pairs(rawzip)

        logger.info(f"Found {len(info_pairs)} buggy java files.")
        logger.info("Filtering single line patches...")
        for buggyinfo, fixedinfo in tqdm(
            info_pairs,
            desc="Progress",
            disable=not logger.isEnabledFor(logging.INFO),
            unit="files",
        ):
            with rawzip.open(buggyinfo) as buggyfile, rawzip.open(
                fixedinfo
            ) as fixedfile:
                buggy_code = decode(buggyfile.read())
                fixed_code = decode(fixedfile.read())
            diff = list(
                unified_diff(
                    buggy_code.splitlines(keepends=True),
                    fixed_code.splitlines(keepends=True),
                    fromfile=buggyinfo.filename,
                    tofile=fixedinfo.filename,
                )
            )
            patch = PatchSet(diff)
            for file_patch in patch:
                if is_single_line(file_patch):
                    fixed_line, lineno = get_fixed_line(file_patch)
                    id_ = str(PurePosixPath(buggyinfo.filename).relative_to(base_path))
                    examples.append(
                        SingleLineFixExample(id_, buggy_code, fixed_line, lineno)
                    )
    # Hopefully this frees some memory
    del rawzip
    return examples


class Bug2FixSingleLine(Dataset):
    DATASET_NAME = "bug2fix"
    RAW_FILE = "bug-fixes.zip"
    CACHED_FILE = "bug2fix-singleline-cached.pkl"

    examples: List[SingleLineFixExample]
    dataset_dir: Path

    def __init__(self, root):
        self.dataset_path = Path(root) / self.DATASET_NAME
        cache_path = self.dataset_path / self.CACHED_FILE
        if cache_path.exists():
            logger.info(f"Loading cached file {cache_path}")
            with open(cache_path, "rb") as file:
                self.examples = pickle.load(file)
            return

        raw_file_path = self.dataset_path / self.RAW_FILE
        assert raw_file_path.exists(), (
            f"Couldn't find {raw_file_path}!"
            " You can manually put it there and retry."
            " The file can be found here https://sites.google.com/view/learning-fixes/data."
        )

        self.examples = extract_single_line_patches(raw_file_path)

        logger.info(f"Found {len(self.examples)} single line patches.")
        logger.info(f"Writing examples to {cache_path}.")
        self.dataset_path.mkdir(parents=True, exist_ok=True)
        try:
            with open(cache_path, "wb") as cachefile:
                pickle.dump(self.examples, cachefile)
        except BaseException as e:
            if cache_path.exists():
                cache_path.unlink()
            raise e from None

    def __getitem__(self, key):
        return self.examples[key]

    def __len__(self):
        return len(self.examples)

    def __iter__(self):
        yield from self.examples
