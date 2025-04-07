import sys
import subprocess
import fnmatch
import argparse
from pathlib import Path
import csv

# The following paths need to be set manually
SURFER_PATH = "D:/Programy/surfer/surfer.exe"
TESTBENCH_DIRECTORY = "testbench"
TEST_OUTPUT_DIRECTORY = "simulation/vunit_out/test_output/"
MAPPING_FILE_PATH = TEST_OUTPUT_DIRECTORY + "test_name_to_path_mapping.txt"


def run_command(command, cwd=None):
    print(f"Running command: {' '.join(command)}")
    subprocess.run(
        command,
        text=True,
        cwd=cwd,
        stdout=sys.stdout,
        stderr=sys.stderr,
    )


def find_matching_test(pattern: str) -> tuple[str, str]:
    tests: dict[str, str] = {}  # test_name: test_folder_name
    with open(MAPPING_FILE_PATH, "r") as file:
        reader = csv.reader(file, delimiter=" ")
        for row in reader:
            tests[" ".join(row[1:])] = row[0]

    matches = [key for key in tests if fnmatch.fnmatch(key, pattern)]

    if len(matches) > 1:
        print(f"Found {len(matches)} matching tests:")
        for i, match in enumerate(matches):
            print(f"{i}: {match}")
        test_index = input("Select test: ")
        return (matches[int(test_index)], tests[matches[int(test_index)]])
    elif len(matches) == 0:
        print("No matching tests found.")
        sys.exit(1)
    else:
        print(f"Found 1 matching test: {matches[0]}")
        return (matches[0], tests[matches[0]])


def find_state_file(test_name: str) -> str:
    # Assume that the testbench name is the second dot-separated member of the test name
    testbench_name = test_name.split(".")[1].rstrip("_tb")

    # Attempt to find a *surfer.ron state file in the testbench directory
    testbench_directory = Path(TESTBENCH_DIRECTORY) / testbench_name

    state_files = list(testbench_directory.glob("*surf.ron"))

    if len(state_files) == 0:
        print("No state files found. Proceeding...")
        return ""
    elif len(state_files) == 1:
        print(f"Found 1 state file: {state_files[0]}")
        return state_files[0]
    else:
        # Multiple state files found: prompt user to select one
        print(f"Found {len(state_files)} state files:")
        for i, state_file in enumerate(state_files):
            print(f"{i}: {state_file}")
        state_file_index = input("Select state file: ")
        return state_files[int(state_file_index)]


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Open Surfer with wave and potentially state file loaded."
    )
    parser.add_argument(
        "pattern",
        type=Path,
        help="Glob pattern for the test to open in Surfer.",
    )
    args = parser.parse_args()
    pattern: str = args.pattern

    test_name, test_path = find_matching_test(pattern)
    state_file = find_state_file(test_name)

    wave_file = Path(TEST_OUTPUT_DIRECTORY) / test_path / "ghdl" / "wave.vcd"

    if state_file:
        command = [SURFER_PATH, "-s", str(state_file), str(wave_file)]
    else:
        command = [SURFER_PATH, str(wave_file)]

    run_command(command)
