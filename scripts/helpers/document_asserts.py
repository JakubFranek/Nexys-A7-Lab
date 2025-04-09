import re
from pathlib import Path
from helpers.parse_vhdl import uncomment_psl


def extract_asserts_from_vhdl(vhdl_code: str) -> list[list[str]]:
    assert_pattern = re.compile(
        r"(?P<label>\w+)?\s*:\s*assert\s*\((?P<condition>[^\n\"]*)\)\s*(?:report\s*\"(?P<report>.*?)\"\s*)?(?:severity\s*(?P<severity>\w+))?"
    )

    asserts = []
    for match in assert_pattern.finditer(vhdl_code):
        label = (match.group("label") or "").strip()
        condition = (match.group("condition") or "").strip().replace("|", "&#124;")
        report = (match.group("report") or "").strip()
        severity = (match.group("severity") or "").strip()
        asserts.append([label, condition, report, severity, ".vhd"])

    return asserts


def extract_asserts_from_psl(psl_code: str) -> list[list[str]]:
    assert_pattern = re.compile(
        r"(?P<label>\w+)?\s*:\s*assert\s*(?P<condition>[\S\s]*?)\s*;\n"
    )

    asserts = []
    for match in assert_pattern.finditer(psl_code):
        label = (match.group("label") or "").strip()
        condition = (
            (match.group("condition") or "")
            .strip()
            .replace("|", "&#124;")
            .replace("\n", "")
        )
        report = ""
        severity = ""
        asserts.append([label, condition, report, severity, ".psl"])

    return asserts


def generate_markdown_table(asserts: list[list[str]]) -> str:
    markdown = "| Label | Condition | Report | Severity | File |\n"
    markdown += "|-------|-----------|--------|----------| -----|\n"

    for label, condition, report, severity, file in asserts:
        markdown += f"| {label} | {condition} | {report} | {severity} | {file} |\n"

    return markdown


def document_asserts(directory: Path) -> None:
    with open(f"{directory}/{directory.name}.vhd", "r") as file:
        vhdl_code = file.readlines()

    cleaned_code = uncomment_psl(vhdl_code)

    vhdl_asserts = extract_asserts_from_vhdl(cleaned_code)
    psl_asserts = []

    if (directory / f"{directory.name}.psl").exists():
        with open(f"{directory}/{directory.name}.psl", "r") as file:
            psl_code = "\n".join(file.readlines())
            psl_asserts = extract_asserts_from_psl(psl_code)

    asserts = vhdl_asserts + psl_asserts
    markdown_table = generate_markdown_table(asserts)

    if not (directory / "README.md").exists():
        print(f"WARNING: {directory}/README.md does not exist. Skipping it...")
        return

    with open(f"{directory}/README.md", "r+", encoding="utf-8") as md_file:
        lines = md_file.readlines()

        # Remove all lines beginning with the line which contains "## Assertions"
        for index, line in enumerate(lines):
            if "## Assertions" in line:
                lines = lines[:index]
                break

        # Remove all blank lines at the end of the list
        while lines and not lines[-1].strip():
            lines.pop()

        # Move back to the beginning to overwrite
        md_file.seek(0)
        for index, line in enumerate(lines):
            md_file.write(line)

        if len(asserts) > 0:
            md_file.write("\n## Assertions\n\n")
            md_file.write(markdown_table)

        # Truncate file in case new content is shorter than original
        md_file.truncate()

    print(f"Asserts saved: {str(directory)}\\README.md")


def document_all_asserts(directory: Path) -> None:
    for entity_folder in directory.rglob("*"):
        if entity_folder.is_dir():
            vhdl_files = list(entity_folder.glob("*.vhd"))
            if not vhdl_files:
                print(f"WARNING: No .vhd files found in {entity_folder}. Skipping...")
            document_asserts(entity_folder)


if __name__ == "__main__":
    document_all_asserts(Path("source"))
