def configure(testbench) -> None:
    """Argument `testbench` is of type `vunit.ui.testbench.TestBench`, but for some reason
    it cannot be imported."""

    for binary in [
        0,
        1,
        9,
        10,
        99,
        999_999,
        1_000_000,
    ]:
        testbench.add_config(name=f"BINARY={binary}", generics={"BINARY": binary})
