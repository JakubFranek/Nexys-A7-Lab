library ieee;
    use ieee.std_logic_1164.all;
    use ieee.math_real.floor;
    use ieee.numeric_std.all;
    use work.bcd_conversion_package.all;
    use work.bcd_array_package.all;
    use work.utilities_package.all;

library vunit_lib;
    context vunit_lib.vunit_context;

entity unsigned_to_bcd_lut_tb is
    generic (
        RUNNER_CFG : string;
        DECIMAL    : natural := 0
    );
end entity unsigned_to_bcd_lut_tb;

architecture tb of unsigned_to_bcd_lut_tb is

    constant BINARY_WIDTH : natural                             := get_binary_width(DECIMAL);
    constant DIGITS       : natural                             := get_decimal_size(2 ** BINARY_WIDTH - 1);
    signal   binary       : unsigned(BINARY_WIDTH - 1 downto 0) := to_unsigned(DECIMAL, BINARY_WIDTH);
    signal   bcd_array    : t_bcd_array(DIGITS - 1 downto 0)    := (others => "XXXX");

begin

    inst_unsigned_to_bcd_lut : entity work.unsigned_to_bcd_lut
        generic map (
            BINARY_WIDTH => BINARY_WIDTH,
            BCD_DIGITS   => DIGITS
        )
        port map (
            i_binary => binary,
            o_bcd    => bcd_array
        );

    proc_test_runner : process is

        variable v_result : natural := 0;

    begin

        test_runner_setup(runner, RUNNER_CFG);

        show(get_logger(default_checker), display_handler, pass);

        bcd_array <= unsigned_to_bcd(binary);

        wait for 1 ns;

        for digit in DIGITS - 1 downto 0 loop

            v_result := v_result + (10 ** digit) * to_integer(bcd_array(digit));

        end loop;

        check_equal(v_result, DECIMAL, "Check conversion result");

        test_runner_cleanup(runner); -- Simulation ends here

    end process proc_test_runner;

end architecture tb;
