# Nexys A7 Lab

This repository is my personal laboratory dedicated to the FPGA development board [Nexys A7](https://digilent.com/reference/programmable-logic/nexys-a7/start) by Digilent. 

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

| Type        | Naming Convention | Example |
|------------|------------------|---------|
| **Ports** | `i_` (input), `o_` (output), `io_` (inout) | `i_clk`, `o_result`, `io_bus` |
| **Signals** | `reg_` (register),  `w_` (wire) | `w_data_ready`, `reg_data` |
| **Variables** | `var_` prefix | `var_counter`, `var_temp` |
| **Constants** | Uppercase with underscores | `CLK_PERIOD_NS`, `MAX_COUNT` |
| **Generics** | Uppercase with underscores | `DATA_WIDTH`, `CLOCK_FREQ` |
| **Processes** | Suffix `_proc` | `clk_div_proc` |
| **FSM States** | Enum type with `S_` prefix | `S_IDLE`, `S_READ`, `S_DONE` |
| **Components** | PascalCase | `MyComponent` |
| **Instances** | Lowercase with `_inst` suffix | `u_uart`, `u_fifo_inst` |
| **Inverted logic** | `_n` suffix (negative) | `rst_n`, `ena_n` |

