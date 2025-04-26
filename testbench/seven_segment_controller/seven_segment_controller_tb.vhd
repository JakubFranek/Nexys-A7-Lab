library ieee;
    use ieee.std_logic_1164.all;
    use work.digit_record_package.all;
    use ieee.numeric_std.all;

library vunit_lib;
    context vunit_lib.vunit_context;

entity seven_segment_controller_tb is
    generic (
        RUNNER_CFG           : string;
        SEGMENT_ACTIVE_LEVEL : std_logic := '0';
        DIGIT_ACTIVE_LEVEL   : std_logic := '0'
    );
end entity seven_segment_controller_tb;

architecture tb of seven_segment_controller_tb is

    constant CLK_PERIOD     : time    := 20 ns;
    constant CLK_ENA_PERIOD : natural := 2;
    constant DIGITS         : natural := 2;

    signal clk          : std_logic := '0';
    signal clk_ena      : std_logic;
    signal digit_array  : t_digit_array(DIGITS - 1 downto 0);
    signal segments     : std_logic_vector(7 downto 0);
    signal digit_enable : std_logic_vector(DIGITS - 1 downto 0);

    type t_segment_array is array (natural range <>) of std_logic_vector(6 downto 0);

    --! array of predefined segment patterns, assumes active level is '1', DP not included
    constant SEGMENTS_ARRAY : t_segment_array(0 to 15) :=
    (
        "1111110", -- 0
        "0110000", -- 1
        "1101101", -- 2
        "1111001", -- 3
        "0110011", -- 4
        "1011011", -- 5
        "1011111", -- 6
        "1110000", -- 7
        "1111111", -- 8
        "1111011", -- 9
        "1110111", -- A
        "0011111", -- B
        "1001110", -- C
        "0111101", -- D
        "1001111", -- E
        "1000111"  -- F
    );

    function get_expected_segments (
        digit : t_digit
    ) return std_logic_vector is

        variable v_result : std_logic_vector(7 downto 0);

    begin

        v_result := SEGMENTS_ARRAY(to_integer(digit.value)) & digit.decimal_point;

        if (SEGMENT_ACTIVE_LEVEL = '0') then
            v_result := not v_result;
        end if;

        return v_result;

    end function get_expected_segments;

begin

    inst_clk_ena : entity work.clock_enable_generator
        generic map (
            PERIOD => CLK_ENA_PERIOD
        )
        port map (
            i_clk     => clk,
            o_clk_ena => clk_ena
        );

    inst_uut : entity work.seven_segment_controller
        generic map (
            DIGITS               => DIGITS,
            SEGMENT_ACTIVE_LEVEL => SEGMENT_ACTIVE_LEVEL,
            DIGIT_ACTIVE_LEVEL   => DIGIT_ACTIVE_LEVEL
        )
        port map (
            i_clk          => clk,
            i_clk_ena      => clk_ena,
            i_digits       => digit_array,
            o_segments     => segments,
            o_digit_enable => digit_enable
        );

    clk <= not clk after (CLK_PERIOD / 2);

    proc_test_runner : process is

        variable v_expected_segments : std_logic_vector(7 downto 0) := (others => '0');

    begin

        test_runner_setup(runner, RUNNER_CFG);

        show(get_logger(default_checker), display_handler, pass);

        -- digit_array initialization
        for i in 0 to DIGITS - 1 loop

            digit_array(i).value         <= to_unsigned(0, digit_array(i).value'length);
            digit_array(i).decimal_point <= '0';
            digit_array(i).enable        <= '1';

        end loop;

        -- testing digit_array
        for j in 0 to 15 loop

            digit_array(0).value <= to_unsigned(j, digit_array(0).value'length);
            digit_array(1).value <= to_unsigned(15 - j, digit_array(1).value'length);

            wait until rising_edge(clk) and clk_ena = '1';

            -- checking digit_array(0)

            v_expected_segments := get_expected_segments(digit_array(0));

            check_equal(segments, v_expected_segments, "Check segments for digit " & integer'image(j));
            check(digit_enable(0) = DIGIT_ACTIVE_LEVEL, "Check `digit_enable(0)` is active");
            check(digit_enable(1) = not DIGIT_ACTIVE_LEVEL, "Check `digit_enable(1)` is inactive");

            wait until rising_edge(clk) and clk_ena = '1';

            -- checking digit_array(1)

            v_expected_segments := get_expected_segments(digit_array(1));

            check_equal(segments, v_expected_segments, "Check segments for digit " & integer'image(15 - j));
            check(digit_enable(1) = DIGIT_ACTIVE_LEVEL, "Check `digit_enable(1)` is active");
            check(digit_enable(0) = not DIGIT_ACTIVE_LEVEL, "Check `digit_enable(0)` is inactive");

        end loop;

        -- test decimal points
        digit_array(0).decimal_point <= '1';
        digit_array(1).decimal_point <= '1';

        wait until rising_edge(clk) and clk_ena = '1';

        v_expected_segments := get_expected_segments(digit_array(0));

        check_equal(segments, v_expected_segments, "Check segments for digit 15 and decimal point enabled");

        wait until rising_edge(clk) and clk_ena = '1';

        v_expected_segments := get_expected_segments(digit_array(1));

        check_equal(segments, v_expected_segments, "Check segments for digit 0 and decimal point enabled");

        -- test disable
        digit_array(0).enable <= '0';
        v_expected_segments   := (others => not SEGMENT_ACTIVE_LEVEL);

        wait until rising_edge(clk) and clk_ena = '1';

        check_equal(segments, v_expected_segments, "Check segments for disabled digit_array(0)");

        digit_array(1).enable <= '0';

        wait until rising_edge(clk) and clk_ena = '1';

        check_equal(segments, v_expected_segments, "Check segments for disabled digit_array(1)");

        test_runner_cleanup(runner); -- Simulation ends here

    end process proc_test_runner;

end architecture tb;
