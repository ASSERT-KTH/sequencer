import requests
from pathlib import Path
import logging
from tqdm import tqdm
from collections import namedtuple

logger = logging.getLogger(__name__)

SingleLineFixExample = namedtuple(
    "SingleLineFixExample", ("id", "buggy_code", "fixed_line", "lineno")
)


def download(url, out_path, *, size_estimate=None):
    out_path = Path(out_path)
    if out_path.exists():
        logger.warn(f"File {out_path} already exists, skipping.")
        return

    try:
        response = requests.get(url, stream=True)
        total = response.headers.get("Content-Length")
        logger.info(f"Downloading {url} to {out_path}.")
        with open(out_path, "wb") as out_file, tqdm(
            desc="Progress",
            total=total and int(total),
            disable=not logger.isEnabledFor(logging.INFO),
            unit="b",
            unit_scale=True,
            postfix=not total
            and size_estimate
            and f"(should be around {size_estimate}Mb)",
        ) as progress:
            for chunk in response.iter_content(chunk_size=2 ** 18):
                out_file.write(chunk)
                progress.update(len(chunk))
        logger.info(f"Done!")
    except BaseException as e:
        logger.error(f"Something went wrong, deleting {out_path}.")
        if out_path.exists():
            out_path.unlink()
        raise e from None
