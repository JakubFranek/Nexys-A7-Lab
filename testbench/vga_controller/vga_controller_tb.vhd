library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.vga_package.all;

library vunit_lib;
    context vunit_lib.vunit_context;

entity vga_controller_tb is
    generic (
        RUNNER_CFG : string
    );
end entity vga_controller_tb;

architecture tb of vga_controller_tb is

    signal   clk        : std_logic := '1';
    constant CLK_PERIOD : time      := 40 ns;

    signal hsync          : std_logic;
    signal vsync          : std_logic;
    signal display_active : std_logic;
    signal row            : unsigned(VGA_CONFIG_H600_V480.row_bit_width downto 0);
    signal column         : unsigned(VGA_CONFIG_H600_V480.column_bit_width downto 0);

    constant VGA_H_TOTAL : natural := VGA_CONFIG_H600_V480.h_res + VGA_CONFIG_H600_V480.h_front_porch +
                                      VGA_CONFIG_H600_V480.h_sync_width + VGA_CONFIG_H600_V480.h_back_porch;

    constant VGA_V_TOTAL : natural := VGA_CONFIG_H600_V480.v_res + VGA_CONFIG_H600_V480.v_front_porch +
                                      VGA_CONFIG_H600_V480.v_sync_width + VGA_CONFIG_H600_V480.v_back_porch;

