--! Synchronous edge detector.
--!
--! Warning: After reset there might be a false rising edge detected if `i_input` is high
--! from the very start, as the delayed input is initialized to '0'.
------------------------------------------------------------
--! { signal: [
--!  { name: "i_clk",           wave: "P........." },
--!  { name: "i_input",         wave: "01....0..." },
--!  { name: ["tspan", {style: "fill:gray"}, "q_input_dly"],
--!                             wave: "0.1....0.." },
--!  { name: "o_rising_edge",   wave: "0..10....." },
--!  { name: "o_falling_edge",  wave: "0.......10" },
--!  { name: "o_any_edge",      wave: "0..10...10" },
--! ],
--!  head:{
--!     text:'Time diagram',
--!     tick:0,
--!     every:1
--!   },
--! }
------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity edge_detector is
    port (
        i_clk          : in    std_logic;        --! input clock
        i_input        : in    std_logic;        --! input signal
        o_rising_edge  : out   std_logic := '0'; --! high when input goes from low to high
        o_falling_edge : out   std_logic := '0'; --! high when input goes from high to low
        o_any_edge     : out   std_logic := '0'  --! high when input changes
    );
end entity edge_detector;

architecture rtl of edge_detector is

    --! delayed input
    signal q_input_dly : std_logic := '0';

begin

    proc_clk : process (i_clk) is
    begin

        if rising_edge(i_clk) then
            q_input_dly    <= i_input;
            o_rising_edge  <= i_input and not q_input_dly;
            o_falling_edge <= not i_input and q_input_dly;
            o_any_edge     <= i_input xor q_input_dly;
        end if;

    end process proc_clk;

end architecture rtl;

