library ieee;
    use ieee.std_logic_1164.all;
    use work.bcd_array_package.all;
    use ieee.numeric_std.all;

library vunit_lib;
    context vunit_lib.vunit_context;

entity bcd_counter_tb is
    generic (
        RUNNER_CFG : string;
        DIGITS     : natural := 3
    );
end entity bcd_counter_tb;

architecture tb of bcd_counter_tb is

    signal   clk        : std_logic := '0';
    signal   enable     : std_logic := '0';
    signal   direction  : std_logic := '0';
    signal   reset      : std_logic := '0';
    signal   decimals   : t_bcd_array(DIGITS - 1 downto 0);
    signal   overflow   : std_logic;
    constant CLK_PERIOD : time      := 20 ns;

    signal dec0 : unsigned (3 downto 0);
    signal dec1 : unsigned (3 downto 0);
    signal dec2 : unsigned (3 downto 0);

    signal count : natural;

begin

    inst_uut : entity work.bcd_counter
        generic map (
            DECIMALS => DIGITS
        )
        port map (
            i_clk       => clk,
            i_enable    => enable,
            i_direction => direction,
            i_reset     => reset,
            o_decimals  => decimals,
            o_overflow  => overflow
        );

    clk <= not clk after (CLK_PERIOD / 2);

    dec0 <= decimals(0);
    dec1 <= decimals(1);
    dec2 <= decimals(2);

    count <= to_integer(dec0) + to_integer(dec1) * 10 + to_integer(dec2) * 100;

    proc_test_runner : process is
    begin

        test_runner_setup(runner, RUNNER_CFG);

        show(get_logger(default_checker), display_handler, pass);

        while test_suite loop

            -- count up
            if run("count_up") then
                enable    <= '1';
                direction <= '1';
                reset     <= '0';

                check(count = 0, "Check `count` is 0 at start");

                wait until rising_edge(clk);

                wait for 999 * CLK_PERIOD;

                check(count = 999, "Check `count` is 999 after 999 clock cycles");
                check(overflow = '0', "Check `o_overflow` is '0' after 999 clock cycles");

                wait for CLK_PERIOD;

                check(count = 0, "Check `count` is 0 after overflowing from 999");
                check(overflow = '1', "Check `o_overflow` is '1' after overflowing from 999");
            end if;

            -- count down
            if run("count_down") then
                enable    <= '1';
                direction <= '0';
                reset     <= '0';

                check(count = 0, "Check `count` is 0 at start");
                check(overflow = '0', "Check `o_overflow` is '0' at start");

                wait until rising_edge(clk);

                wait for CLK_PERIOD;

                check(count = 999, "Check `count` is 999 after 1 clock cycle");
                check(overflow = '1', "Check `o_overflow` is '1' after 1 clock cycle");

                wait for 999 * CLK_PERIOD;

                check(count = 0, "Check `count` is 0 after 1000 clock cycles");
                check(overflow = '0', "Check `o_overflow` is '0' after 1000 clock cycles");

                wait for CLK_PERIOD;

                check(count = 999, "Check `count` is 999 after overflowing from 0");
                check(overflow = '1', "Check `o_overflow` is '1' after overflowing from 0");
            end if;

            -- count up and reset
            if run("count_up_reset") then
                enable    <= '1';
                direction <= '1';
                reset     <= '0';

                check(count = 0, "Check `count` is 0 at start");
                check(overflow = '0', "Check `o_overflow` is '0' at start");

                wait until rising_edge(clk);

                wait for 100 * CLK_PERIOD;

                check(count = 100, "Check `count` is 100 after 100 clock cycles");

                wait until falling_edge(clk);

                reset <= '1';

                wait for CLK_PERIOD;

                reset <= '0';

                check(count = 0, "Check `count` is 0 after reset");

                wait for CLK_PERIOD;
            end if;

            -- count up and down
            if run("count_up_down") then
                enable    <= '1';
                direction <= '1';
                reset     <= '0';

                check(count = 0, "Check `count` is 0 at start");
                check(overflow = '0', "Check `o_overflow` is '0' at start");

                wait until rising_edge(clk);

                wait for 100 * CLK_PERIOD;

                check(count = 100, "Check `count` is 100 after 100 clock cycles of counting up");

                -- rising edge caused increment to 101

                wait until falling_edge(clk);

                direction <= '0';

                wait for CLK_PERIOD;

                check(count = 100, "Check `count` is 100 after 101 clock cycles and direction change");

                wait for CLK_PERIOD;

                check(count = 99, "Check `count` is 99 after 102 clock cycles and direction change");

                wait for 99 * CLK_PERIOD;

                check(count = 0, "Check `count` is 0 after 200 clock cycles and direction change");
            end if;

        end loop;

        test_runner_cleanup(runner); -- Simulation ends here

    end process proc_test_runner;

end architecture tb;
