library ieee;
    use ieee.std_logic_1164.all;
    use ieee.math_real.floor;

library vunit_lib;
    context vunit_lib.vunit_context;

entity debouncer_tb is
    generic (
        RUNNER_CFG      : string;
        PERIOD_CLK_ENA  : natural := 10;
        PERIOD_DEBOUNCE : natural := 10
    );
end entity debouncer_tb;

architecture tb of debouncer_tb is

    signal   input      : std_logic := '0';
    signal   output     : std_logic;
    signal   clk        : std_logic := '0';
    signal   clk_ena    : std_logic;
    constant CLK_PERIOD : time      := 20 ns;

begin

    inst_clk_ena : entity work.clock_enable_generator
        generic map (
            PERIOD => PERIOD_CLK_ENA
        )
        port map (
            i_clk     => clk,
            o_clk_ena => clk_ena
        );

    inst_uut : entity work.debouncer
        generic map (
            PERIOD => PERIOD_DEBOUNCE
        )
        port map (
            i_input   => input,
            i_clk     => clk,
            i_clk_ena => clk_ena,
            o_output  => output
        );

    clk <= not clk after (CLK_PERIOD / 2);

    proc_test_runner : process is
    begin

        test_runner_setup(runner, RUNNER_CFG);

        show(get_logger(default_checker), display_handler, pass);

        while test_suite loop

            -- glitches at the start of `input` transitions
            if run("glitch_edge") then
                wait for (PERIOD_CLK_ENA + 1) * CLK_PERIOD;
                wait until rising_edge(clk);

                input <= '1';
                wait for CLK_PERIOD;
                input <= '0';
                wait for CLK_PERIOD;
                input <= '1';

                wait for 3 * CLK_PERIOD;
                wait until rising_edge(clk_ena);
                wait for (PERIOD_CLK_ENA * PERIOD_DEBOUNCE + 3) * CLK_PERIOD;

                check(output = '1', "Check `o_output` is '1'");

                input <= '0';
                wait for CLK_PERIOD;
                input <= '1';
                wait for CLK_PERIOD;
                input <= '0';

                wait for 3 * CLK_PERIOD;
                wait until rising_edge(clk_ena);
                wait for (PERIOD_CLK_ENA * PERIOD_DEBOUNCE + 3) * CLK_PERIOD;

                check(output = '0', "Check `o_output` is '0'");

                wait for (PERIOD_CLK_ENA) * CLK_PERIOD;

            -- glitches at the start of `input` transitions, and glitch in the middle of counter period
            elsif run("glitch_middle") then
                wait for (PERIOD_CLK_ENA + 1) * CLK_PERIOD;
                wait until rising_edge(clk);

                input <= '1';
                wait for CLK_PERIOD;
                input <= '0';
                wait for CLK_PERIOD;
                input <= '1';

                wait until rising_edge(clk_ena);
                wait for (PERIOD_CLK_ENA * natural(floor(real(PERIOD_DEBOUNCE / 2)))) * CLK_PERIOD;

                input <= '0';
                wait for CLK_PERIOD;
                input <= '1';

                wait until rising_edge(clk_ena);
                wait for (PERIOD_CLK_ENA * PERIOD_DEBOUNCE + 3) * CLK_PERIOD;

                check(output = '1', "Check `o_output` is '1'");

                input <= '0';
                wait for CLK_PERIOD;
                input <= '1';
                wait for CLK_PERIOD;
                input <= '0';

                wait until rising_edge(clk_ena);
                wait for (PERIOD_CLK_ENA * natural(floor(real(PERIOD_DEBOUNCE / 2)))) * CLK_PERIOD;

                input <= '1';
                wait for CLK_PERIOD;
                input <= '0';

                wait until rising_edge(clk_ena);
                wait for (PERIOD_CLK_ENA * PERIOD_DEBOUNCE + 3) * CLK_PERIOD;

                check(output = '0', "Check `o_output` is '0'");

                wait for (PERIOD_CLK_ENA) * CLK_PERIOD;
            end if;

        end loop;

        test_runner_cleanup(runner); -- Simulation ends here

    end process proc_test_runner;

end architecture tb;
