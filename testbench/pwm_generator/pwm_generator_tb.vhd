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

        procedure sweep_duty (
            start_val : integer;
            stop_val  : integer;
            step_val  : integer
        ) is

            variable v_active_count   : natural := 0;
            variable v_expected_count : natural := 0;
            variable v_loop_index     : integer := 0;

        begin

            v_loop_index := start_val;

            while (step_val > 0 and v_loop_index < stop_val) or (step_val < 0 and v_loop_index >= stop_val) loop

                v_active_count   := 0;
                duty             <= to_unsigned(v_loop_index, duty'length);
                v_expected_count := to_integer(duty);

                for j in 0 to (2 ** RESOLUTION) - 1 loop

                    wait until rising_edge(clk) and clk_ena = '1';

                    if (pwm = POLARITY) then
                        v_active_count := v_active_count + 1;
                    end if;

                end loop;

                check_equal(
                            v_active_count,
                            v_expected_count,
                            "Check duty cycle for duty = " & integer'image(v_loop_index)
                        );

                v_loop_index := v_loop_index + step_val;  -- manually step

            end loop;

        end procedure sweep_duty;

    begin

        test_runner_setup(runner, RUNNER_CFG);

        while test_suite loop

            -- duty sweep
            if run("duty_sweep") then
                -- Sweep up
                sweep_duty(1, 2 ** RESOLUTION, 1);

                -- Sweep down
                sweep_duty((2 ** RESOLUTION), 0, - 1);
                -- dummy cycle to check duty 0
                sweep_duty(0, 1, 1);
            end if;

            -- reset test
            if run("reset") then
                duty <= to_unsigned(2 ** (RESOLUTION - 1), duty'length);

                wait until rising_edge(clk);
                wait for 2 * PERIOD * CLK_PERIOD * (2 ** RESOLUTION) + PERIOD * CLK_PERIOD - CLK_PERIOD;

                check_equal(pwm, POLARITY, "Check PWM output before reset");

                reset <= '1';

                wait for PERIOD * CLK_PERIOD;

                check_equal(pwm, not POLARITY, "Check PWM output during reset");

                reset <= '0';

                wait for PERIOD * CLK_PERIOD;

                check_equal(pwm, POLARITY, "Check PWM output after reset");

                wait for PERIOD * CLK_PERIOD * (2 ** RESOLUTION);
            end if;

        end loop;

        -- Simulation ends here
        test_runner_cleanup(runner);

    end process proc_test_runner;

end architecture tb;
