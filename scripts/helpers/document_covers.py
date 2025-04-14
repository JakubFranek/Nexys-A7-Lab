import re
from pathlib import Path

from helpers.parse_vhdl import uncomment_psl


def extract_covers_from_vhdl(vhdl_code: str) -> list[list[str]]:
    assume_pattern = re.compile(
        r"(?P<label>\w+)?\s*:\s*cover\s*\{(?P<condition>[^\n\"{}]*)\};"
    )

    covers = []
    for match in assume_pattern.finditer(vhdl_code):
        label = (match.group("label") or "").strip()
        condition = (
            "{" + (match.group("condition") or "").strip().replace("|", "&#124;") + "};"
        )
        covers.append([label, condition, ".vhd"])

    return covers


def extract_covers_from_psl(psl_code: str) -> list[list[str]]:
    assume_pattern = re.compile(
        r"(?P<label>\w+)?\s*:\s*cover\s*\{(?P<condition>[^\n\"{}]*)\};"
    )

    covers = []
    for match in assume_pattern.finditer(psl_code):
        label = (match.group("label") or "").strip()
        condition = (
            (match.group("condition") or "")
            .strip()
            .replace("|", "&#124;")
            .replace("\n", "")
        )
        covers.append([label, condition, ".psl"])

    return covers


def generate_markdown_table(covers: list[list[str]]) -> str:
    markdown = "| Label | Condition |\n"
    markdown += "|-----------|-----------|\n"

    for label, condition, _ in covers:
        markdown += f"| {label} | {condition} |\n"

    return markdown


def document_covers(directory: Path) -> None:
    with open(f"{directory}/{directory.name}.vhd", "r") as file:
        vhdl_code = file.readlines()

    cleaned_code = uncomment_psl(vhdl_code)

    vhdl_covers = extract_covers_from_vhdl(cleaned_code)
    psl_covers = []

    if (directory / f"{directory.name}.psl").exists():
        with open(f"{directory}/{directory.name}.psl", "r") as file:
            psl_code = "\n".join(file.readlines())
            psl_covers = extract_covers_from_psl(psl_code)

    covers = vhdl_covers + psl_covers
    markdown_table = generate_markdown_table(covers)

    if not (directory / "README.md").exists():
        print(f"WARNING: {directory}/README.md does not exist. Skipping it...")
        return

    with open(f"{directory}/README.md", "r+", encoding="utf-8") as md_file:
        lines = md_file.readlines()

        # Remove all lines beginning with the line which contains "## Covers"
        for index, line in enumerate(lines):
            if "## Covers" in line:
                lines = lines[:index]
                break

        # Remove all blank lines at the end of the list
        while lines and not lines[-1].strip():
            lines.pop()

        # Move back to the beginning to overwrite
        md_file.seek(0)
        for index, line in enumerate(lines):
            md_file.write(line)

        if len(covers) > 0:
            md_file.write("\n## Covers\n\n")
            md_file.write(markdown_table)

        # Truncate file in case new content is shorter than original
        md_file.truncate()

    print(f"Covers saved: {str(directory)}\\README.md")


def document_all_covers(directory: Path) -> None:
    for entity_folder in directory.rglob("*"):
        if entity_folder.is_dir():
            vhdl_files = list(entity_folder.glob("*.vhd"))
            if not vhdl_files:
                print(f"WARNING: No .vhd files found in {entity_folder}. Skipping...")
            document_covers(entity_folder)


if __name__ == "__main__":
    document_all_covers(Path("source"))
