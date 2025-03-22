# Tool limitations

This is a list of known limitations of the tools that are used in this repository.

## GHDL
- code coverage analysis is not supported with LLVM backend (only GCC backend supports it)
- some PSL built-in functions like `prev()` are not supported for simulation (only synthesis)

## SymbiYosys
- `$assert` cells do not contain severity levels
  - this means any failing assert regardless of severity level causes formal verification to fail
  - [see issue](https://github.com/YosysHQ/sby/issues/318)
  - workaround is to remove asserts which have labels that end with `*/*_note` and `*/*_warning` (i.e. filter asserts based on their labels) in the `.sby` file via `chformal -assert [-remove|-assert2assume] */*_note` in the `[script]` section

## VHDL-LS
- PSL statements are not supported
  - this therefore necessitates putting PSL statements into `-- psl` comment blocks (which in turn requires running GHDL with `-fpsl` option)
  - [option to skip regions of code will be added in release 0.84](https://github.com/VHDL-LS/rust_hdl/pull/372), once that releases, the PSL statements can be written directly into the HDL code
  - since it takes time before VHDL-LS releases are merged into Teros HDL, it might be possible to install VDHL-LS VS Code extension separately and disable VHDL-LS in Teros HDL

## VSG
- PSL statements are only minimally supported

## VUnit
- PSL vunits are not supported

## Teros HDL
- generating documentation via command line is not supported anymore, saving docs must be done manually
  - manually saving documentation with WaveDrom time diagrams saves them as SVG with random suffix
  - to be able to version the time diagrams properly, [cleanup_wavedrom_svgs.py](../scripts/cleanup_wavedrom_svgs.py) script has been made to automatically rename the SVG files according to a predictable pattern
- generating schematics via GHDL+yosys integration is broken (missing ghdl.so file), but this has been bypassed by [synthesize_svg.py](../scripts/synthesize_svg.py) script
  - [will be supposedly fixed in TerosHDL v7.0.1](https://github.com/TerosTechnology/vscode-terosHDL/issues/717#issuecomment-2733571436)

## Surfer
- setting default time unit in config file is not yet supported, [see this issue](https://gitlab.com/surfer-project/surfer/-/issues/373)

## AMD Vivado
- PSL statements are not supported in plain VHDL-2008 (only workaround seems to be `-- psl` comment blocks)
- case of port names in XDC constaints must exactly match the case in VHDL code