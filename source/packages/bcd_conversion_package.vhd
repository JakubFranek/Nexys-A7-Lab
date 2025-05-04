library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;
    use work.bcd_array_package.all;

package bcd_conversion_package is

    function get_decimal_size (
        number : natural
    ) return natural;

    function unsigned_to_bcd (
        binary : unsigned
    ) return t_bcd_array;

    function bcd_to_natural (
        bcd : t_bcd_array
    ) return natural;

end package bcd_conversion_package;

package body bcd_conversion_package is

    -------------------------------------------------------------------------------------------------------------------
    --! Returns the number of digits required for decimal representation of number

    function get_decimal_size (
        number : natural
    ) return natural is
    begin

        if (number = 0) then
            return 1;
        else
            return natural(floor(log10(real(abs(number))))) + 1;
        end if;

    end function get_decimal_size;

    -------------------------------------------------------------------------------------------------------------------
    --! Converts unsigned number to BCD array using a double dabble algorithm

    function unsigned_to_bcd (
        binary : unsigned
    ) return t_bcd_array is

        constant DIGITS         : natural                           := get_decimal_size(to_integer(binary));
        variable v_unsigned_bcd : unsigned(DIGITS * 4 - 1 downto 0) := (others => '0');
        variable v_bcd_array    : t_bcd_array(DIGITS - 1 downto 0)  := (others => "0000");

    begin

        for bit_index in binary'range loop

            for d in 0 to DIGITS - 1 loop

                -- "Dabble" step: If a digit is greater than or equal to 5, add 3.
                -- If the number is 0 to 4, it will be 0 to 8 after left shift (below), which fits into one digit.
                -- If the number is 5 to 9, it will be 10 to 18 after left shift, which does not fit into one digit.
                -- By adding 3 to the number, it will be minimum 8, which after doubling is 16, which means the number
                -- shifts into the next digit as desired.
                if (v_unsigned_bcd(d * 4 + 3 downto d * 4) >= 5) then
                    v_unsigned_bcd(d * 4 + 3 downto d * 4) := v_unsigned_bcd(d * 4 + 3 downto d * 4) + 3;
                end if;

            end loop;

            -- "Double" step:Shift left and load next bit
            v_unsigned_bcd := v_unsigned_bcd(v_unsigned_bcd'left-1 downto 0) & binary(bit_index);

        end loop;

        for d in 0 to DIGITS - 1 loop

            v_bcd_array(d) := v_unsigned_bcd(d * 4 + 3 downto d * 4);

        end loop;

        return v_bcd_array;

    end function unsigned_to_bcd;

    -------------------------------------------------------------------------------------------------------------------

    function bcd_to_natural (
        bcd : t_bcd_array
    ) return natural is

        constant DIGITS    : natural := bcd'length;
        variable v_natural : natural := 0;

    begin

        for d in DIGITS - 1 downto 0 loop

            v_natural := v_natural + (10 ** d) * to_integer(bcd(d));

        end loop;

        return v_natural;

    end function bcd_to_natural;

-------------------------------------------------------------------------------------------------------------------

end package body bcd_conversion_package;

