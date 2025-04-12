--! Parametrized clock enable pulse generator.
--!
--! The initial value of output `o_clk_ena` is '0'.

------------------------------------------------------------
--! { signal: [
--!  { name: "i_clk",       wave: "P........." },
--!  { name: "q_counter",   wave: "==========", data: [0,1,2,3,0,1,2,3,0,1] },
--!  { name: "o_clk_ena",   wave: "0...10..10" }
--! ],
--!  head:{
--!     text:'Time diagram (for PERIOD = 4)',
--!     tick:0,
--!     every:1
--!   },
--! }
------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.log2;
    use ieee.math_real.ceil;

entity clock_enable_generator is
    generic (
        --! number of clock cycles required to generate a single clock enable pulse
        PERIOD : natural range 1 to natural'high := 10
    );
    port (
        i_clk     : in    std_logic;       --! input clock
        o_clk_ena : out   std_logic := '0' --! clock enable signal, active high for one input clock cycle
    );
end entity clock_enable_generator;

architecture rtl of clock_enable_generator is

    --! counter width required to fit `PERIOD`
    constant COUNTER_WIDTH : natural := natural(ceil(log2(real(PERIOD))));

    --! counter register
    signal q_counter : unsigned(COUNTER_WIDTH - 1 downto 0) := (others => '0');

begin

    proc_clk_ena : process (i_clk) is
    begin

        if rising_edge(i_clk) then
            if (q_counter = (PERIOD - 1)) then
                q_counter <= (others => '0');
                o_clk_ena <= '1';
            else
                q_counter <= q_counter + 1;
                o_clk_ena <= '0';
            end if;
        end if;

    end process proc_clk_ena;

end architecture rtl;
