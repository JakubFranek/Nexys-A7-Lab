library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package bcd_array_package is

    type t_bcd_array is array (natural range <>) of unsigned(3 downto 0);

end package bcd_array_package;
