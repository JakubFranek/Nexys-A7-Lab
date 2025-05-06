library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

package math_functions_package is

    function floor_log (
        number,
        base : positive
    ) return natural;

    function ceil_log (
        number,
        base : positive
    ) return natural;

end package math_functions_package;

package body math_functions_package is

    -------------------------------------------------------------------------------------------------------------------

    function floor_log (
        number,
        base : positive
    ) return natural is

        variable v_log, v_residual : natural;

    begin

        v_residual := number;
        v_log      := 0;

        -- The -1 ensures that the amount of loop iterations equals the log value even when `number` is a power of base
        while v_residual > (base - 1) loop

            v_residual := v_residual / base; -- Floor division
            v_log      := v_log + 1;

        end loop;

        return v_log;

    end function floor_log;

    -------------------------------------------------------------------------------------------------------------------

    function ceil_log (
        number,
        base : positive
    ) return natural is

        variable v_log, v_residual : natural;

    begin

        -- The -1 ensures that the amount of loop iterations equals the log value even when `number` is a power of base
        v_residual := number - 1;
        v_log      := 0;

        while v_residual > 0 loop

            v_residual := v_residual / base; -- Floor division
            v_log      := v_log + 1;

        end loop;

        return v_log;

    end function ceil_log;

-------------------------------------------------------------------------------------------------------------------

end package body math_functions_package;

