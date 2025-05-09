library ieee;
    use ieee.std_logic_1164.all;

library vunit_lib;
    context vunit_lib.vunit_context;

entity ps2_transceiver_tb is
    generic (
        RUNNER_CFG : string
    );
end entity ps2_transceiver_tb;

architecture tb of ps2_transceiver_tb is

    signal   clk            : std_logic := '1';
    signal   ps2_clk        : std_logic := '1';
    signal   ps2_data       : std_logic := '1';
    constant CLK_PERIOD     : time      := 10 ns;
    constant PS2_CLK_PERIOD : time      := 60 us;

    signal tx_start : std_logic                    := '0';
    signal tx_data  : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_data  : std_logic_vector(7 downto 0);
    signal tx_busy  : std_logic;
    signal tx_done  : std_logic;
    signal tx_error : std_logic;
    signal rx_busy  : std_logic;
    signal rx_done  : std_logic;
    signal rx_error : std_logic;

    procedure send_ps2_data (
        signal clock : out std_logic;
        signal data  : out std_logic;
        device_data  : std_logic_vector(8 downto 0)
    ) is

        variable v_data : std_logic_vector(8 downto 0) := device_data;

    begin

        data  <= '0'; -- Start bit
        wait for 0.5 * PS2_CLK_PERIOD;
        clock <= '0';
        wait for 0.5 * PS2_CLK_PERIOD;
        clock <= '1';

        for i in 0 to 7 loop

            data   <= v_data(8);
            wait for 0.5 * PS2_CLK_PERIOD;
            v_data := v_data(7 downto 0) & '0';
            clock  <= '0';
            wait for 0.5 * PS2_CLK_PERIOD;
            clock  <= '1';

        end loop;

        data  <= xor v_data; -- Odd parity bit
        wait for 0.5 * PS2_CLK_PERIOD;
        clock <= '0';
        wait for 0.5 * PS2_CLK_PERIOD;
        clock <= '1';
        data  <= '1';        -- Stop bit
        wait for 0.5 * PS2_CLK_PERIOD;
        clock <= '0';
        wait for 0.5 * PS2_CLK_PERIOD;
        clock <= '1';

    end procedure send_ps2_data;

begin

    inst_uut : entity work.ps2_transceiver
        port map (
            i_clk       => clk,
            i_reset     => '0',
            io_ps2_clk  => ps2_clk,
            io_ps2_data => ps2_data,
            i_tx_start  => '0',
            i_tx_data   => (others => '0'),
            o_tx_busy   => tx_busy,
            o_tx_done   => tx_done,
            o_tx_error  => tx_error,
            o_rx_data   => rx_data,
            o_rx_busy   => rx_busy,
            o_rx_done   => rx_done,
            o_rx_error  => rx_error
        );

    clk <= not clk after (CLK_PERIOD / 2);

    proc_test_runner : process is
    begin

        test_runner_setup(runner, RUNNER_CFG);

        show(get_logger(default_checker), display_handler, pass);

        /*wait for PS2_CLK_PERIOD;
        send_ps2_data(ps2_clk, ps2_data, "100101101");
        wait for PS2_CLK_PERIOD;*/

        while test_suite loop

            if run("receive") then
                wait for PS2_CLK_PERIOD;
                send_ps2_data(ps2_clk, ps2_data, "100101101");

                check(rx_data = "10010110", "Check the received data");
                check(rx_error = '0', "Check there is no RX error");
                check(rx_busy = '0', "Check RX is not busy");
            end if;

        end loop;

        test_runner_cleanup(runner); -- Simulation ends here

    end process proc_test_runner;

end architecture tb;
