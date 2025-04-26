library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.log2;
    use ieee.math_real.ceil;

entity pwm_generator is
    generic (
        --! number of bits
        RESOLUTION : natural range 1 to natural'high := 10;
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

    signal   q_counter   : unsigned(RESOLUTION - 1 downto 0) := (others => '0');
    constant COUNTER_MAX : natural                           := 2 ** q_counter'length - 1;
    signal   q_duty      : unsigned(RESOLUTION downto 0)     := (others => '0');

begin

    proc_pwm : process (i_clk) is
    begin

        if rising_edge(i_clk) then
            if (i_reset = '1') then
                o_pwm     <= not POLARITY;
                q_counter <= (others => '0');
                q_duty    <= i_duty;
            else
                if (i_clk_ena = '1') then
                    if (q_counter = COUNTER_MAX) then
                        q_counter <= (others => '0');
                        q_duty    <= i_duty;
                    else
                        q_counter <= q_counter + 1;
                    end if;

                    if (q_counter = COUNTER_MAX) then
                        o_pwm <= POLARITY when i_duty /= 0 else not POLARITY;
                    else
                        if (q_counter < q_duty - 1 and q_duty /= 0) then
                            o_pwm <= POLARITY;
                        else
                            o_pwm <= not POLARITY;
                        end if;
                    end if;
                end if;
            end if;
        end if;

    end process proc_pwm;

end architecture rtl;
