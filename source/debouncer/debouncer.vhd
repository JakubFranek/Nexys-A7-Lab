--! Parametrized debouncer.
--!
--! The `i_input` signal can be asynchronous, as the debouncer includes a 2-stage flip-flop synchronizer.
--!
--! The `o_output` signal reacts to `i_input` after it is stable for `PERIOD` `i_clk_ena` cycles.
--! The initial value of `o_output` is '0'.
--!
--! There is a latency of 4 `i_clk` cycles (2 cycles for the flip-flop synchronizer,
--! 1 cycle for counter reset XOR, 1 cycle for the output register) and up to 1 `i_clk_ena`
--! cycle (depending on when `i_input` changes).

------------------------------------------------------------
--! { signal: [
--!  { name: "i_clk (period = c)", wave: "P..............." },
--!  { name: "i_clk_ena (period = e)", wave: "P.......", period:2 },
--!  { name: "i_input",  wave: "0101............", node: "...C...." },
--!  { name: "input_sync",  wave: "0..101..........", node: ".....E..." },
--!  { name: "q_input_sync_dly",  wave: "0...101.........", node: "......F.." },
--!  { name: ["tspan", {style: "fill:gray"}, "counter reset"], wave: "0..1..0........." },
--!  { name: "q_counter", wave: "=.==....=.=.=.=.", data: [0,1,0,1,2,0,1], node: "........A...B.."},
--!  { name: "o_output", wave: "0............1..", node: ".............H.." }
--! ],
--! edge: ["A~>B PERIOD*e", "C~>E 2c", "E~>F 1c", "F~>A <=1e", "B~>H 1c"],
--!  head:{
--!     text:'Simplified time diagram (for PERIOD = 2)',
--!     tick:0,
--!     every:1
--!   },
--! }
------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.log2;
    use ieee.math_real.ceil;

entity debouncer is
    generic (
        PERIOD     : natural := 10;  --! number of `i_clk_ena` cycles during which `i_input` must be stable
        SIMULATION : boolean := true --! generate simulation asserts
    );
    port (
        i_input   : in    std_logic;       --! input signal to be debounced
        i_clk     : in    std_logic;       --! input clock
        i_clk_ena : in    std_logic;       --! clock enable signal, used for incrementing internal counter
        o_output  : out   std_logic := '0' --! debounced output
    );
end entity debouncer;

architecture rtl of debouncer is

    --! counter width required to fit `PERIOD` + 1 (+1 because value 0 can last unpredictably long)
    constant COUNTER_WIDTH : natural := natural(ceil(log2(real(PERIOD + 1))));

    --! counter register
    signal q_counter : unsigned(COUNTER_WIDTH - 1 downto 0) := (others => '0');

    signal input_sync       : std_logic;        --! synchronized `i_input`
    signal q_input_sync_dly : std_logic := '0'; --! delayed `input_sync`

begin

    inst_synchronizer : entity work.flip_flop_synchronizer
        generic map (
            STAGES => 2
        )
        port map (
            i_clk   => i_clk,
            i_async => i_input,
            o_sync  => input_sync
        );

    proc_clk : process (i_clk) is
    begin

        if rising_edge(i_clk) then
            -- DFF used for detecting `i_input` changes
            q_input_sync_dly <= input_sync;

            if (input_sync /= q_input_sync_dly) then
                -- `i_input` has changed, reset counter
                q_counter <= (others => '0');
            else
                if (i_clk_ena = '1') then
                    if (q_counter = to_unsigned(PERIOD, COUNTER_WIDTH)) then
                        q_counter <= (others => '0');
                        o_output  <= input_sync;
                    else
                        q_counter <= q_counter + 1;
                    end if;
                end if;
            end if;
        end if;

    end process proc_clk;

    gen_simulation : if SIMULATION generate

        psl_block : block is

        -- psl default clock is rising_edge(i_clk);

        begin

            counter_max_min_value:
            assert (PERIOD > 1)
                report "`PERIOD` must be larger than 1"
                severity error;

        end block psl_block;

    end generate gen_simulation;

end architecture rtl;
