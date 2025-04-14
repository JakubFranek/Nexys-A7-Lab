import sys
import subprocess
import argparse
from pathlib import Path

# The following paths need to be set manually
SBY_PATH = "D:/Programy/oss-cad-suite/bin/sby.exe"


def run_command(command, cwd=None):
    print(f"Running command: {' '.join(command)}")
    result = subprocess.run(
        command,
        text=True,
        cwd=cwd,
        stdout=sys.stdout,
        stderr=sys.stderr,
    )
    return result.returncode


def run_sby_file(sby_file: Path, task: str = "") -> bool:
    command = [
        SBY_PATH,
        "--prefix",
        "simulation/sby",
        "-f",
        str(sby_file).replace("\\", "/"),
    ]
    if task:
        command.append(task)

    returncode = run_command(command)
    return returncode == 0


def find_all_sby_files(root: Path = Path("testbench")):
    return list(root.glob("**/*.sby"))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run SymbiYosys testbenches.")
    parser.add_argument(
        "directory",
        type=Path,
        nargs="?",
        help="Relative path to a directory containing directory.sby file.",
    )
    parser.add_argument(
        "task", type=str, nargs="?", default="", help="Optional task name to run."
    )
    args = parser.parse_args()

    if args.directory:
        sby_file = args.directory / f"{args.directory.name}.sby"
        if not sby_file.exists():
            print(f"Error: {sby_file} does not exist.")
            sys.exit(1)

        success = run_sby_file(sby_file, args.task)
        sys.exit(0 if success else 1)

    # No directory provided — run all found testbenches
    all_sby_files = find_all_sby_files()
    if not all_sby_files:
        print("No .sby files found in testbench/**/")
        sys.exit(1)

    print(f"Found {len(all_sby_files)} .sby testbenches. Running all...\n")

    results = {}
    for sby in all_sby_files:
        print(f"Running testbench: {sby}")
        success = run_sby_file(sby, args.task)
        results[str(sby)] = success
        print("-" * 60)

    print("\nFormal verification summary:")
    for sby, passed in results.items():
        status = "PASSED" if passed else "FAILED"
        icon = "✅" if passed else "❌"
        print(f"{icon} {sby}")

    if all(results.values()):
        print("\n✅ All testbenches passed.")
        sys.exit(0)
    else:
        print("\n❌ Some testbenches failed.")
        sys.exit(1)
