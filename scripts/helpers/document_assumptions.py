import re
from pathlib import Path
from helpers.parse_vhdl import uncomment_psl


def extract_assumptions_from_vhdl(vhdl_code: str) -> list[list[str]]:
    assume_pattern = re.compile(r"assume\s*\((?P<condition>[^\n\";]*)\)")

    assumes = []
    for match in assume_pattern.finditer(vhdl_code):
        condition = (match.group("condition") or "").strip().replace("|", "&#124;")
        assumes.append([condition, ".vhd"])

    return assumes


def extract_assumptions_from_psl(psl_code: str) -> list[list[str]]:
    assume_pattern = re.compile(r"assume\s*(?P<condition>[^\n\";]*)")

    assumes = []
    for match in assume_pattern.finditer(psl_code):
        condition = (
            (match.group("condition") or "")
            .strip()
            .replace("|", "&#124;")
            .replace("\n", "")
        )
        assumes.append([condition, ".psl"])

    return assumes


def generate_markdown_table(assumes: list[list[str]]) -> str:
    markdown = "| Condition | File |\n"
    markdown += "|-----------|-----|\n"

    for condition, file in assumes:
        markdown += f"| {condition} | {file} |\n"

    return markdown


def document_assumptions(directory: Path) -> None:
    with open(f"{directory}/{directory.name}.vhd", "r") as file:
        vhdl_code = file.readlines()

    cleaned_code = uncomment_psl(vhdl_code)

    vhdl_assumes = extract_assumptions_from_vhdl(cleaned_code)
    psl_assumes = []

    if (directory / f"{directory.name}.psl").exists():
        with open(f"{directory}/{directory.name}.psl", "r") as file:
            psl_code = "\n".join(file.readlines())
            psl_assumes = extract_assumptions_from_psl(psl_code)

    markdown_table = generate_markdown_table(vhdl_assumes + psl_assumes)

    if not (directory / "README.md").exists():
        print(f"WARNING: {directory}/README.md does not exist. Skipping it...")
        return

    with open(f"{directory}/README.md", "r+", encoding="utf-8") as md_file:
        lines = md_file.readlines()

        # Remove all lines beginning with the line which contains "## Assumptions"
        for index, line in enumerate(lines):
            if "## Assumptions" in line:
                lines = lines[:index]
                break

        # Remove all blank lines at the end of the list
        while lines and not lines[-1].strip():
            lines.pop()

        # Move back to the beginning to overwrite
        md_file.seek(0)
        for index, line in enumerate(lines):
            md_file.write(line)

        md_file.write("\n## Assumptions\n\n")
        md_file.write(markdown_table)

        # Truncate file in case new content is shorter than original
        md_file.truncate()

    print(f"Assumptions saved: {str(directory)}\\README.md")


def document_all_assumptions(directory: Path) -> None:
    for entity_folder in directory.rglob("*"):
        if entity_folder.is_dir():
            vhdl_files = list(entity_folder.glob("*.vhd"))
            if not vhdl_files:
                print(f"WARNING: No .vhd files found in {entity_folder}. Skipping...")
            document_assumptions(entity_folder)


if __name__ == "__main__":
    document_all_assumptions(Path("source"))
