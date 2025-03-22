--! Parametrized clock enable pulse generator.
--!
--! The initial value of output `o_clk_ena` is '1'.

------------------------------------------------------------
--! { signal: [
--!  { name: "i_clk",  wave: "P........." },
--!  { name: "q_counter",  wave: "==========", data: [0,1,2,3,0,1,2,3,0,1] },
--!  { name: "o_clk_ena", wave: "10..10..10" }
--! ],
--!  head:{
--!     text:'Time diagram (for PERIOD = 4)',
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

entity clock_enable_generator is
    generic (
        PERIOD     : natural := 10;  --! number of clock cycles required to generate a single clock enable pulse
        SIMULATION : boolean := true --! generate logic needed for assert evaluation
    );
    port (
        i_clk     : in    std_logic;       --! input clock
        o_clk_ena : out   std_logic := '1' --! clock enable signal, active high for one input clock cycle
    );
end entity clock_enable_generator;

architecture rtl of clock_enable_generator is

    --! counter width required to fit `PERIOD`
    constant COUNTER_WIDTH : natural := natural(ceil(log2(real(PERIOD))));

    --! counter register
    signal q_counter : unsigned(COUNTER_WIDTH - 1 downto 0) := (others => '0');

begin

    proc_clk_ena : process (i_clk) is
    begin

        if rising_edge(i_clk) then
            if (q_counter = to_unsigned(PERIOD - 1, COUNTER_WIDTH)) then
                q_counter <= (others => '0');
                o_clk_ena <= '1';
            else
                q_counter <= q_counter + 1;
                o_clk_ena <= '0';
            end if;
        end if;

    end process proc_clk_ena;

    gen_formal : if SIMULATION generate

        psl_block : block is

        -- psl default clock is rising_edge(i_clk);

        begin

            counter_max_min_value:
            assert (PERIOD > 1)
                report "`PERIOD` must be larger than 1"
                severity error;

            -- psl o_clk_ena_period :
            -- assert (always {q_counter = PERIOD - 1} |=> {o_clk_ena = '1'})
            -- report "`o_clk_ena` not activated in the next clock cycle after `q_counter` reaches `PERIOD` - 1"
            -- severity error;

            -- psl q_counter_reset :
            -- assert (always {q_counter = PERIOD - 1} |=> {q_counter = 0})
            -- report "`q_counter` not reset in the next clock cycle after reaching `PERIOD` - 1"
            -- severity error;

            -- psl o_clk_ena_one_cycle :
            -- assert (always {o_clk_ena = '1'} |=> {o_clk_ena = '0'})
            -- report "`o_clk_ena` pulse is longer than one clock cycle"
            -- severity error;

            q_counter_helper_block : block is

                signal q_counter_prev : unsigned(q_counter'range) := (others => '0');

            begin

                proc_q_counter_prev : process (i_clk) is
                begin

                    if rising_edge(i_clk) then
                        q_counter_prev <= q_counter;
                    end if;

                end process proc_q_counter_prev;

            -- psl q_counter_increment :
            -- assert (always (q_counter < PERIOD - 1) |=> (q_counter = q_counter_prev + 1))
            -- report "`q_counter` not incremented in the next clock cycle after `q_counter` < `PERIOD` - 1"
            -- severity error;

            end block q_counter_helper_block;

        end block psl_block;

    end generate gen_formal;

end architecture rtl;
