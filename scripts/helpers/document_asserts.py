import re
from pathlib import Path


def extract_asserts(vhdl_code):
    assert_pattern = re.compile(
        r"(?P<label>\w+)?\s*:\s*assert\s*\((?P<condition>[^\n\"]*)\)\s*(?:report\s*\"(?P<report>.*?)\"\s*)?(?:severity\s*(?P<severity>\w+))?"
    )

    asserts = []
    for match in assert_pattern.finditer(vhdl_code):
        label = (match.group("label") or "").strip()
        condition = (match.group("condition") or "").strip().replace("|", "&#124;")
        report = (match.group("report") or "").strip()
        severity = (match.group("severity") or "").strip()
        asserts.append([label, condition, report, severity])

    return asserts


def generate_markdown_table(asserts):
    markdown = "| Label | Condition | Report | Severity |\n"
    markdown += "|-------|-----------|--------|----------|\n"

    for label, condition, report, severity in asserts:
        markdown += f"| {label} | {condition} | {report} | {severity} |\n"

    return markdown


def document_asserts(directory: Path):
    with open(f"{directory}/{directory.name}.vhd", "r") as file:
        vhdl_code = file.readlines()

    cleaned_lines = []
    inside_psl = False
    psl_block = []
    for line in vhdl_code:
        if "-- psl" in line:
            inside_psl = True
            psl_block = [
                line.replace("-- psl", "").strip()
            ]  # Start PSL block, remove leading marker
            continue

        if inside_psl:
            stripped_line = line.replace("--", "").strip()
            psl_block.append(stripped_line)  # Collect multiline PSL assert
            if ";" in stripped_line:
                inside_psl = False  # End PSL block
                cleaned_lines.append(" ".join(psl_block))  # Reassemble as a single line
                psl_block = []
            continue

        cleaned_lines.append(
            re.sub(r"--(?!\s*psl).*", "", line)
        )  # Remove non-PSL comments

    cleaned_code = "\n".join(cleaned_lines)

    asserts = extract_asserts(cleaned_code)
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

        md_file.write("\n## Assertions\n\n")
        md_file.write(markdown_table)

        # Truncate file in case new content is shorter than original
        md_file.truncate()

    print(f"Assert table saved to {str(directory).replace('\\', '/')}/README.md")


def document_asserts_all(directory: Path):
    for entity_folder in directory.rglob("*"):
        if entity_folder.is_dir():
            vhdl_files = list(entity_folder.glob("*.vhd"))
            if not vhdl_files:
                print(f"WARNING: No .vhd files found in {entity_folder}. Skipping...")
            document_asserts(entity_folder)


if __name__ == "__main__":
    document_asserts_all(Path("source"))
