--! Parametrized VGA controller
--!
--! Generates horizontal and vertical sync signals, current row and column vectors, and a signal
--! that indicates whether the current pixel is in the active area.

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.vga_package.all;

entity vga_controller is
    generic (
        --! VGA configuration record
        VGA_CONFIG : t_vga_config := VGA_CONFIG_H600_V480;
        --! `i_reset` active level
        RESET_ACTIVE_LEVEL : std_logic := '1'
    );
    port (
        i_clk            : in    std_logic;                                      --! Input clock
        i_clk_ena        : in    std_logic;                                      --! Clock enable
        i_reset          : in    std_logic;                                      --! Synchronous reset
        o_hsync          : out   std_logic;                                      --! Horizontal sync signal
        o_vsync          : out   std_logic;                                      --! Vertical sync signal
        o_row            : out   unsigned(VGA_CONFIG.row_bit_width downto 0);    --! Current row
        o_column         : out   unsigned(VGA_CONFIG.column_bit_width downto 0); --! Current column
        o_display_active : out   std_logic                                       --! High when current pixel is visible
    );
end entity vga_controller;

architecture rtl of vga_controller is

    constant H_TOTAL : natural := VGA_CONFIG.h_res + VGA_CONFIG.h_front_porch +
                                  VGA_CONFIG.h_sync_width + VGA_CONFIG.h_back_porch;
    constant V_TOTAL : natural := VGA_CONFIG.v_res + VGA_CONFIG.v_front_porch +
                                  VGA_CONFIG.v_sync_width + VGA_CONFIG.v_back_porch;

    constant H_SYNC_START : natural := VGA_CONFIG.h_res + VGA_CONFIG.h_front_porch;
    constant H_SYNC_END   : natural := VGA_CONFIG.h_res + VGA_CONFIG.h_front_porch + VGA_CONFIG.h_sync_width;

    constant V_SYNC_START : natural := VGA_CONFIG.v_res + VGA_CONFIG.v_front_porch;
    constant V_SYNC_END   : natural := VGA_CONFIG.v_res + VGA_CONFIG.v_front_porch + VGA_CONFIG.v_sync_width;

    signal h_counter : unsigned(VGA_CONFIG.column_bit_width downto 0) := (others => '0');
    signal v_counter : unsigned(VGA_CONFIG.row_bit_width downto 0)    := (others => '0');

begin

    proc_counter : process (i_clk) is
    begin

        if rising_edge(i_clk) then
            if (i_reset = RESET_ACTIVE_LEVEL) then
                h_counter <= (others => '0');
                v_counter <= (others => '0');
            elsif (i_clk_ena = '1') then
                if (h_counter = H_TOTAL - 1) then
                    h_counter <= (others => '0');

                    if (v_counter = V_TOTAL - 1) then
                        v_counter <= (others => '0');
                    else
                        v_counter <= v_counter + 1;
                    end if;
                else
                    h_counter <= h_counter + 1;
                end if;
            end if;
        end if;

    end process proc_counter;

    o_row            <= v_counter;
    o_column         <= h_counter;
    o_display_active <= '1' when (h_counter < VGA_CONFIG.h_res) and (v_counter < VGA_CONFIG.v_res) else
                        '0';

    o_hsync <= VGA_CONFIG.hsync_pulse_polarity when (h_counter >= H_SYNC_START and h_counter < H_SYNC_END) else
               not VGA_CONFIG.hsync_pulse_polarity;

    o_vsync <= VGA_CONFIG.vsync_pulse_polarity when (v_counter >= V_SYNC_START and v_counter < V_SYNC_END) else
               not VGA_CONFIG.vsync_pulse_polarity;

end architecture rtl;
