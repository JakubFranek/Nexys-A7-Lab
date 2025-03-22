from pathlib import Path

from rename_wavedrom_svgs import cleanup_and_rename_svgs
from document_asserts import document_asserts_all

if __name__ == "__main__":
    cleanup_and_rename_svgs(Path("source"))
    document_asserts_all(Path("source"))
