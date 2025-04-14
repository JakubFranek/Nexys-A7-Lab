--! Parametrized seven segment display controller.
--!
--! On Nexys A7 board, both cathodes (segments) and anodes (common)
--! are active low.
------------------------------------------------------------
--! { signal: [
--!  { name: "i_clk",               wave: "P..........." },
--!  { name: "i_clk_ena",           wave: "010101010101" },
--!  { name: ["tspan", {style: "fill:gray"}, "q_counter"],
--!                                 wave: "=.=.=.=.=.=.", data: [0,1,2,3,0,1] },
--!  { name: "o_segments(7:0)",     wave: "=.=.=.=.=.=.", data: ["D0", "D1", "D2", "D3", "D0", "D1"] },
--!  { name: "o_digit_enable(0)",   wave: "0.1.....0.1."},
--!  { name: "o_digit_enable(1)",   wave: "1.0.1.....0."},
--!  { name: "o_digit_enable(2)",   wave: "1...0.1....."},
--!  { name: "o_digit_enable(3)",   wave: "1.....0.1..."}
--! ],
--!  head:{
--!     text:'Time diagram (for DIGITS = 4, DIGIT_ACTIVE_LEVEL = 0)',
--!     tick:0,
--!     every:1
--!   },
--! }
------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.digit_record_package.all;
    use ieee.math_real.log2;
    use ieee.math_real.ceil;

entity seven_segment_controller is
    generic (
        DIGITS               : natural   := 2;   --! number of digits
        SEGMENT_ACTIVE_LEVEL : std_logic := '0'; --! active level of segments
        DIGIT_ACTIVE_LEVEL   : std_logic := '0'  --! active level of anodes
    );
    port (
        --! input clock
        i_clk : in    std_logic;
        --! clock enable signal, each digit is active for 1 `i_clk_ena` cycle
        i_clk_ena : in    std_logic;
        --! array of digit records
        i_digits : in    t_digit_array(DIGITS - 1 downto 0);
        --! output segments (7: CA, ..., 1: CG, 0: DP)
        o_segments : out   std_logic_vector(7 downto 0);
        --! output digit common anodes
        o_digit_enable : out   std_logic_vector(DIGITS - 1 downto 0)
    );
end entity seven_segment_controller;

architecture rtl of seven_segment_controller is

    type t_segment_array is array (natural range <>) of std_logic_vector(6 downto 0);

    --! array of predefined segment patterns, assumes active level is '1', DP not included
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

    --! internal counter
    signal q_counter : integer := 0;
    --! intermediary signal for controlling individual segments
    signal segments : std_logic_vector(7 downto 0);

begin

    proc_clk : process (i_clk) is
    begin

        if rising_edge(i_clk) then
            if (i_clk_ena = '1') then
                if (q_counter = (DIGITS - 1)) then
                    q_counter <= 0;
                else
                    q_counter <= q_counter + 1;
                end if;
            end if;
        end if;

    end process proc_clk;

    gen_block : for i in 0 to (DIGITS - 1) generate
        o_digit_enable(i) <= DIGIT_ACTIVE_LEVEL when (i = q_counter) else
                             not DIGIT_ACTIVE_LEVEL;
    end generate gen_block;

    segments(7 downto 1) <= SEGMENTS_ARRAY(to_integer(i_digits(q_counter).value))
                            when i_digits(q_counter).enable = '1' else
                            (others => '0');

    segments(0) <= i_digits(q_counter).decimal_point when i_digits(q_counter).enable = '1' else
                   '0';

    o_segments <= segments when SEGMENT_ACTIVE_LEVEL = '1' else
                  not segments;

end architecture rtl;
