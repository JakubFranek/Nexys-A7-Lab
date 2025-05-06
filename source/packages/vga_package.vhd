library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.utilities_package.all;

package vga_package is

    type t_vga_config is record
        --! horizontal resolution
        h_res : natural;
        --! vertical resolution
        v_res : natural;
        --! horizontal front porch
        h_front_porch : natural;
        --! vertical front porch
        v_front_porch : natural;
        --! horizontal back porch
        h_back_porch : natural;
        --! vertical back porch
        v_back_porch : natural;
        --! horizontal sync width
        h_sync_width : natural;
        --! vertical sync width
        v_sync_width : natural;
        --! number of bits required to represent column
        column_bit_width : natural;
        --! number of bits required to represent row
        row_bit_width : natural;
        --! polarity of horizontal sync pulse
        hsync_pulse_polarity : std_logic;
        --! polarity of vertical sync pulse
        vsync_pulse_polarity : std_logic;
    end record t_vga_config;

    constant VGA_CONFIG_H600_V480 : t_vga_config :=
    (
        h_res                => 640,
        v_res                => 480,
        h_front_porch        => 16,
        v_front_porch        => 10,
        h_back_porch         => 48,
        v_back_porch         => 33,
        h_sync_width         => 96,
        v_sync_width         => 2,
        row_bit_width        => get_binary_width(480),
        column_bit_width     => get_binary_width(640),
        hsync_pulse_polarity => '0',
        vsync_pulse_polarity => '0'
    );

end package vga_package;
