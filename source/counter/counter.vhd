--! Simple unsigned parametrized counter.

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity counter is
    generic (
        --! counter width
        WIDTH : natural range 1 to natural'high := 4;
        --! maximum value of counter
        COUNTER_MAX : natural := 2 ** WIDTH - 1
    );
    port (
        --! input clock
        i_clk : in    std_logic;
        --! enable (is lower priority than reset)
        i_enable : in    std_logic;
        --! count up (1) or down (0)
        i_direction : in    std_logic;
        --! reset (has priority over enable)
        i_reset : in    std_logic;
        --! counter output
        o_count : out   unsigned(WIDTH - 1 downto 0) := (others => '0');
        --! overflow flag, active when counter overflows (counting up) or underflows (counting down)
        o_overflow : out   std_logic := '0'
    );
end entity counter;

architecture rtl of counter is

begin

    proc_clk : process (i_clk) is
    begin

        if rising_edge(i_clk) then
            if (i_reset = '1') then
                o_count    <= (others => '0');
                o_overflow <= '0';
            elsif (i_enable = '1') then
                -- count up
                if (i_direction = '1') then
                    if (o_count = COUNTER_MAX) then
                        o_overflow <= '1';
                        o_count    <= (others => '0');
                    else
                        o_count    <= o_count + 1;
                        o_overflow <= '0';
                    end if;

                -- count down
                else
                    if (o_count = 0) then
                        o_overflow <= '1';
                        o_count    <= to_unsigned(COUNTER_MAX, WIDTH);
                    else
                        o_count    <= o_count - 1;
                        o_overflow <= '0';
                    end if;
                end if;
            end if;
        end if;

    end process proc_clk;

end architecture rtl;

