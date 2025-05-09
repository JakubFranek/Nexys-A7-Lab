library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.utilities_package.all;

entity ps2_transceiver is
    generic (
        -- System clock frequency in Hz
        CLOCK_FREQUENCY : natural := 100_000_000
    );
    port (
        --! System clock
        i_clk : in    std_logic;
        --! Synchronous reset signal
        i_reset : in    std_logic;
        --! PS/2 clock signal
        io_ps2_clk : inout std_logic := 'Z';
        --! PS/2 data signal
        io_ps2_data : inout std_logic := 'Z';
        --! TX start transmission (active high)
        i_tx_start : in    std_logic;
        --! TX data to be sent to device
        i_tx_data : in    std_logic_vector(7 downto 0);
        --! TX busy (transmitting if high)
        o_tx_busy : out   std_logic := '0';
        --! TX done, single `i_clk` cycle active high pulse
        o_tx_done : out   std_logic := '0';
        --! TX acknowledge not received (error if high)
        o_tx_error : out   std_logic := '0';
        --! RX data received
        o_rx_data : out   std_logic_vector(7 downto 0) := (others => '0');
        --! RX busy (receiving if high)
        o_rx_busy : out   std_logic := '0';
        --! RX done, single `i_clk` cycle active high pulse
        o_rx_done : out   std_logic := '0';
        --! RX error (error if high)
        o_rx_error : out   std_logic := '0'
    );
end entity ps2_transceiver;

architecture rtl of ps2_transceiver is

    signal clk_ena_1us : std_logic; -- 1 MHz multi-purpose clock

    signal reset : std_logic;

    signal ps2_clk_clean  : std_logic; -- Synchronized and debounced PS/2 clock line
    signal ps2_data_clean : std_logic; -- Synchronized and debounced PS/2 data line

    signal ps2_clk_falling : std_logic; --

    -- Shift register: Start bit (MSB), 8 data bits, stop bit, odd parity bit (LSB)
    signal q_shiftreg         : std_logic_vector(10 downto 0) := (others => '0');
    signal q_shiftreg_counter : unsigned(3 downto 0)          := (others => '0');
    -- Maximum value of shift register counter, 1 (start bit) + 8 (data bits) + 1 (parity) + 1 (stop bit) = 11
    constant SHIFTREG_COUNTER_MAX : natural := 11;

    type t_fsm_state is (
        S_RX,
        S_INHIBIT,
        S_TX,
        S_TX_DONE,
        S_RESET
    );

    signal state : t_fsm_state := S_RX;

    constant INHIBIT_COUNTER_MAX   : natural := 100;
    constant INHIBIT_COUNTER_WIDTH : natural := get_binary_width(INHIBIT_COUNTER_MAX);

    signal inhibit_counter       : unsigned(INHIBIT_COUNTER_WIDTH - 1 downto 0) := (others => '0');
    signal inhibit_counter_reset : std_logic;

    constant WATCHDOG_COUNTER_MAX   : natural := 2000; -- 2 ms when counted by the `clk_ena_1us` clock
    constant WATCHDOG_COUNTER_WIDTH : natural := get_binary_width(WATCHDOG_COUNTER_MAX);

    signal watchdog_reset    : std_logic;
    signal watchdog_overflow : std_logic;
    signal watchdog_count    : unsigned(WATCHDOG_COUNTER_WIDTH - 1 downto 0) := (others => '0');

