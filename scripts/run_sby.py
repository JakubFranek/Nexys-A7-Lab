import sys
import subprocess

import argparse
from pathlib import Path

# The following paths need to be set manually
SBY_PATH = "D:/Programy/oss-cad-suite/bin/sby.exe"
# YOSYS_PATH = "D:/Programy/MSYS2/mingw64/bin/yosys.exe"
# YOSYS_SMTBMC_PATH = "D:/Programy/oss-cad-suite/bin/yosys-smtbmc.exe"


def run_command(command, cwd=None):
    print(f"Running command: {' '.join(command)}")
    subprocess.run(
        command,
        text=True,
        cwd=cwd,
        stdout=sys.stdout,
        stderr=sys.stderr,
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run Sby")
    parser.add_argument(
        "directory",
        type=Path,
        help="Relative path to a directory containing directory.sby file.",
    )
    parser.add_argument("task", type=str, help="Task to run.", nargs="?", default="")
    args = parser.parse_args()

    directory: Path = args.directory
    task: str = args.task

    command = [
        SBY_PATH,
        "--prefix",
        "simulation/sby",
        "-f",
        str(directory / directory.name).replace("\\", "/") + ".sby",
    ]

    if task:
        command.append(task)

    run_command(command)
