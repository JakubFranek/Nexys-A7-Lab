def configure(testbench) -> None:
    """Argument `testbench` is of type `vunit.ui.testbench.TestBench`, but for some reason
    it cannot be imported."""

    for period in [2, 10, 100]:
        testbench.add_config(name=f"period={period}", generics={"PERIOD": period})
