library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library vunit_lib;
    context vunit_lib.vunit_context;

entity pwm_generator_tb is
    generic (
        RUNNER_CFG : string;
        RESOLUTION : natural   := 2;
        POLARITY   : std_logic := '1';
        PERIOD     : natural   := 5
    );
end entity pwm_generator_tb;

architecture tb of pwm_generator_tb is

    constant CLK_PERIOD : time := 20 ns;

    signal clk     : std_logic                     := '0';
    signal clk_ena : std_logic;
    signal pwm     : std_logic;
    signal duty    : unsigned(RESOLUTION downto 0) := (others => '0');
    signal reset   : std_logic                     := '0';

begin

    inst_clock_enable_generator : entity work.clock_enable_generator
        generic map (
            PERIOD => PERIOD
        )
        port map (
            i_clk     => clk,
            o_clk_ena => clk_ena
        );

    inst_uut : entity work.pwm_generator
        generic map (
            RESOLUTION => RESOLUTION,
            POLARITY   => POLARITY
        )
        port map (
            i_clk     => clk,
            i_clk_ena => clk_ena,
            i_reset   => reset,
            i_duty    => duty,
            o_pwm     => pwm
        );

    clk <= not clk after (CLK_PERIOD / 2);

    proc_test_runner : process is
    begin

        test_runner_setup(runner, RUNNER_CFG);

        while test_suite loop

            -- duty sweep
            if run("duty_sweep") then

                for i in 0 to (2 ** RESOLUTION) loop

                    duty <= to_unsigned(i, duty'length);

                    wait for PERIOD * CLK_PERIOD * (2 ** RESOLUTION);

                end loop;

                for i in (2 ** RESOLUTION) - 1 downto 0 loop

                    duty <= to_unsigned(i, duty'length);

                    wait for PERIOD * CLK_PERIOD * (2 ** RESOLUTION);

                end loop;

            end if;

            -- reset test
            if run("reset") then
                duty <= to_unsigned(2 ** (RESOLUTION - 1), duty'length);

                wait for 2 * PERIOD * CLK_PERIOD * (2 ** RESOLUTION);

                reset <= '1';

                wait for PERIOD * CLK_PERIOD * (2 ** RESOLUTION);

                reset <= '0';
            end if;

        end loop;

        test_runner_cleanup(runner); -- Simulation ends here

    end process proc_test_runner;

end architecture tb;
