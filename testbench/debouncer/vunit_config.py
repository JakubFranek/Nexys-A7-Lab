from itertools import product


def configure(testbench) -> None:
    """Argument `testbench` is of type `vunit.ui.testbench.TestBench`, but for some reason
    it cannot be imported."""

    for period_clk_ena, period_debounce in product([10], [5]):
        testbench.add_config(
            name=f"period_clk_ena={period_clk_ena}.period_debounce={period_debounce}",
            generics={
                "PERIOD_CLK_ENA": period_clk_ena,
                "PERIOD_DEBOUNCE": period_debounce,
            },
        )
