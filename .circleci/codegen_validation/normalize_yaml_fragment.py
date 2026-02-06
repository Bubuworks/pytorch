#!/usr/bin/env python3

from __future__ import annotations

import argparse
import sys
from typing import TextIO

import yaml

from cimodel.lib import miniyaml


def load_yaml(stream: TextIO) -> object:
    """
    Load YAML data from a text stream.

    Raises:
        ValueError: If the YAML is invalid or empty.
    """
    try:
        data = yaml.safe_load(stream)
    except yaml.YAMLError as exc:
        raise ValueError(f"YAML parse error: {exc}") from exc

    if data is None:
        raise ValueError("No YAML input provided.")

    return data


def render_yaml(
    data: object,
    output: TextIO,
    *,
    depth: int,
    use_pyyaml: bool,
) -> None:
    """
    Render YAML data to an output stream.
    """
    if use_pyyaml:
        yaml.dump(data, output, sort_keys=True)
    else:
        miniyaml.render(output, data, depth)


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Render YAML from stdin using miniyaml or PyYAML."
    )
    parser.add_argument(
        "--depth",
        type=int,
        default=3,
        help="Indentation depth for miniyaml rendering (default: 3)",
    )
    parser.add_argument(
        "--pyyaml",
        action="store_true",
        help="Use PyYAML formatter instead of miniyaml",
    )
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)

    try:
        data = load_yaml(sys.stdin)
        render_yaml(
            data,
            sys.stdout,
            depth=args.depth,
            use_pyyaml=args.pyyaml,
        )
    except ValueError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
