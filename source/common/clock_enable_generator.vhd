library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.LOG2;
use ieee.math_real.ceil;

entity clock_enable_generator is
    generic (
        COUNTER_MAX : natural := 100000000 -- number of clock cycles to generate a clock enable signal
    );
    port (
        i_clk     : in std_logic;        -- input clock
        o_clk_ena : out std_logic := '0' -- clock enable signal, active high for one clock cycle
    );
end clock_enable_generator;

architecture Behavioral of clock_enable_generator is

    constant COUNTER_WIDTH : natural                              := natural(ceil(LOG2(real(COUNTER_MAX))));
    signal reg_counter     : unsigned(COUNTER_WIDTH - 1 downto 0) := (others => '0');

begin

    assert (COUNTER_MAX > 0) report "COUNTER_MAX must be a positive, non-zero value." severity failure;
    assert (COUNTER_WIDTH >= 1) report "COUNTER_BITS must be at least 1 bit." severity failure;
    assert (COUNTER_WIDTH <= 32) report "COUNTER_BITS exceeds the maximum allowed width of 32 bits." severity failure;

    clk_ena_proc : process (i_clk) begin
        if rising_edge(i_clk) then
            if (reg_counter = to_unsigned(COUNTER_MAX - 1, COUNTER_WIDTH)) then
                reg_counter <= (others => '0'); -- reset counter
                o_clk_ena   <= '1';             -- create clock enable pulse for one clock cycle
            else
                reg_counter <= reg_counter + 1;
                o_clk_ena   <= '0';
            end if;
        end if;
    end process;

end Behavioral;