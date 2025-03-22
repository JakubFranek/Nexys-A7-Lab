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
  - [ ] Include multiple test cases in a testbench

## To do

- [ ] Test synthesization of PSL code in Vivado (in case of problems, wrap formal verification code in some kind of SIMULATION/FORMAL generic boolean)
- [ ] Test `synthesize_svg` script on a block containing sub-blocks
- [ ] Test FSM diagram generation in TerosHDL
- [ ] Test multiple WaveDrom diagrams per VHDL file

## Backlog

## Done

- [x] [Try to get VSG working with PSL](https://github.com/jeremiah-c-leary/vhdl-style-guide/issues/1411)
- [x] Create a script for documenting asserts in VHDL files
- [x] Setup VSG linter & formatter
  - [x] decide whether to use prefixes rigorously
- [x] [Create an issue about SymbiYosys & VHDL assert severity interpretation when used for formal verification (probably in SymbiYosys GitHub)](https://github.com/YosysHQ/sby/issues/318)
- [x] [Make ticket about VSG problems being shown for external libraries](https://github.com/TerosTechnology/vscode-terosHDL/issues/748) 
- [x] Bundle WaveDrom SVG cleanup script and assert documenting script into one script
- [x] Include SVG white background addition within cleanup_wavedrom_svgs.py script
- [x] Add tool links to README
- [x] Make SymbiYosys Python script accept arguments (testbench path)