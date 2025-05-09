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
    signal   ps2_clk        : std_logic := 'H';
    signal   ps2_data       : std_logic := 'H';
    constant CLK_PERIOD     : time      := 10 ns;
    constant PS2_CLK_PERIOD : time      := 60 us;

    signal reset    : std_logic                    := '0';
    signal tx_start : std_logic                    := '0';
    signal tx_data  : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_data  : std_logic_vector(7 downto 0);
    signal tx_busy  : std_logic;
    signal tx_done  : std_logic;
    signal tx_error : std_logic;
    signal rx_busy  : std_logic;
    signal rx_done  : std_logic;
    signal rx_error : std_logic;

    signal tb_shiftreg : std_logic_vector(9 downto 0) := (others => '0');

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
        clock <= 'Z';

        for i in 0 to 7 loop

            data   <= 'Z' when v_data(0) = '1' else '0';
            wait for 0.5 * PS2_CLK_PERIOD;
            v_data := '0' & v_data(8 downto 1);
            clock  <= '0';
            wait for 0.5 * PS2_CLK_PERIOD;
            clock  <= 'Z';

        end loop;

        data  <= 'Z' when (xor to_x01(v_data) = '1') else '0'; -- Odd parity bit
        wait for 0.5 * PS2_CLK_PERIOD;
        clock <= '0';
        wait for 0.5 * PS2_CLK_PERIOD;
        clock <= 'Z';
        data  <= 'Z';                                          -- Stop bit
        wait for 0.5 * PS2_CLK_PERIOD;
        clock <= '0';
        wait for 0.5 * PS2_CLK_PERIOD;
        clock <= 'Z';

    end procedure send_ps2_data;

    procedure receive_ps2_data (
        signal clock    : out std_logic;
        signal data     : inout std_logic;
        signal shiftreg : inout std_logic_vector(9 downto 0)
    ) is
    begin

        wait for 0.5 * PS2_CLK_PERIOD;
        shiftreg <= (others => '0');

        for i in 0 to 9 loop

            clock    <= '0';
            wait for 0.5 * PS2_CLK_PERIOD;
            clock    <= 'Z';
            shiftreg <= to_x01(data) & tb_shiftreg(9 downto 1);
            wait for 0.5 * PS2_CLK_PERIOD;

        end loop;

        clock <= '0';
        wait for 0.5 * PS2_CLK_PERIOD;
        clock <= 'Z';
        data  <= '0'; -- Acknowledge bit
        wait for 0.5 * PS2_CLK_PERIOD;
        clock <= '0';
        wait for 0.5 * PS2_CLK_PERIOD;
        clock <= 'Z';
        data  <= 'Z';

    end procedure receive_ps2_data;

begin

    inst_uut : entity work.ps2_transceiver
        port map (
            i_clk       => clk,
            i_reset     => reset,
            io_ps2_clk  => ps2_clk,
            io_ps2_data => ps2_data,
            i_tx_start  => tx_start,
            i_tx_data   => tx_data,
            o_tx_busy   => tx_busy,
            o_tx_done   => tx_done,
            o_tx_error  => tx_error,
            o_rx_data   => rx_data,
            o_rx_busy   => rx_busy,
            o_rx_done   => rx_done,
            o_rx_error  => rx_error
        );

    clk <= not clk after (CLK_PERIOD / 2);

    -- Pull-ups
    ps2_clk  <= 'H';
    ps2_data <= 'H';

    proc_test_runner : process is

        variable v_timestamp : time := 0 ns;

    begin

        test_runner_setup(runner, RUNNER_CFG);

        show(get_logger(default_checker), display_handler, pass);

        while test_suite loop

            if run("receive") then
                wait for PS2_CLK_PERIOD;

                send_ps2_data(ps2_clk, ps2_data, "110010110");
                check_equal(rx_data, std_logic_vector'("10010110"), "Check the received data (1st packet)");
                check_equal(rx_error, '0', "Check there is no RX error after 1st packet");
                check_equal(rx_busy, '0', "Check RX is not busy after 1st packet");

                send_ps2_data(ps2_clk, ps2_data, "000011010");
                check_equal(rx_data, std_logic_vector'("00011010"), "Check the received data (2nd packet)");
                check_equal(rx_error, '0', "Check there is no RX error after 2nd packet");
                check_equal(rx_busy, '0', "Check RX is not busy after 2nd packet");

                wait for PS2_CLK_PERIOD;
            elsif run("transmit") then
                tx_data     <= "10010110";
                wait for CLK_PERIOD;
                tx_start    <= '1';
                wait until falling_edge(ps2_clk);
                tx_start    <= '0';
                v_timestamp := now;
                wait until rising_edge(ps2_clk);
                check_relation(now - v_timestamp >= 100 us,
                               "Check that PS/2 clock has been held low for at least 100 us");
                wait for CLK_PERIOD;
                check_equal(ps2_data, '0', "Check that PS/2 data is low (TX start bit)");
                receive_ps2_data(ps2_clk, ps2_data, tb_shiftreg);

                check_equal(tb_shiftreg, std_logic_vector'("1110010110"), "Check the transmitted data");
                check_equal(tx_error, '0', "Check there is no TX error");

                wait for 5 us;
                check_equal(tx_busy, '0', "Check TX is not busy after complete transmission");

                wait for PS2_CLK_PERIOD;
            end if;

        end loop;

        test_runner_cleanup(runner); -- Simulation ends here

    end process proc_test_runner;

end architecture tb;
