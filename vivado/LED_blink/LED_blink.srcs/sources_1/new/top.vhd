----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 15.02.2025 21:40:54
-- Design Name:
-- Module Name: top - Structural
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
-- use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
-- library UNISIM;
-- use UNISIM.VComponents.all;

-- vsg_off
entity top is
    port (
        CLK_100M : in    std_logic;
        LED      : out   std_logic_vector(0 downto 0)
    );
end entity top;
-- vsg_on

architecture structural of top is

    signal clk_ena : std_logic;

begin

    inst_clk_ena_gen : entity work.clock_enable_generator
        generic map (
            PERIOD => 100000000
        )
        port map (
            i_clk     => CLK_100M,
            o_clk_ena => clk_ena
        );

    proc_led : process (CLK_100M) is
    begin

        if rising_edge(CLK_100M) then
            if (clk_ena = '1') then
                LED(0) <= not LED(0);
            end if;
        end if;

    end process proc_led;

end architecture structural;
