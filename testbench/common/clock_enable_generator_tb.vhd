library ieee;
use ieee.std_logic_1164.all;
use std.env.finish;

entity clock_enable_generator_tb is
end entity clock_enable_generator_tb;

architecture tb of clock_enable_generator_tb is

    signal clk     : std_logic := '0';
    signal clk_ena : std_logic;

begin

    UUT : entity work.clock_enable_generator
        generic map(COUNTER_MAX => 1000)
        port map
            (i_clk => clk, o_clk_ena => clk_ena);

    clk_process : process (clk)
        constant period : time := 20 ns;
    begin
        clk <= not clk after period;
    end process clk_process;

    tb1 : process
    begin
        wait for 100 us;
        finish;
    end process tb1;

end tb;
