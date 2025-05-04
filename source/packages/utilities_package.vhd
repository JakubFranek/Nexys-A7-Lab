library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

package utilities_package is

    function get_binary_width (
        number : natural
    ) return natural;

end package utilities_package;

package body utilities_package is

    -------------------------------------------------------------------------------------------------------------------
    --! Returns the number of bits required to represent number as binary

    function get_binary_width (
        number : natural
    ) return natural is
    begin

        if (number = 0) then
            return 1;
        else
            return integer(ceil(log2(real(number)))) + 1;
        end if;

    end function get_binary_width;

-------------------------------------------------------------------------------------------------------------------

end package body utilities_package;

