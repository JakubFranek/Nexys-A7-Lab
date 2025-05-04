library ieee;
    use ieee.std_logic_1164.all;
    use ieee.math_real.floor;
    use ieee.numeric_std.all;

library vunit_lib;
    context vunit_lib.vunit_context;
    use work.bcd_conversion_package.all;
    use work.bcd_array_package.all;

entity unsigned_to_bcd_tb is
    generic (
        RUNNER_CFG : string;
        DECIMAL    : natural := 0
    );
end entity unsigned_to_bcd_tb;

architecture tb of unsigned_to_bcd_tb is

    constant DIGITS : natural                     := get_decimal_size(DECIMAL);
    constant BITS   : natural                     := DIGITS * 4;
    signal   binary : unsigned(BITS - 1 downto 0) := to_unsigned(DECIMAL, BITS);

begin

    proc_test_runner : process is

        variable v_result    : natural                          := 0;
        variable v_bcd_array : t_bcd_array(DIGITS - 1 downto 0) := (others => "XXXX");

    begin

        test_runner_setup(runner, RUNNER_CFG);

        show(get_logger(default_checker), display_handler, pass);

        v_bcd_array := unsigned_to_bcd(binary);

        for digit in DIGITS - 1 downto 0 loop

            v_result := v_result + (10 ** digit) * to_integer(v_bcd_array(digit));

        end loop;

        check_equal(v_result, DECIMAL, "Check conversion result");

        test_runner_cleanup(runner); -- Simulation ends here

    end process proc_test_runner;

end architecture tb;
