from pathlib import Path

from rename_wavedrom_svgs import cleanup_and_rename_svgs
from document_asserts import document_asserts_all


def rename_entity_documents(directory: Path) -> None:
    """Rename entity Markdown files to 'README.md' to make them show up in GitHub."""

    for entity_folder in directory.rglob("*"):
        if entity_folder.is_dir():
            entity_vhdl_file = entity_folder / f"{entity_folder.name}.vhd"
            entity_markdown_file = entity_folder / f"{entity_folder.name}.md"

            if entity_vhdl_file.exists() and entity_markdown_file.exists():
                entity_markdown_file.rename(entity_folder / "README.md")


if __name__ == "__main__":
    cleanup_and_rename_svgs(Path("source"))
    document_asserts_all(Path("source"))
    rename_entity_documents(Path("source"))
