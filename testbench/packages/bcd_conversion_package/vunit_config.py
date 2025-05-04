def configure(testbench) -> None:
    """Argument `testbench` is of type `vunit.ui.testbench.TestBench`, but for some reason
    it cannot be imported."""

    for decimal in [0, 1, 9, 10, 99, 100, 999, 1000]:
        testbench.add_config(name=f"DECIMAL={decimal}", generics={"DECIMAL": decimal})
