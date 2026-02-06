import re
import sys
from pathlib import Path

from mypy.plugin import Plugin


def get_correct_mypy_version() -> str:
    """Return the mypy version required by the PyTorch repo."""
    requirements_file = Path(__file__).parent.parent / ".ci" / "docker" / "requirements-ci.txt"
    if not requirements_file.is_file():
        raise FileNotFoundError(f"Requirements file not found: {requirements_file}")

    text = requirements_file.read_text(encoding="utf-8")
    match = re.search(r"mypy==(\d+(?:\.\d+)*)", text)
    if not match:
        raise ValueError(f"Could not find mypy version in {requirements_file}")
    (version,) = match.groups()
    return version


def plugin(version: str) -> type:
    correct_version = get_correct_mypy_version()
    if version != correct_version:
        print(
            f"""\
You are using mypy version {version}, which is not supported
in the PyTorch repo. Please switch to mypy version {correct_version}.

For example, if you installed mypy via pip, run this:

    pip install mypy=={correct_version}

Or if you installed mypy via conda, run this:

    conda install -c conda-forge mypy={correct_version}
""",
            file=sys.stderr,
        )
    return Plugin
