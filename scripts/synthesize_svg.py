import sys
import argparse
import subprocess
from pathlib import Path

from helpers.add_svg_white_background import add_white_background

# The following paths need to be set manually
YOSYS_PATH = "D:/Programy/MSYS2/mingw64/bin/yosys.exe"
NETLISTSVG_PATH = "C:/Users/jfran/AppData/Roaming/npm/netlistsvg.cmd"
NETLISTSVG_SKIN_PATH = "scripts/netlistsvg_skins/default.svg"


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


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Synthesize a VHDL file into a SVG")
    parser.add_argument(
        "directory",
        type=Path,
        help="Relative path to the directory which contains the VHDL file with the same name.",
    )
    args = parser.parse_args()

    vhd_file_path: Path = args.directory / (args.directory.name + ".vhd")
    vhd_file_paths: list[Path] = list(Path("source").glob("**/*.vhd"))
    svg_file_path: Path = args.directory / (args.directory.name + "_netlist.svg")
    json_file_name = f"{svg_file_path.parent}/{vhd_file_path.stem}.json"
    run_command(
        [
            YOSYS_PATH,
            "-p",
            f"ghdl --std=08 --no-formal --work=work {' '.join(str(path) for path in vhd_file_paths)} --work=work -e {vhd_file_path.stem}",
            "-p",
            f"hierarchy -top {vhd_file_path.stem}",
            "-p",
            "proc",
            "-p",
            f"write_json {json_file_name}",
            "-p",
            "stat",
        ]
    )
    run_command(
        [
            NETLISTSVG_PATH,
            f"{json_file_name}",
            "-o",
            f"{svg_file_path.as_posix()}",
            f"--skin {NETLISTSVG_SKIN_PATH}",
        ]
    )
    print(f"Created: {svg_file_path}")

    # Remove JSON netlist
    json_file_path = Path(json_file_name)
    if json_file_path.exists():
        json_file_path.unlink()
        print(f"Removed: {json_file_path}")

    add_white_background(svg_file_path)
