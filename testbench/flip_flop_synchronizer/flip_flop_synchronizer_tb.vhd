library ieee;
    use ieee.std_logic_1164.all;

library vunit_lib;
    context vunit_lib.vunit_context;

entity flip_flop_synchronizer_tb is
    generic (
        RUNNER_CFG : string;
        STAGES     : natural := 2
    );
end entity flip_flop_synchronizer_tb;

architecture tb of flip_flop_synchronizer_tb is

    signal   clk, async : std_logic := '0';
    signal   sync       : std_logic;
    constant CLK_PERIOD : time      := 10 ns;

begin

    inst_uut : entity work.flip_flop_synchronizer
        generic map (
            STAGES => STAGES
        )
        port map (
            i_clk   => clk,
            i_async => async,
            o_sync  => sync
        );

    clk <= not clk after (CLK_PERIOD / 2);

    proc_test_runner : process is
    begin

        test_runner_setup(runner, RUNNER_CFG);

        show(get_logger(default_checker), display_handler, pass);

        check(sync = '0', "Check initial value of `o_sync` is '0'");

        wait until rising_edge(clk);
        wait for (CLK_PERIOD * 0.5);

        async <= '1';

        for i in 1 to STAGES loop

            wait until rising_edge(clk);
            check(sync = '0', "Check `o_sync` is '0'");

        end loop;

        wait until rising_edge(clk);
        check(sync = '1', "Check `o_sync` is '1'");

        wait for (CLK_PERIOD * 0.5);

        async <= '0';

        for i in 1 to STAGES loop

            wait until rising_edge(clk);
            check(sync = '1', "Check `o_sync` is '1'");

        end loop;

        wait until rising_edge(clk);
        check(sync = '0', "Check `o_sync` is '0'");

        test_runner_cleanup(runner); -- Simulation ends here

    end process proc_test_runner;

end architecture tb;
