"""
Script to run VHDL simulations with GHDL.

Typical usage:
python scripts/run_ghdl.py testbenches/my_module/my_module_tb.vhd --stop-time=1us
"""

import subprocess
import sys
import glob
import argparse
from pathlib import Path
import shutil

# Configuration constants
VHDL_EXT = ".vhd"
STOP_TIME = "1ms"
SIM_DIR = "simulation"
GHDL_CMD = "ghdl"
GHDL_FLAGS = "--std=08"

# Define file paths
FILES = glob.glob(str(Path.cwd() / "source" / "**" / f"*{VHDL_EXT}"), recursive=True)


# Function to run a command and check for success
def run_command(command, cwd=None):
    try:
        print(f"Running command: {' '.join(command)}")
        result = subprocess.run(
            command,
            check=True,
            text=True,
            cwd=cwd,
            stdout=sys.stdout,
            stderr=sys.stderr,
        )
        result.check_returncode()  # This raises CalledProcessError if returncode is non-zero
    except subprocess.CalledProcessError as e:
        print(f"Error: {e}")
        print(f"Command: {' '.join(command)}")
        print(f"Exit code: {e.returncode}")
        print(f"Standard Output:\n{e.stdout}")
        print(f"Standard Error:\n{e.stderr}")
        sys.exit(e.returncode)


# Clean simulation directory
def clean():
    sim_path = Path(SIM_DIR)
    if sim_path.exists():
        print(f"Cleaning {SIM_DIR} directory.")
        shutil.rmtree(sim_path)  # Cross-platform removal


# Compile source and testbench
def compile(testbench_relative_path: Path):
    Path(SIM_DIR).mkdir(parents=True, exist_ok=True)

    testbench_absolute_path = Path.cwd() / testbench_relative_path
    testbench_name = testbench_relative_path.stem

    # Compile source files
    for file in FILES:
        run_command(
            [GHDL_CMD, "-i", GHDL_FLAGS, "--work=work", f"--workdir={SIM_DIR}", file]
        )

    # Compile testbench
    run_command(
        [
            GHDL_CMD,
            "-i",
            GHDL_FLAGS,
            "--work=work",
            f"--workdir={SIM_DIR}",
            str(testbench_absolute_path),
        ]
    )

    # Create object file for the testbench
    run_command(
        [
            GHDL_CMD,
            "-m",
            GHDL_FLAGS,
            "--work=work",
            f"--workdir={SIM_DIR}",
            "-o",
            f"{Path.cwd()}/{SIM_DIR}/{testbench_name}",
            f"{testbench_name}",
        ]
    )


# Run the simulation
def run(testbench_relative_path: Path, stop_time: str):
    testbench_name = testbench_relative_path.stem
    vcdfile = f"{testbench_name}.vcd"
    run_command(
        [
            GHDL_CMD,
            "-r",
            GHDL_FLAGS,
            "--work=work",
            "--workdir=.",
            testbench_name,
            "--vcd=" + vcdfile,
            "--stop-time=" + stop_time,
        ],
        cwd=SIM_DIR,
    )


def main():
    parser = argparse.ArgumentParser(description="Run VHDL simulations with GHDL.")
    parser.add_argument(
        "testbench_path", type=Path, help="Relative path to the testbench file."
    )
    parser.add_argument(
        "--stop-time", type=str, default=STOP_TIME, help="Stop time for the simulation."
    )

    args = parser.parse_args()

    testbench_path: Path = args.testbench_path
    stop_time: str = args.stop_time

    clean()
    compile(testbench_path)
    run(testbench_path, stop_time)


if __name__ == "__main__":
    main()
