library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;
    use work.bcd_array_package.all;
    use work.bcd_conversion_package.all;
    use work.utilities_package.all;

library vunit_lib;
    context vunit_lib.vunit_context;

entity double_dabble_tb is
    generic (
        RUNNER_CFG : string;
        BINARY     : natural := 1234
    );
end entity double_dabble_tb;

architecture tb of double_dabble_tb is

    -- Generic parameters, min. values are because of limitations of the double_dabble entity
    constant BCD_DIGITS   : natural := maximum(get_decimal_size(BINARY), 2);
    constant BINARY_WIDTH : natural := maximum(get_binary_width(BINARY), 4);

    signal   clk        : std_logic := '0';
    constant CLK_PERIOD : time      := 20 ns;

    signal convert, reset : std_logic                           := '0';
    signal done,    ready : std_logic;
    signal binary_vector  : unsigned(BINARY_WIDTH - 1 downto 0) := to_unsigned(BINARY, BINARY_WIDTH);
    signal bcd_array      : t_bcd_array(BCD_DIGITS - 1 downto 0);

begin

    inst_uut : entity work.double_dabble
        generic map (
            RESET_ACTIVE_LEVEL => '1',
            BINARY_WIDTH       => BINARY_WIDTH,
            BCD_DIGITS         => BCD_DIGITS
        )
        port map (
            i_clk     => clk,
            i_reset   => reset,
            i_convert => convert,
            i_binary  => binary_vector,
            o_done    => done,
            o_ready   => ready,
            o_bcd     => bcd_array
        );

    clk <= not clk after (CLK_PERIOD / 2);

    proc_test_runner : process is

        variable v_result : natural := 0;

    begin

        test_runner_setup(runner, RUNNER_CFG);

        show(get_logger(default_checker), display_handler, pass);

        check_equal(ready, '1', "Check initial value of `o_ready`");
        check_equal(done, '0', "Check initial value of `o_done`");

        convert <= '1';

        wait until rising_edge(clk);
        wait for 1 ns;

        check_equal(ready, '0', "Check value of `o_ready`");

        -- conversion time is `BINARY_WIDTH - 1` clock cycles, wait for one less because the first occured above
        wait for (BINARY_WIDTH - 2) * CLK_PERIOD;
        wait for 1 ns;

        for d in 0 to BCD_DIGITS - 1 loop

            v_result := v_result + (10 ** d) * to_integer(bcd_array(d));

        end loop;

        check_equal(v_result, BINARY, "Check conversion result");
        check_equal(done, '1', "Check value of `o_done`");
        check_equal(ready, '1', "Check value of `o_ready`");

        wait until rising_edge(clk);
        wait until rising_edge(clk);

        test_runner_cleanup(runner); -- Simulation ends here

    end process proc_test_runner;

end architecture tb;
