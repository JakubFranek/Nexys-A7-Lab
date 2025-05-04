--! Parametrized unsigned to BCD converter, utilizing double-dabble algorithm.
--!
--! The number of clocks required from `i_convert` = '1' to `o_done` = '1' is `BINARY_WIDTH - 1`, where
--! `BINARY_WIDTH` is the width of binary input. One cycle is used to load binary data into shift registers
--! and `BINARY_WIDTH - 2` cycles are used to convert the data.
--!
--! Note that `o_bcd` data changes during conversion and the data are valid only when `o_done` is high. If invalid data
--! are not permissible, the output data should be registered and updated only when `o_done` is high.
--!
--! Note that the input data is registered in shift registers in `S_LOAD_SHIFTREG` state, which occurs one clock after
--! `i_convert` goes high. This means that the converter number is not necessarily same as the number in `i_binary`
--! when `i_convert` goes high, but rather that is present on `i_binary` in the next clock after `i_convert` goes high.

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;
    use work.bcd_conversion_package.all;
    use work.bcd_array_package.all;
    use work.utilities_package.all;

entity double_dabble is
    generic (
        RESET_ACTIVE_LEVEL : std_logic                       := '1'; --! Active level of `i_reset`
        BINARY_WIDTH       : natural range 4 to natural'high := 6;   --! Width of binary input
        BCD_DIGITS         : natural range 2 to natural'high := 2    --! Number of output BCD digits
    );
    port (
        i_clk     : in    std_logic;                           --! System clock
        i_reset   : in    std_logic;                           --! Synchronous reset
        i_convert : in    std_logic;                           --! Start conversion when high
        i_binary  : in    unsigned(BINARY_WIDTH - 1 downto 0); --! Binary data to convert
        o_done    : out   std_logic;                           --! Indicates completed conversion
        --! Output data, valid only when `o_done` is high, static until new conversion starts
        o_bcd : out   t_bcd_array(BCD_DIGITS - 1 downto 0)
    );
end entity double_dabble;

architecture rtl of double_dabble is

    --! Number of conversion cycles
    constant MAX_COUNT : natural := maximum(i_binary'length - 3 - 1, 0);
    --! Size of conversion cycle counter
    constant COUNTER_SIZE : natural := get_binary_width(MAX_COUNT);
    --! Initial value of counter
    constant INITIAL_COUNT : unsigned(COUNTER_SIZE - 1 downto 0) := to_unsigned(MAX_COUNT, COUNTER_SIZE);

    type fsm_state is (
        S_IDLE,          --! Idle, waiting for `i_convert` active pulse
        S_LOAD_SHIFTREG, --! Load shift registers with input data
        S_CONVERTING,    --! Conversion under way
        S_DONE           --! Conversion done, output data are valid
    );

    signal current_state : fsm_state := S_IDLE; --! FSM current state signal

    --! Binary shift register
    signal binary_shiftreg : unsigned(i_binary'length - 3 - 1 downto 0) := (others => '0');
    --! BCD shift register
    signal bcd_shiftreg : unsigned(BCD_DIGITS * 4 - 1 downto 0) := (others => '0');
    --! Conversion cycle counter
    signal bit_count : unsigned(COUNTER_SIZE - 1 downto 0) := (others => '0');
    --! Shift register load signal
    signal load_shiftregs : std_logic;
    --! Run algorithm signal
    signal run_algorithm : std_logic;

begin

    proc_double_dabble : process (i_clk) is

        variable v_next_bcd : unsigned(bcd_shiftreg'range); --! Next value of `bcd_shiftreg`

    begin

        if rising_edge(i_clk) then
            if (i_reset = RESET_ACTIVE_LEVEL) then
                bcd_shiftreg    <= (others => '0');
                binary_shiftreg <= (others => '0');
            elsif (load_shiftregs = '1') then
                -- Initialize the shift registers with the first three binary bits.
                -- Maximum value of 2 bits is 3 and dabble occurs only when value is 5 or greater,
                -- so no "dabble" will be performed before at least 3 bits area loaded. This means that
                -- the first three shifts can be performed in this initialization.
                bcd_shiftreg(bcd_shiftreg'high downto 3) <= (others => '0');
                bcd_shiftreg(2 downto 0)                 <= (i_binary(i_binary'high downto i_binary'high-2));
                binary_shiftreg                          <= i_binary(i_binary'high-3 downto 0);
            elsif (run_algorithm = '1') then

                for d in 0 to BCD_DIGITS - 1 loop

                    -- "Dabble" step: If a digit is greater than or equal to 5, add 3.
                    -- If the number is 0 to 4, it will be 0 to 8 after left shift (below), which fits into one digit.
                    -- If the number is 5 to 9, it will be 10 to 18 after left shift, which does not fit into one digit.
                    -- By adding 3 to the number, it will be minimum 8, which after doubling is 16, which means it
                    -- shifts into the next digit as desired.

                    if (bcd_shiftreg(d * 4 + 3 downto d * 4) >= 5) then
                        v_next_bcd(d * 4 + 3 downto d * 4) := bcd_shiftreg(d * 4 + 3 downto d * 4) + 3;
                    else
                        v_next_bcd(d * 4 + 3 downto d * 4) := bcd_shiftreg(d * 4 + 3 downto d * 4);
                    end if;

                end loop;

                -- "Double" step: Shift left and load next bit
                bcd_shiftreg    <= v_next_bcd(bcd_shiftreg'left-1 downto 0) & binary_shiftreg(binary_shiftreg'left);
                binary_shiftreg <= binary_shiftreg(binary_shiftreg'left-1 downto 0) & '0';
            end if;
        end if;

    end process proc_double_dabble;

    proc_fsm : process (i_clk) is

        variable v_next_state : fsm_state; --! Next value of `current_state`

    begin

        if rising_edge(i_clk) then
            if (i_reset = RESET_ACTIVE_LEVEL) then
                current_state <= S_IDLE;
            else
                v_next_state := current_state; --! Default next state assignment

                case current_state is

                    when S_IDLE =>

                        if (i_convert = '1') then
                            v_next_state := S_LOAD_SHIFTREG;
                        end if;

                    when S_LOAD_SHIFTREG =>

                        v_next_state := S_CONVERTING;

                    when S_CONVERTING =>

                        if (bit_count = (bit_count'range => '0')) then
                            v_next_state := S_DONE;
                        end if;

                    when S_DONE =>

                        if (i_convert = '1') then
                            v_next_state := S_LOAD_SHIFTREG;
                        end if;

                    when others =>

                        v_next_state := S_IDLE;

                end case;

                current_state <= v_next_state;
            end if;
        end if;

    end process proc_fsm;

    proc_bit_counter : process (i_clk) is
    begin

        if rising_edge(i_clk) then
            if (i_reset = RESET_ACTIVE_LEVEL or run_algorithm = '0') then
                bit_count <= INITIAL_COUNT;
            else
                bit_count <= bit_count - 1;
            end if;
        end if;

    end process proc_bit_counter;

    load_shiftregs <= '1' when current_state = S_LOAD_SHIFTREG else
                      '0';
    run_algorithm  <= '1' when current_state = S_CONVERTING else
                      '0';
    o_done         <= '1' when current_state = S_DONE else
                      '0';

    gen_bcd_array : for d in BCD_DIGITS - 1 downto 0 generate

        o_bcd(d) <= bcd_shiftreg(d * 4 + 3 downto d * 4);

    end generate gen_bcd_array;

end architecture rtl;

