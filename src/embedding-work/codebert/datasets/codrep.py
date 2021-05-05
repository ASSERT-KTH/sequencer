import logging
import pickle
import zipfile
from pathlib import Path, PurePosixPath
from typing import List

from torch.utils.data import Dataset
from tqdm import tqdm

from .utils import SingleLineFixExample, download

logger = logging.getLogger(__name__)


class CodRep(Dataset):
    DATASET_NAME = "codrep"
    URL = "https://github.com/KTH/CodRep-competition/archive/refs/heads/master.zip"
    RAW_FILE = "codrep-raw.zip"
    CACHED_FILE_TEMPLATE = "codrep-{}-cached.pkl"

    examples: List[SingleLineFixExample]
    split: int

    def __init__(self, root, *, split):
        assert split in (1, 2, 3, 4, 5), "Invalid split!"
        self.split = split

        cache_path = (
            Path(root) / self.DATASET_NAME / self.CACHED_FILE_TEMPLATE.format(split)
        )
        if cache_path.exists():
            logger.info(f"Loading cached file {cache_path}")
            with open(cache_path, "rb") as file:
                self.examples = pickle.load(file)
            return

        # Create dataset dir
        dataset_path = Path(root) / self.DATASET_NAME
        dataset_path.mkdir(parents=True, exist_ok=True)

        raw_file_path = dataset_path / self.RAW_FILE
        download(self.URL, str(raw_file_path), size_estimate=250)

        # Extract and create examples
        base = PurePosixPath(f"CodRep-competition-master/Datasets/Dataset{split}")
        tasks_base = base / "Tasks"
        solutions_base = base / "Solutions"
        self.examples = []
        logger.info(f"Extracting examples from {base} in {raw_file_path}.")
        with zipfile.ZipFile(raw_file_path) as rawzip:
            tasklist = [
                info
                for info in rawzip.infolist()
                if PurePosixPath(info.filename).parent == tasks_base
            ]
            for taskinfo in tqdm(
                tasklist,
                desc="Progress",
                disable=not logger.isEnabledFor(logging.INFO),
                unit="files",
            ):
                with rawzip.open(taskinfo) as taskfile:
                    task = taskfile.read().decode()
                fixed_line, _, buggy_code = task.split("\n", maxsplit=2)
                taskpath = PurePosixPath(taskinfo.filename)
                with rawzip.open(str(solutions_base / taskpath.name)) as solutionfile:
                    lineno = int(solutionfile.read().decode())
                id_ = taskpath.stem

                self.examples.append(
                    SingleLineFixExample(id_, buggy_code, fixed_line, lineno)
                )

        logger.info(f"Writing examples to {cache_path}")
        with open(cache_path, "wb") as cachefile:
            pickle.dump(self.examples, cachefile)

    def __getitem__(self, key):
        return self.examples[key]

    def __len__(self):
        return len(self.examples)

    def __iter__(self):
        yield from self.examples