begin

    inst_uut : entity work.vga_controller
        generic map (
            VGA_CONFIG         => VGA_CONFIG_H600_V480,
            RESET_ACTIVE_LEVEL => '1'
        )
        port map (
            i_clk            => clk,
            i_clk_ena        => '1',
            i_reset          => '0',
            o_hsync          => hsync,
            o_vsync          => vsync,
            o_row            => row,
            o_column         => column,
            o_display_active => display_active
        );

    clk <= not clk after (CLK_PERIOD / 2);

    proc_test_runner : process is

        variable v_timestamp : time := 0 ns;

    begin

        test_runner_setup(runner, RUNNER_CFG);

        check_equal(row, 0, "Check initial value of `o_row`");
        check_equal(column, 0, "Check initial value of `o_column`");
        check_equal(hsync, '1', "Check initial value of `o_hsync`");
        check_equal(vsync, '1', "Check initial value of `o_vsync`");
        check_equal(display_active, '1', "Check initial value of `o_display_active`");

        wait until falling_edge(display_active);

        check_equal(row, 0, "Check value of `o_row` at the end of first line");
        check_equal(column, VGA_CONFIG_H600_V480.h_res, "Check value of `o_column` at the end of first line");
        check_equal(hsync, '1', "Check value of `o_hsync` at the end of first line");
        check_equal(vsync, '1', "Check value of `o_vsync` at the end of first line");
        check_equal(display_active, '0', "Check value of `o_display_active` at the end of first line");

        check_equal(now - v_timestamp, CLK_PERIOD * VGA_CONFIG_H600_V480.h_res,
                    "Check horizontal active time");

        v_timestamp := now;

        wait until falling_edge(hsync);

        check_equal(row, 0, "Check value of `o_row` at the end of first line horizontal sync");
        check_equal(column, VGA_CONFIG_H600_V480.h_res + VGA_CONFIG_H600_V480.h_front_porch,
                    "Check value of `o_column` at the end of first line horizontal sync");
        check_equal(hsync, '0', "Check value of `o_hsync` at the end of first line horizontal sync");
        check_equal(vsync, '1', "Check value of `o_vsync` at the end of first line horizontal sync");
        check_equal(display_active, '0', "Check value of `o_display_active` at the end of first line horizontal sync");

        check_equal(now - v_timestamp, CLK_PERIOD * VGA_CONFIG_H600_V480.h_front_porch,
                    "Check horizontal front porch time");

        v_timestamp := now;

        wait until rising_edge(hsync);

        check_equal(row, 0, "Check value of `o_row` at the start of second line horizontal sync");
        check_equal(column, VGA_CONFIG_H600_V480.h_res + VGA_CONFIG_H600_V480.h_front_porch
                    + VGA_CONFIG_H600_V480.h_sync_width,
                    "Check value of `o_column` at the start of second line horizontal sync");
        check_equal(hsync, '1', "Check value of `o_hsync` at the start of second line horizontal sync");
        check_equal(vsync, '1', "Check value of `o_vsync` at the start of second line horizontal sync");
        check_equal(display_active, '0',
                    "Check value of `o_display_active` at the start of second line horizontal sync");

        check_equal(now - v_timestamp, CLK_PERIOD * VGA_CONFIG_H600_V480.h_sync_width,
                    "Check horizontal sync width time");

        v_timestamp := now;

        wait until rising_edge(display_active);

        check_equal(row, 1, "Check value of `o_row` at the start of second line");
        check_equal(column, 0, "Check value of `o_column` at the start of second line");
        check_equal(hsync, '1', "Check value of `o_hsync` at the start of second line");
        check_equal(vsync, '1', "Check value of `o_vsync` at the start of second line");
        check_equal(display_active, '1', "Check value of `o_display_active` at the start of second line");

        check_equal(now - v_timestamp, CLK_PERIOD * VGA_CONFIG_H600_V480.h_back_porch,
                    "Check horizontal back porch time");

        v_timestamp := now;

        wait until falling_edge(display_active) and row = VGA_CONFIG_H600_V480.v_res - 1;

        check_equal(row, VGA_CONFIG_H600_V480.v_res - 1, "Check value of `o_row` at the end of last line");
        check_equal(column, VGA_CONFIG_H600_V480.h_res, "Check value of `o_column` at the end of last line");
        check_equal(hsync, '1', "Check value of `o_hsync` at the end of last line");
        check_equal(vsync, '1', "Check value of `o_vsync` at the end of last line");
        check_equal(display_active, '0', "Check value of `o_display_active` at the end of last line");

        check_equal(now, CLK_PERIOD *
                    (VGA_H_TOTAL * (VGA_CONFIG_H600_V480.v_res - 1) + VGA_CONFIG_H600_V480.h_res),
                    "Check time until the end of last line active area");

        v_timestamp := now;

        wait until falling_edge(vsync);

        check_equal(row, VGA_CONFIG_H600_V480.v_res + VGA_CONFIG_H600_V480.v_front_porch,
                    "Check value of `o_row` at the end of last line vertical sync");
        check_equal(column, 0,
                    "Check value of `o_column` at the end of last line vertical sync");
        check_equal(hsync, '1', "Check value of `o_hsync` at the end of last line vertical sync");
        check_equal(vsync, '0', "Check value of `o_vsync` at the end of last line vertical sync");
        check_equal(display_active, '0', "Check value of `o_display_active` at the end of last line vertical sync");

        check_equal(now - v_timestamp, CLK_PERIOD * (VGA_H_TOTAL * VGA_CONFIG_H600_V480.v_front_porch
                    + VGA_H_TOTAL - VGA_CONFIG_H600_V480.h_res),
                    "Check vertical front porch time");

        v_timestamp := now;

        wait until rising_edge(vsync);

        check_equal(row, VGA_CONFIG_H600_V480.v_res + VGA_CONFIG_H600_V480.v_front_porch
                    + VGA_CONFIG_H600_V480.v_sync_width,
                    "Check value of `o_row` at the start of first line vertical sync");
        check_equal(column, 0, "Check value of `o_column` at the start of first line vertical sync");
        check_equal(hsync, '1', "Check value of `o_hsync` at the start of first line vertical sync");
        check_equal(vsync, '1', "Check value of `o_vsync` at the start of first line vertical sync");
        check_equal(display_active, '0', "Check value of `o_display_active` at the start of first line vertical sync");

        check_equal(now - v_timestamp, CLK_PERIOD * VGA_H_TOTAL * VGA_CONFIG_H600_V480.v_sync_width,
                    "Check vertical sync width time");

        v_timestamp := now;

        wait until rising_edge(display_active);

        check_equal(row, 0, "Check value of `o_row` at the start of first line");
        check_equal(column, 0, "Check value of `o_column` at the start of first line");
        check_equal(hsync, '1', "Check value of `o_hsync` at the start of first line");
        check_equal(vsync, '1', "Check value of `o_vsync` at the start of first line");
        check_equal(display_active, '1', "Check value of `o_display_active` at the start of first line");

        check_equal(now - v_timestamp, CLK_PERIOD * VGA_H_TOTAL * VGA_CONFIG_H600_V480.v_back_porch,
                    "Check vertical back porch time");

        check_equal(now, CLK_PERIOD * VGA_H_TOTAL * VGA_V_TOTAL,
                    "Check time until the end of last line");

        wait for 17 ms - now;

        test_runner_cleanup(runner); -- Simulation ends here

    end process proc_test_runner;

end architecture tb;
