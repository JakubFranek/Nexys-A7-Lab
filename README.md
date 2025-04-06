# Nexys A7 Lab

This repository is my personal digital design laboratory dedicated to the FPGA development board [Nexys A7](https://digilent.com/reference/programmable-logic/nexys-a7/start) by Digilent. 

My goal with this repository is to gradually design and verify RTL code required for controlling Nexys A7 board peripherals. 

All of the code in this repository is authored by me personally, as my motivation is to refresh and expand my digital design and verification knowledge and skills.

## Repository Structure

```
constraints/   # XDC constraint files
docs/          # Documentation and notes
scripts/       # Useful scripts for automation
source/        # HDL source files
testbench/     # HDL testbenches for verification of HDL source files
vivado/        # Vivado projects
.gitignore     # Git ignore rules
README.md      # Project overview (you are reading this now!)
TODO.dm        # Project task list
```

## Supported peripherals / controllers

- [ ] Switch / button debouncer
- [ ] 7-segment display controller
- [ ] PWM controller
- [ ] VGA controller
- [ ] PS/2 mouse controller
- [ ] PS/2 keyboard controller
- [ ] UART controller
- [ ] ADT7420 temperature sensor I2C master
- [ ] ADXL362 accelerometer SPI master
- [ ] ADMP421 microphone PDM demodulator
- [ ] Quad-SPI Flash memory controller
- [ ] DDR2 memory controller
- [ ] MicroSD card controller
- [ ] Ethernet PHY controller

## VHDL Naming Convention

| Type                       | Naming Convention                                                                | Example                         |
| -------------------------- | -------------------------------------------------------------------------------- | ------------------------------- |
| **Ports**                  | `i_` (input), `o_` (output), `io_` (inout)                                       | `i_clk`, `o_result`, `io_bus`   |
| **Signals**                | `q_` (registered), no prefix otherwise                                           | `xor_out`, `q_data`             |
| **Variables**              | `var_` prefix                                                                    | `var_counter`, `var_temp`       |
| **Constants and generics** | SCREAMING_SNAKE_CASE                                                             | `DATA_WIDTH`, `CLOCK_FREQ`      |
| **Processes**              | Prefix `proc_`                                                                   | `proc_clk_div`                  |
| **FSM States**             | Enum type with `S_` prefix, uppercase                                            | `S_IDLE`, `S_READ`, `S_DONE`    |
| **Entities / Components**  | snake_case                                                                       | `component_name`                |
| **Instances**              | `inst_` prefix                                                                   | `inst_uart`, `inst_fifo`        |
| **Inverted logic**         | `_n` suffix (negative)                                                           | `rst_n`, `ena_n`                |
| **Assert labels**          | `_note`, `_warning` suffices (see [here](./docs/tool_limitations.md#symbiyosys)) | `assert_note`, `assert_warning` |

## Tools

- VHDL simulator: [GHDL](http://ghdl.free.fr/)
- target aware FPGA synthesizer, P&R, STA: [AMD Vivado](https://www.amd.com/en/products/software/adaptive-socs-and-fpgas/vivado.html)
- synthesizer for documentation and formal verification: [Yosys](https://yosyshq.net/yosys/about.html) with [GHDL-Yosys-plugin](https://github.com/ghdl/ghdl-yosys-plugin)
- unit testing framework: [VUnit](https://vunit.github.io/)
- formal verification: [SymbiYosys](https://symbiyosys.readthedocs.io/en/latest/)
- waveform viewer: [Surfer](https://surfer-project.org/)
- VHDL formatter and style checker: [vhdl-style-guide (VSG)](https://github.com/jeremiah-c-leary/vhdl-style-guide)
- VHDL syntactic linter: [VHDL-LS](https://github.com/VHDL-LS/rust_hdl)