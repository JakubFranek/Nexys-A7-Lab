library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.utilities_package.all;

entity ps2_transceiver is
    generic (
        CLOCK_FREQUENCY : natural := 100_000_000
    );
    port (
        --! System clock
        i_clk : in    std_logic;
        --! Synchronous reset signal
        i_reset : in    std_logic;
        --! PS/2 clock signal
        io_ps2_clk : inout std_logic;
        --! PS/2 data signal
        io_ps2_data : inout std_logic;
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

    signal clk_ena_1us : std_logic;

    signal ps2_clk_clean  : std_logic;
    signal ps2_data_clean : std_logic;

    signal ps2_clk_falling : std_logic;
    signal ps2_clk_rising  : std_logic;

    -- Shift register: Start bit (MSB), 8 data bits, stop bit, odd parity bit (LSB)
    signal shiftreg         : std_logic_vector(10 downto 0) := (others => '0');
    signal shiftreg_counter : unsigned(3 downto 0)          := (others => '0');
    signal rx_parity        : std_logic;

    type t_fsm_state is (
        S_RX,
        S_INHIBIT,
        S_TX,
        S_TX_DONE
    );

    signal current_state : t_fsm_state := S_RX;

    constant INHIBIT_COUNTER_MAX   : natural := 100;
    constant INHIBIT_COUNTER_WIDTH : natural := get_binary_width(INHIBIT_COUNTER_MAX);

    signal inhibit_counter       : unsigned(INHIBIT_COUNTER_WIDTH - 1 downto 0) := (others => '0');
    signal inhibit_counter_reset : std_logic;

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
            i_input   => io_ps2_clk,
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
            i_input   => io_ps2_data,
            i_clk     => i_clk,
            i_clk_ena => clk_ena_1us,
            o_output  => ps2_data_clean
        );

    inst_ps2_clock_edge_detector : entity work.edge_detector
        port map (
            i_clk          => i_clk,
            i_input        => ps2_clk_clean,
            o_rising_edge  => ps2_clk_rising,
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
            i_enable    => '1',
            i_direction => '1',
            i_reset     => inhibit_counter_reset,
            o_count     => inhibit_counter
        );

    -------------------------------------------------------------------------------------------------------------------

    proc_fsm : process (i_clk) is

        variable v_next_state : t_fsm_state; --! Next value of `current_state`

    begin

        if rising_edge(i_clk) then
            if (i_reset = '1') then
                current_state <= S_RX;
            else
                -- Default assignments
                v_next_state          := current_state;
                inhibit_counter_reset <= '1';
                io_ps2_clk            <= 'Z';
                o_tx_busy             <= '0';

                case current_state is

                    when S_RX =>

                        if (i_tx_start = '1') then
                            v_next_state := S_INHIBIT;
                        end if;

                    when S_INHIBIT =>

                        inhibit_counter_reset <= '0';
                        io_ps2_clk            <= '0';
                        o_tx_busy             <= '1';

                        if (inhibit_counter = INHIBIT_COUNTER_MAX) then
                            v_next_state := S_TX;
                        end if;

                    when S_TX =>

                        o_tx_busy <= '1';

                        if (o_tx_done = '1') then
                            v_next_state := S_TX_DONE;
                        end if;

                    when S_TX_DONE =>

                        o_tx_busy <= '1';

                        if (ps2_clk_clean = '1' and ps2_data_clean = '1') then
                            v_next_state := S_RX;
                        end if;

                    when others =>

                end case;

            end if;
        end if;

    end process proc_fsm;

    proc_shiftreg : process (i_clk) is
    begin

        if rising_edge(i_clk) then
            -- Default assignments
            io_ps2_data <= 'Z';

            if (i_reset = '1' or (current_state /= S_RX and current_state /= S_TX)) then
                shiftreg         <= (others => '0');
                shiftreg_counter <= (others => '0');
                o_rx_data        <= (others => '0');
                o_rx_done        <= '0';
            elsif (current_state = S_RX) then
                if (ps2_clk_falling = '1') then
                    shiftreg <= shiftreg(9 downto 0) & ps2_data_clean;

                    if (shiftreg_counter < 11) then
                        shiftreg_counter <= shiftreg_counter + 1;
                    end if;
                end if;

                -- Default assignment
                o_rx_done <= '0';

                if (shiftreg_counter = 11) then
                    shiftreg_counter <= (others => '0');

                    if (o_rx_error = '0') then
                        o_rx_data <= shiftreg(9 downto 2);
                        o_rx_done <= '1';
                    end if;
                end if;
            elsif (current_state = S_TX) then
                if (shiftreg_counter = 0) then
                    -- Start bit
                    shiftreg(10) <= '0';
                    -- Data
                    shiftreg(9 downto 2) <= i_tx_data;
                    -- Parity bit
                    shiftreg(1) <= xor shiftreg(9 downto 1);
                -- Stop bit is not included in shift register (transmitted by releasing the data line to high)
                end if;

                if (ps2_clk_falling = '1') then
                    shiftreg <= shiftreg(9 downto 0) & '0';

                    if (shiftreg_counter < 10) then
                        shiftreg_counter <= shiftreg_counter + 1;

                        io_ps2_data <= shiftreg(10);
                        if (shiftreg_counter = 9) then
                            io_ps2_data <= 'Z';
                        end if;
                    end if;
                elsif (ps2_clk_rising = '1') then
                    if (shiftreg_counter = 10) then
                        o_tx_done        <= '1';
                        shiftreg_counter <= (others => '0');
                        o_tx_error       <= '1' when io_ps2_data /= '0' else '0';
                    end if;
                end if;
            end if;
        end if;

    end process proc_shiftreg;

    rx_parity  <= xor shiftreg(9 downto 1);
    o_rx_busy  <= '1' when (current_state = S_RX and shiftreg_counter /= 0 and shiftreg_counter /= 11) else
                  '0';
    o_rx_error <= '1' when (current_state = S_RX and shiftreg_counter = 11 and
                               (rx_parity /= '1' or shiftreg(10) /= '0' or shiftreg(0) /= '1')) else
                  '0';

-------------------------------------------------------------------------------------------------------------------

end architecture rtl;
