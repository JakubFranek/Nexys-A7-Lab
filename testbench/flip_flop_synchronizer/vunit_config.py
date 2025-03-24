def configure(testbench) -> None:
    """Argument `testbench` is of type `vunit.ui.testbench.TestBench`, but for some reason
    it cannot be imported."""

    for stages in [2, 3]:
        testbench.add_config(name=f"stages={stages}", generics={"STAGES": stages})
