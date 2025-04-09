library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.digit_record_package.all;
    use ieee.math_real.log2;
    use ieee.math_real.ceil;

entity seven_segment_controller is
    generic (
        DIGITS               : natural := 8;     --! number of digits
        SEGMENTS_ACTIVE_HIGH : boolean := false; --! active level of segments
        ANODES_ACTIVE_HIGH   : boolean := false; --! active level of anodes
        SIMULATION           : boolean := true   --! generate simulation asserts
    );
    port (
        --! input clock
        i_clk : in    std_logic;
        --! clock enable signal
        i_clk_ena : in    std_logic;
        --! array of digit records
        i_digits : in    t_digit_array(DIGITS - 1 downto 0);
        --! output segments (CA to CG + DP)
        o_segments : out   std_logic_vector(7 downto 0);
        --! output digit common anodes
        o_digit_enable : out   std_logic_vector(DIGITS - 1 downto 0)
    );
end entity seven_segment_controller;

architecture rtl of seven_segment_controller is

    type t_segment_array is array (natural range <>) of std_logic_vector(6 downto 0);

    constant SEGMENTS_ARRAY : t_segment_array(0 to 15) :=
    (
        "1111110", -- 0
        "0110000", -- 1
        "1101101", -- 2
        "1111001", -- 3
        "0110011", -- 4
        "1011011", -- 5
        "1011111", -- 6
        "1110000", -- 7
        "1111111", -- 8
        "1111011", -- 9
        "1110111", -- A
        "0011111", -- B
        "1001110", -- C
        "0111101", -- D
        "1001111", -- E
        "1000111"  -- F
    );

    constant COUNTER_WIDTH : natural                              := natural(ceil(log2(real(DIGITS))));
    signal   q_counter     : unsigned(COUNTER_WIDTH - 1 downto 0) := (others => '0');
    signal   segments      : std_logic_vector(7 downto 0);

begin

    proc_clk : process (i_clk) is
    begin

        if rising_edge(i_clk) then
            if (i_clk_ena = '1') then
                if (q_counter = to_unsigned(DIGITS - 1, COUNTER_WIDTH)) then
                    q_counter <= (others => '0');
                else
                    q_counter <= q_counter + 1;
                end if;
            end if;
        end if;

    end process proc_clk;

    gen_block : for i in 0 to DIGITS - 1 generate
        o_digit_enable(i) <= '1' when (i = to_integer(q_counter) and ANODES_ACTIVE_HIGH) or
                                      (i /= to_integer(q_counter) and not ANODES_ACTIVE_HIGH) else
                             '0';
    end generate gen_block;

    segments(7 downto 1) <= SEGMENTS_ARRAY(to_integer(q_counter));

    segments(0) <= '1' when i_digits(to_integer(q_counter)).decimal_point = '1' else
                   '0';

    o_segments <= segments when SEGMENTS_ACTIVE_HIGH = true else
                  not segments;

end architecture rtl;

