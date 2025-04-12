--! BCD counter with generic number of decimal digits.
------------------------------------------------------------
--! { signal: [
--!  { name: "i_clk",           wave: "P..........." },
--!  { name: "i_enable",        wave: "01.........." },
--!  { name: "i_direction",     wave: "1..........." },
--!  { name: "i_reset",         wave: "0..........." },
--!  { name: "o_decimals(0)",   wave: "=.==========", data: [0,1,2,"...",9,0,1,"...",9,0,1] },
--!  { name: "o_decimals(1)",   wave: "=...===.===.", data: [0,"...",0,1,"...",9,0] },
--!  { name: "o_overflow",      wave: "0.........10" }
--! ],
--!                             gaps: '. . . . s . . . s',
--!  head:{
--!     text:'Time diagram (for DECIMALS = 2)',
--!     tick:0,
--!     every:1
--!   },
--! }
------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use work.bcd_array_package.all;
    use ieee.numeric_std.all;

entity bcd_counter is
    generic (
        --! number of decimal digits
        DECIMALS : natural range 1 to natural'high := 2
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
        --! output digits, index 0 is the least significant
        o_decimals : out   t_bcd_array(DECIMALS - 1 downto 0) := (others => "0000");
        --! overflow flag, active when most significant digit overflows (counting up) or underflows (counting down)
        o_overflow : out   std_logic := '0'
    );
end entity bcd_counter;

architecture rtl of bcd_counter is

begin

    proc_clk : process (i_clk) is

        variable v_carry : boolean := true;

    begin

        if rising_edge(i_clk) then
            if (i_reset = '1') then
                o_decimals <= (others => "0000");
                o_overflow <= '0';
            elsif (i_enable = '1') then
                v_carry := true; -- reset carry to true at the start of the process

                -- count up
                if (i_direction = '1') then

                    for i in 0 to (DECIMALS - 1) loop

                        if (v_carry) then
                            if (o_decimals(i) = "1001") then
                                o_decimals(i) <= (others => '0');
                                v_carry       := true;
                            else
                                o_decimals(i) <= o_decimals(i) + 1;
                                v_carry       := false;
                            end if;
                        end if;

                    end loop;

                -- count down
                else

                    for i in 0 to (DECIMALS - 1) loop

                        if (v_carry) then
                            if (o_decimals(i) = "0000") then
                                o_decimals(i) <= "1001";
                                v_carry       := true;
                            else
                                o_decimals(i) <= o_decimals(i) - 1;
                                v_carry       := false;
                            end if;
                        end if;

                    end loop;

                end if;

                o_overflow <= '1' when v_carry else '0';
            end if;
        end if;

    end process proc_clk;

end architecture rtl;

