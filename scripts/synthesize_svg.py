import re
import sys
import argparse
import subprocess
from pathlib import Path

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


def add_white_background(svg_file):
    with open(svg_file, "r", encoding="utf-8") as f:
        content = f.read()

    # Regex to find the <svg> tag and insert the <rect>
    modified_content = re.sub(
        r"(<svg[^>]*>)", r'\1<rect width="100%" height="100%" fill="white"/>', content
    )

    with open(svg_file, "w", encoding="utf-8") as f:
        f.write(modified_content)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Synthesize a VHDL file into a SVG")
    parser.add_argument(
        "vhd_file_path", type=Path, help="Relative path to the input VHDL file."
    )
    parser.add_argument(
        "svg_file_path", type=Path, help="Relative path to the output SVG file."
    )
    args = parser.parse_args()

    vhd_file_path: Path = args.vhd_file_path
    vhd_file_name = vhd_file_path.stem
    svg_file_path: Path = args.svg_file_path
    json_file_name = f"{svg_file_path.parent}/{vhd_file_name}.json"
    run_command(
        [
            YOSYS_PATH,
            "-p",
            f"ghdl --std=08 -fsynopsys --work=work {vhd_file_path} --work=work -e {vhd_file_name}",
            "-p",
            f"hierarchy -top {vhd_file_name}",
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
    add_white_background(svg_file_path)
    print(f"Created: {svg_file_path}")
