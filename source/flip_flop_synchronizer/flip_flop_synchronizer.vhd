--! Parametrized flip-flop synchronizer.
--!
--! The initial value of output `o_sync` is '0'.

------------------------------------------------------------
--! { signal: [
--!  { name: "i_clk",  wave: "P....", period:2 },
--!  { name: "i_async",  wave: "01...0...." },
--!  { name: "o_sync", wave: "0...1...0." }
--! ],
--!  head:{
--!     text:'Time diagram (for STAGES = 2)',
--!     tick:0,
--!     every:1
--!   },
--! }
------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;

entity flip_flop_synchronizer is
    generic (
        STAGES     : natural := 2;   --! number of chained flip-flops
        SIMULATION : boolean := true --! generate logic needed for assert evaluation
    );
    port (
        i_clk   : in    std_logic; --! input clock
        i_async : in    std_logic; --! asynchronous input
        o_sync  : out   std_logic  --! synchronous output
    );
end entity flip_flop_synchronizer;

architecture rtl of flip_flop_synchronizer is

    --! internal shift register
    signal q_reg : std_logic_vector(STAGES - 1 downto 0) := (others => '0');

begin

    o_sync <= q_reg(q_reg'high);

    proc_sync : process (i_clk) is
    begin

        if rising_edge(i_clk) then
            q_reg <= q_reg(q_reg'high -1 downto q_reg'low) & i_async;
        end if;

    end process proc_sync;

    stages_min_value:
    assert (STAGES > 1)
        report "`STAGES` must be larger than 1"
        severity error;

end architecture rtl;
