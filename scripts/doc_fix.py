from pathlib import Path

from helpers.rename_wavedrom_svgs import cleanup_and_rename_svgs
from helpers.document_asserts import document_all_asserts
from helpers.document_assumptions import document_all_assumptions
from helpers.document_covers import document_all_covers


def rename_entity_documents(directory: Path) -> None:
    """Rename entity Markdown files to 'README.md' to make them show up in GitHub."""

    for entity_folder in directory.rglob("*"):
        if entity_folder.is_dir():
            entity_vhdl_file = entity_folder / f"{entity_folder.name}.vhd"
            entity_markdown_file = entity_folder / f"{entity_folder.name}.md"

            if entity_vhdl_file.exists() and entity_markdown_file.exists():
                if (entity_folder / "README.md").exists():
                    (entity_folder / "README.md").unlink()
                entity_markdown_file.rename(entity_folder / "README.md")
                print(
                    f"Doc renamed: {entity_markdown_file} -> {entity_folder / 'README.md'}"
                )


if __name__ == "__main__":
    rename_entity_documents(Path("source"))
    cleanup_and_rename_svgs(Path("source"))
    document_all_covers(Path("source"))
    document_all_assumptions(Path("source"))
    document_all_asserts(Path("source"))