begin

    -------------------------------------------------------------------------------------------------------------------
    inst_clk_gen_1mhz : entity work.clock_enable_generator
        generic map (
            PERIOD => CLOCK_FREQUENCY / (1_000_000)
        )
        port map (
            i_clk     => i_clk,
            o_clk_ena => clk_ena_1us
        );

    -- Target debouncing period is 5 microseconds
    inst_ps2_clock_debouncer : entity work.debouncer
        generic map (
            PERIOD => 4
        )
        port map (
            i_input   => to_x01(io_ps2_clk),
            i_clk     => i_clk,
            i_clk_ena => clk_ena_1us,
            o_output  => ps2_clk_clean
        );

    -- Target debouncing period is 5 microseconds
    inst_ps2_data_debouncer : entity work.debouncer
        generic map (
            PERIOD => 4
        )
        port map (
            i_input   => to_x01(io_ps2_data),
            i_clk     => i_clk,
            i_clk_ena => clk_ena_1us,
            o_output  => ps2_data_clean
        );

    inst_ps2_clock_edge_detector : entity work.edge_detector
        port map (
            i_clk          => i_clk,
            i_input        => ps2_clk_clean,
            o_rising_edge  => open,
            o_falling_edge => ps2_clk_falling,
            o_any_edge     => open
        );

    inst_inhibit_counter : entity work.counter
        generic map (

            WIDTH       => INHIBIT_COUNTER_WIDTH,
            COUNTER_MAX => INHIBIT_COUNTER_MAX
        )
        port map (
            i_clk       => i_clk,
            i_enable    => clk_ena_1us,
            i_direction => '1',
            i_reset     => inhibit_counter_reset,
            o_count     => inhibit_counter
        );

    inst_watchdog_counter : entity work.counter
        generic map (
            WIDTH       => WATCHDOG_COUNTER_WIDTH,
            COUNTER_MAX => WATCHDOG_COUNTER_MAX
        )
        port map (
            i_clk       => i_clk,
            i_enable    => clk_ena_1us,
            i_direction => '1',
            i_reset     => watchdog_reset,
            o_count     => watchdog_count,
            o_overflow  => watchdog_overflow
        );

    -------------------------------------------------------------------------------------------------------------------

    proc_fsm : process (i_clk) is

        variable v_next_state : t_fsm_state; --! Next value of `state`

    begin

        if rising_edge(i_clk) then
            if (i_reset = '1') then
                state <= S_RESET;
            else
                -- Default assignments
                v_next_state := state;

                case state is

                    when S_RESET =>

                        v_next_state := S_RX;

                    when S_RX =>

                        if (i_tx_start = '1') then
                            v_next_state := S_INHIBIT;
                        elsif (watchdog_overflow = '1' and o_rx_busy = '1') then
                            v_next_state := S_RESET;
                        end if;

                    when S_INHIBIT =>

                        if (inhibit_counter = INHIBIT_COUNTER_MAX) then
                            v_next_state := S_TX;
                        end if;

                    when S_TX =>

                        if (o_tx_done = '1') then
                            v_next_state := S_TX_DONE;
                        elsif (watchdog_overflow = '1') then
                            v_next_state := S_RESET;
                        end if;

                    when S_TX_DONE =>

                        if (ps2_clk_clean = '1' and ps2_data_clean = '1') then
                            v_next_state := S_RX;
                        end if;

                    when others =>

                        assert false
                            report "Invalid PS/2 transceiver state."
                            severity failure;
                        v_next_state := S_RX;

                end case;

                state <= v_next_state;
            end if;
        end if;

    end process proc_fsm;

    -------------------------------------------------------------------------------------------------------------------
    proc_fsm_comb : process (all) is
    begin

        -- Default assignments
        inhibit_counter_reset <= '1';
        io_ps2_clk            <= 'Z';
        io_ps2_data           <= 'Z';
        o_tx_busy             <= '0';
        o_rx_busy             <= '0';
        watchdog_reset        <= '1';

        case state is

            when S_RESET =>

                reset <= '1';

            when S_RX =>

                o_rx_busy      <= '1' when (q_shiftreg_counter /= 0) else
                                  '0';
                watchdog_reset <= '0' when (q_shiftreg_counter /= 0) else
                                  '1';

            when S_INHIBIT =>

                inhibit_counter_reset <= '0';
                io_ps2_clk            <= '0';
                o_tx_busy             <= '1';

            when S_TX =>

                o_tx_busy      <= '1';
                watchdog_reset <= '0';
                io_ps2_data    <= 'Z' when q_shiftreg(q_shiftreg'low) = '1' else '0';

            when S_TX_DONE =>

                o_tx_busy <= '1';

            when others =>

                assert false
                    report "Invalid PS/2 transceiver state."
                    severity failure;

        end case;

    end process proc_fsm_comb;

    -------------------------------------------------------------------------------------------------------------------
    proc_shiftreg : process (i_clk) is

        variable v_rx_parity : std_logic;

    begin

        if rising_edge(i_clk) then
            if (reset = '1' or (state = S_TX_DONE)) then
                q_shiftreg         <= (others => '0');
                q_shiftreg_counter <= (others => '0');
                o_rx_data          <= (others => '0');
                o_rx_error         <= '0';
                o_rx_done          <= '0';
                o_tx_done          <= '0';
                o_tx_error         <= '0';
            elsif (state = S_RX) then
                -- Default assignments
                o_rx_done  <= '0';
                o_rx_error <= '1' when (watchdog_overflow = '1') else '0';

                if (ps2_clk_falling = '1') then
                    q_shiftreg <= ps2_data_clean & q_shiftreg(10 downto 1);

                    if (q_shiftreg_counter < SHIFTREG_COUNTER_MAX) then
                        q_shiftreg_counter <= q_shiftreg_counter + 1;
                    end if;
                end if;

                if (q_shiftreg_counter = SHIFTREG_COUNTER_MAX) then
                    q_shiftreg_counter <= (others => '0');
                    q_shiftreg         <= (others => '0');

                    v_rx_parity := xor q_shiftreg(9 downto 1);

                    -- Check parity, start bit and stop bit
                    if (v_rx_parity /= '1' or q_shiftreg(q_shiftreg'high) /= '1'
                        or q_shiftreg(q_shiftreg'low) /= '0') then
                        o_rx_error <= '1';
                    else
                        o_rx_data <= q_shiftreg(8 downto 1);
                        o_rx_done <= '1';
                    end if;
                end if;
            elsif (state = S_INHIBIT) then
                -- Load shift register with data to be sent
                -- Start bit
                q_shiftreg(0) <= '0';
                -- TX data
                q_shiftreg(8 downto 1) <= i_tx_data;
                -- Parity bit
                q_shiftreg(9) <= not(xor i_tx_data);
                -- Stop bit
                q_shiftreg(10) <= '1';
            elsif (state = S_TX) then
                o_tx_error <= '1' when (watchdog_overflow = '1') else '0';

                if (ps2_clk_falling = '1') then
                    -- Loading the shiftreg with '1's ensures that the line will be naturally high-Z after transmit
                    q_shiftreg <= '1' & q_shiftreg(10 downto 1);

                    if (q_shiftreg_counter < SHIFTREG_COUNTER_MAX) then
                        q_shiftreg_counter <= q_shiftreg_counter + 1;
                    elsif (q_shiftreg_counter = SHIFTREG_COUNTER_MAX) then
                        o_tx_done          <= '1';
                        o_tx_error         <= '1' when io_ps2_data /= '0' else '0';
                        q_shiftreg_counter <= (others => '0');
                    end if;
                end if;
            end if;
        end if;

    end process proc_shiftreg;

-------------------------------------------------------------------------------------------------------------------

end architecture rtl;
