--! Parametrized PWM signal generator.
--!
--! The initial value of output `o_pwm` is `not POLARITY`. If `i_duty = 0`, then `o_pwm` is `not POLARITY`.
--! If `i_duty = 1`, then `o_pwm` is `POLARITY`. If `i_duty` is not 0 or 1, then in the first phase of the PWM
--! waveform the output is `POLARITY`.
--!
--! The resolution of duty cycle is `1/(2^RESOLUTION)`. For example, if `RESOLUTION = 2`,
--! then the duty cycle resolution is 1/4 and there are 5 possible duty cycle values:
--! 0, 1/4, 1/2, 3/4, 1.
--!
--! The frequency of the output PWM signal is `f_clk_ena/(2^RESOLUTION)`.
--!
--! The input `i_duty` is the desired duty cycle value. For example, if `i_duty = 3` and `RESOLUTION = 2`,
--! then the duty cycle is 3/4. The width of `i_duty` is `RESOLUTION + 1`, not `RESOLUTION`, as the extra bit
--! is needed to allow 100% duty cycle. Any `i_duty` value greater than `2^RESOLUTION - 1` is treated as 100%
--! duty cycle.
--!
--! The input `i_duty` is registered if `i_reset` is active or if `i_clk_ena` is active and the internal counter
--! is at its maximum value, i.e. at the end of the PWM period. During the PWM period the registered duty does not
--! change.
--!
--! The input `i_reset` is a synchronous reset. While active, it forces output to initial value, internal counter to
--! zero and registers the `i_duty` input.

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.log2;
    use ieee.math_real.ceil;

entity pwm_generator is
    generic (
        --! duty cycle resolution is 1/(2^RESOLUTION)
        RESOLUTION : natural range 1 to natural'high := 2;
        --! output active polarity
        POLARITY : std_logic := '1'
    );
    port (
        i_clk     : in    std_logic;                     --! input clock
        i_clk_ena : in    std_logic;                     --! clock enable
        i_reset   : in    std_logic;                     --! reset signal
        i_duty    : in    unsigned(RESOLUTION downto 0); --! PWM duty (i_pwm_value / 2^RESOLUTION)
        o_pwm     : out   std_logic := not POLARITY      --! PWM output
    );
end entity pwm_generator;

architecture rtl of pwm_generator is

    --! counter
    signal q_counter : unsigned(RESOLUTION - 1 downto 0) := (others => '0');
    --! maximum value of counter
    constant COUNTER_MAX : natural := 2 ** q_counter'length - 1;
    --! registered duty input
    signal q_duty : unsigned(RESOLUTION downto 0) := (others => '0');

begin

    proc_pwm : process (i_clk) is
    begin

        if rising_edge(i_clk) then
            -- synchronous reset
            if (i_reset = '1') then
                o_pwm     <= not POLARITY;
                q_counter <= (others => '0');
                q_duty    <= i_duty;
            else
                if (i_clk_ena = '1') then
                    if (q_counter = COUNTER_MAX) then
                        q_counter <= (others => '0');
                        q_duty    <= i_duty; -- register `i_duty`
                    else
                        q_counter <= q_counter + 1;
                    end if;

                    if (q_counter = COUNTER_MAX) then
                        -- first phase output initialization
                        o_pwm <= POLARITY when i_duty /= 0 else not POLARITY;
                    else
                        if (q_counter < q_duty - 1 and q_duty /= 0) then
                            -- still in first phase of PWM waveform
                            o_pwm <= POLARITY;
                        else
                            -- second phase of PWM waveform
                            o_pwm <= not POLARITY;
                        end if;
                    end if;
                end if;
            end if;
        end if;

    end process proc_pwm;

end architecture rtl;
