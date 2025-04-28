----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 27.04.2025 22:03:31
-- Design Name:
-- Module Name: LED_PWM_top - Structural
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

    -- Uncomment the following library declaration if using
    -- arithmetic functions with Signed or Unsigned values
    use ieee.numeric_std.all;
    use ieee.math_real.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
-- library UNISIM;
-- use UNISIM.VComponents.all;

-- vsg_off
entity led_pwm_top is
    port (
        clk_100meg_hz : in    std_logic;
        led           : out   std_logic_vector(15 downto 0)
    );
end entity led_pwm_top;
-- vsg_on

architecture structural of led_pwm_top is

    constant CLOCK_PERIOD : time := 10 ns;
    constant LED_PERIOD   : time := 10 sec;

    signal clk_ena : std_logic_vector(15 downto 0);
    signal reset   : std_logic;

begin

    inst_reset_pulse_gen : entity work.clock_enable_generator
        generic map (
            PERIOD => LED_PERIOD / CLOCK_PERIOD
        )
        port map (
            i_clk     => clk_100meg_hz,
            o_clk_ena => reset
        );

    -- LED 0: on/off
    inst_clk_gen_led0 : entity work.clock_enable_generator
        generic map (
            PERIOD => LED_PERIOD / (2 * CLOCK_PERIOD)
        )
        port map (
            i_clk     => clk_100meg_hz,
            o_clk_ena => clk_ena(0)
        );

    inst_counter_led0 : entity work.counter
        generic map (
            WIDTH => 1
        )
        port map (
            i_clk       => clk_100meg_hz,
            i_enable    => clk_ena(0),
            i_direction => '1',
            i_reset     => reset,
            o_count(0)  => led(0),
            o_overflow  => open
        );

    gen_led_pwm : for i in 1 to 15 generate

        signal count_led : unsigned(i downto 0);

    begin

        inst_clk_gen : entity work.clock_enable_generator
            generic map (
                PERIOD => natural(floor(real(LED_PERIOD / ((2 ** i + 1) * CLOCK_PERIOD))))
            )
            port map (
                i_clk     => clk_100meg_hz,
                o_clk_ena => clk_ena(i)
            );

        inst_counter : entity work.counter
            generic map (
                WIDTH       => i + 1,
                COUNTER_MAX => (2 ** i) + 1
            )
            port map (
                i_clk       => clk_100meg_hz,
                i_enable    => clk_ena(i),
                i_direction => '1',
                i_reset     => reset,
                o_count     => count_led,
                o_overflow  => open
            );

        inst_pwm_gen : entity work.pwm_generator
            generic map (
                RESOLUTION => i,
                POLARITY   => '1'
            )
            port map (
                i_clk     => clk_100meg_hz,
                i_clk_ena => '1',
                i_reset   => '0',
                i_duty    => count_led,
                o_pwm     => led(i)
            );

    end generate gen_led_pwm;

end architecture structural;
