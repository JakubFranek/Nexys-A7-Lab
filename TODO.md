# Task list <!-- omit from toc -->

This is a task list for this repository. This list is not exhaustive.

## Contents <!-- omit from toc -->
- [Work in progress](#work-in-progress)
- [To do](#to-do)
- [Backlog](#backlog)
- [Done](#done)

## Work in progress

- [ ] Explore VUnit further
  - [x] Vary generics
  - [x] Include multiple test cases in a testbench
  - [ ] Study logging library
  - [ ] Study check library
  - [ ] Study run library

- [ ] Create 7-segment display controller
  - [x] Create RTL
  - [x] Add documentation and WaveDrom time diagram
  - [ ] Create VUnit testbench
  - [x] Create PSL assertions
  - [x] Test on FPGA

## To do

- [ ] Add script to run formal verification on all testbenches which have `.sby` files

- [ ] Handle package documentation 

- [ ] Create PWM controller

- [ ] Test FSM diagram generation in TerosHDL

## Backlog

- [ ] Make a clock enable generator utilizing inferred SRLs ([inspiration here](https://gist.github.com/Thraetaona/ba941e293d36d0f76db6b9f3476b823c))

## Done

- [x] [Try to get VSG working with PSL](https://github.com/jeremiah-c-leary/vhdl-style-guide/issues/1411)
- [x] Create a script for documenting asserts in VHDL files
- [x] Setup VSG linter & formatter
  - [x] decide whether to use prefixes rigorously (result: partially yes)
- [x] [Create an issue about SymbiYosys & VHDL assert severity interpretation when used for formal verification (probably in SymbiYosys GitHub)](https://github.com/YosysHQ/sby/issues/318)
- [x] [Make ticket about VSG problems being shown for external libraries](https://github.com/TerosTechnology/vscode-terosHDL/issues/748) 
- [x] Bundle WaveDrom SVG cleanup script and assert documenting script into one script
- [x] Include SVG white background addition within cleanup_wavedrom_svgs.py script
- [x] Add tool links to README
- [x] Make SymbiYosys Python script accept arguments (testbench path)
- [x] Test synthesization of PSL code in Vivado (in case of problems, wrap formal verification code in some kind of SIMULATION/FORMAL generic boolean)
- [x] Make XDC constraint port names lowercase
- [x] Rename entity Markdown docs to README in order to show them on GitHub
- [x] Add README to scripts directory
- [x] Test PSL vunits with SymbiYosys and GHDL synthesis-only PSL functions
- [x] Create parametrized synchronizer
- [x] Create an issue about new GHDL release causing exec errors with VUnit (after MSYS2 update on 5/4/2025 there are actually no issues with VUnit)
- [x] Test `synthesize_svg` script on a block containing sub-blocks
- [x] Create a Python script for convenient display of VUnit data in surfer, which will load the .vcd file as well as the state .ron file
- [x] Document `assume` statements
- [x] Document `assert` and `assume` statements	in `.psl` files as well
- [x] Test multiple WaveDrom diagrams per VHDL file
- [x] Edit PSL documenting scripts to skip cover/assume/assert sections if empty
- [x] Create BCD counter
  - [x] Create RTL
  - [x] Add documentation and WaveDrom time diagram
  - [x] Create VUnit testbench
  - [x] Create PSL assertions
- [x] Create parametrized debouncer
  - [x] Create RTL
  - [x] Create VUnit testbench
  - [x] Create PSL assertions
  - [x] Test on FPGA