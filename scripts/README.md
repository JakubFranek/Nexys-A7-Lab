# Scripts <!-- omit from toc -->

This directory contains scripts used by the project.

## Contents <!-- omit from toc -->
- [`run_vunit.py`](#run_vunitpy)
- [`run_sby.py`](#run_sbypy)
- [`synthesize_svg.py`](#synthesize_svgpy)
- [`doc_fix.py`](#doc_fixpy)


## `run_vunit.py`

`run_vunit.py` is a script used to run VUnit tests.

## `run_sby.py`

`run_sby.py` is a script used to run SymbiYosys formal verification.

## `synthesize_svg.py`

`synthesize_svg.py` is a script used to synthesize SVG diagrams from VHDL code.

## `doc_fix.py`

`doc_fix.py` is a script which improves documentation of VHDL entities found within `source/` directory.

It does the following things:
1. renames `entity_name/entity_name.md` files (default TerosHDL name) to `entity_name/README.md` (required by GitHub in order to show the contents of the file when inspecting the directory)
1. renames WaveDrom SVGs generated by TerosHDL, which contain random string identifiers by default, to a predictable name, which allows version control of the SVGs, and updates the references in the relevant `entity_name/README.md` file to the new names
1. analyzes the `entity_name/entity_name.vhd` file, extracts all VHDL and PSL asserts from it and appends a Markdown file documenting the asserts to `entity_name/README.md`