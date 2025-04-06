
# Entity: clock_enable_generator 
- **File**: clock_enable_generator.vhd

## Diagram
![Diagram](clock_enable_generator.svg "Diagram")
## Description

Parametrized clock enable pulse generator.

The initial value of output `o_clk_ena` is '0'.



![alt text](clock_enable_generator_wavedrom_0.svg "title")

 


## Generics

| Generic name | Type    | Value | Description                                                             |
| ------------ | ------- | ----- | ----------------------------------------------------------------------- |
| PERIOD       | natural | 10    | number of clock cycles required to generate a single clock enable pulse |
| SIMULATION   | boolean | true  | generate simulation asserts                                             |

## Ports

| Port name | Direction | Type      | Description                                                |
| --------- | --------- | --------- | ---------------------------------------------------------- |
| i_clk     | in        | std_logic | input clock                                                |
| o_clk_ena | out       | std_logic | clock enable signal, active high for one input clock cycle |

## Signals

| Name      | Type                                 | Description      |
| --------- | ------------------------------------ | ---------------- |
| q_counter | unsigned(COUNTER_WIDTH - 1 downto 0) | counter register |

## Constants

| Name          | Type    | Value                             | Description                            |
| ------------- | ------- | --------------------------------- | -------------------------------------- |
| COUNTER_WIDTH | natural | natural(ceil(log2(real(PERIOD)))) | counter width required to fit `PERIOD` |

## Processes
- proc_clk_ena: ( i_clk )

## Assertions

| Label | Condition | Report | Severity | File |
|-------|-----------|--------|----------| -----|
| counter_max_min_value | PERIOD > 1 | `PERIOD` must be larger than 1 | error | .vhd |
| o_clk_ena_period | always {q_counter = PERIOD - 1} &#124;=> {o_clk_ena = '1'} | `o_clk_ena` not activated in the next clock cycle after `q_counter` reaches `PERIOD` - 1 | error | .vhd |
| q_counter_reset | always {q_counter = PERIOD - 1} &#124;=> {q_counter = 0} | `q_counter` not reset in the next clock cycle after reaching `PERIOD` - 1 | error | .vhd |
| o_clk_ena_one_cycle | always {o_clk_ena = '1'} &#124;=> {o_clk_ena = '0'} | `o_clk_ena` pulse is longer than one clock cycle | error | .vhd |
| q_counter_increment | always (q_counter < PERIOD - 1) -> next (q_counter = prev(q_counter) + 1) |  |  | .psl |
