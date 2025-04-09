library ieee;
    use ieee.std_logic_1164.all;

package digit_record_package is

    type t_digit is record
        value         : std_logic_vector(3 downto 0);
        decimal_point : std_logic;
        enable        : std_logic;
    end record t_digit;

    type t_digit_array is array (natural range <>) of t_digit;

end package digit_record_package;
