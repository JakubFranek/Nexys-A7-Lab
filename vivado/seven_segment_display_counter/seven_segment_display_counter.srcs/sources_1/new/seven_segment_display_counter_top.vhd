----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 12.04.2025 20:17:59
-- Design Name:
-- Module Name: top - structural
-- Project Name:
-- Target Devices:
-- Tool Versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use work.bcd_array_package.all;
    use work.digit_record_package.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
-- use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
-- library UNISIM;
-- use UNISIM.VComponents.all;

-- vsg_off
entity seven_segment_display_counter_top is
    port (
        clk_100meg_hz : in    std_logic;
        btnc          : in    std_logic;
        btnu          : in    std_logic;
        btnd          : in    std_logic;
        sw            : in    std_logic_vector(1 downto 0);
        seg           : out   std_logic_vector(6 downto 0);
        dp            : out   std_logic;
        an            : out   std_logic_vector(7 downto 0)
    );
end entity seven_segment_display_counter_top;
-- vsg_on

architecture structural of seven_segment_display_counter_top is

    signal clk_ena_1000_hz, clk_ena_1_hz : std_logic;

    signal button           : std_logic_vector(4 downto 0);
    signal button_debounced : std_logic_vector(4 downto 0);
    signal button_pressed   : std_logic_vector(4 downto 0);

    signal decimals_right,  decimals_left : t_bcd_array(3 downto 0);
    signal digits                         : t_digit_array(7 downto 0);

begin

    button(0) <= btnc;  -- right counter reset
    button(1) <= btnu;  -- right counter enable
    button(2) <= btnd;  -- left counter reset
    button(3) <= sw(0); -- right counter direction
    button(4) <= sw(1); -- left counter direction

    inst_clk_ena_gen_100_hz : entity work.clock_enable_generator
        generic map (
            PERIOD => 100000
        )
        port map (
            i_clk     => clk_100meg_hz,
            o_clk_ena => clk_ena_1000_hz
        );

    inst_clk_ena_gen_1_hz : entity work.clock_enable_generator
        generic map (
            PERIOD => 100000000
        )
        port map (
            i_clk     => clk_100meg_hz,
            o_clk_ena => clk_ena_1_hz
        );

    gen_debouncers : for i in 0 to 4 generate

        inst_debouncer : entity work.debouncer
            generic map (
                PERIOD => 50
            )
            port map (
                i_clk     => clk_100meg_hz,
                i_clk_ena => clk_ena_1000_hz,
                i_input   => button(i),
                o_output  => button_debounced(i)
            );

        inst_edge_detector : entity work.edge_detector
            port map (
                i_clk          => clk_100meg_hz,
                i_input        => button_debounced(i),
                o_rising_edge  => button_pressed(i),
                o_falling_edge => open,
                o_any_edge     => open
            );

    end generate gen_debouncers;

    inst_bcd_counter_right : entity work.bcd_counter
        generic map (
            DECIMALS => 4
        )
        port map (
            i_clk       => clk_100meg_hz,
            i_enable    => button_pressed(1),
            i_direction => button_debounced(3),
            i_reset     => button_pressed(0),
            o_decimals  => decimals_right,
            o_overflow  => open
        );

    inst_bcd_counter_left : entity work.bcd_counter
        generic map (
            DECIMALS => 4
        )
        port map (
            i_clk       => clk_100meg_hz,
            i_enable    => clk_ena_1_hz,
            i_direction => button_debounced(4),
            i_reset     => button_pressed(2),
            o_decimals  => decimals_left,
            o_overflow  => open
        );

    inst_seven_segment_controller : entity work.seven_segment_controller
        generic map (
            DIGITS               => 8,
            DIGIT_ACTIVE_LEVEL   => '0',
            SEGMENT_ACTIVE_LEVEL => '0'
        )
        port map (
            i_clk                  => clk_100meg_hz,
            i_clk_ena              => clk_ena_1000_hz,
            i_digits               => digits,
            o_segments(7 downto 1) => seg,
            o_segments(0)          => dp,
            o_digit_enable         => an
        );

    digits(0).value         <= decimals_right(0);
    digits(1).value         <= decimals_right(1);
    digits(2).value         <= decimals_right(2);
    digits(3).value         <= decimals_right(3);
    digits(4).value         <= decimals_left(0);
    digits(5).value         <= decimals_left(1);
    digits(6).value         <= decimals_left(2);
    digits(7).value         <= decimals_left(3);
    digits(0).decimal_point <= '0';
    digits(1).decimal_point <= '0';
    digits(2).decimal_point <= '0';
    digits(3).decimal_point <= '0';
    digits(4).decimal_point <= '0';
    digits(5).decimal_point <= '0';
    digits(6).decimal_point <= '0';
    digits(7).decimal_point <= '0';
    digits(0).enable        <= '1';
    digits(1).enable        <= '1';
    digits(2).enable        <= '1';
    digits(3).enable        <= '1';
    digits(4).enable        <= '1';
    digits(5).enable        <= '1';
    digits(6).enable        <= '1';
    digits(7).enable        <= '1';

end architecture structural;
