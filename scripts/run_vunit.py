import sys
from vunit import VUnit
from pathlib import Path
import importlib
import importlib.util

# Define default arguments
default_args = [
    "run.py",
    "-o",
    "simulation/vunit_out",
    "--viewer",
    "surfer",
    "--viewer-fmt",
    "vcd",
]

# Append actual command-line arguments, excluding the script name
sys.argv = default_args + sys.argv[1:]

vunit = VUnit.from_argv()
vunit.add_vhdl_builtins()

lib = vunit.add_library("lib")
lib.add_source_files("source/**/*.vhd")
lib.add_source_files("testbench/**/*.vhd")

# The following code is used to automatically configure the testbenches
# based on the presence of a `vunit_config.py` file within the testbench
# directory (which is named the same as the testbench itself, without the `_tb`).
for testbench in lib.get_test_benches():
    config_path = Path(f"testbench/{testbench.name.strip('_tb')}/vunit_config.py")
    if config_path.exists():
        spec = importlib.util.spec_from_file_location("config", str(config_path))
        config_module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(config_module)
        config_module.configure(testbench)
        print(f"Configured {testbench.name} with {config_path}")
    else:
        print(f"Could not find vunit_config.py for {testbench.name}, skipping...")

vunit.set_compile_option(
    "ghdl.a_flags", ["-fpsl", "--std=08"]
)  # -fpsl is needed to accept PSL asserts in comments
vunit.main()
