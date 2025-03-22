library ieee;
    use ieee.std_logic_1164.all;

library vunit_lib;
    context vunit_lib.vunit_context;

entity clock_enable_generator_tb is
    generic (
        RUNNER_CFG : string;
        PERIOD     : natural := 10
    );
end entity clock_enable_generator_tb;

architecture tb of clock_enable_generator_tb is

    signal   clk        : std_logic := '0';
    signal   clk_ena    : std_logic;
    constant CLK_PERIOD : time      := 20 ns;

begin

    inst_uut : entity work.clock_enable_generator
        generic map (
            PERIOD => PERIOD
        )
        port map (
            i_clk     => clk,
            o_clk_ena => clk_ena
        );

    clk <= not clk after (CLK_PERIOD / 2);

    proc_test_runner : process is
    begin

        test_runner_setup(runner, RUNNER_CFG);

        report "Hello world!";

        for i in 0 to 2 * PERIOD loop

            wait until rising_edge(clk);

            if (i mod PERIOD = 0) then
                check(clk_ena = '1', "Clock enable not asserted at expected cycle");
            else
                check(clk_ena = '0', "Clock enable asserted unexpectedly");
            end if;

        end loop;

        test_runner_cleanup(runner); -- Simulation ends here

    end process proc_test_runner;

end architecture tb;
