library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package digit_record_package is

    type t_digit is record
        value         : unsigned(3 downto 0);
        decimal_point : std_logic;
        enable        : std_logic;
    end record t_digit;

    type t_digit_array is array (natural range <>) of t_digit;

end package digit_record_package;
