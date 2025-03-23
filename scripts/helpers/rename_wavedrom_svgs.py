import re
from pathlib import Path


from helpers.add_svg_white_background import add_white_background

# This script will iterate through all folders within source directory. It will read all Markdown files within each folder
# and find the names of all used wavedrom SVGs. It will remove the unused wavedrom SVGs, and it will renamed the used
# wavedrom SVGs to {entity_name}_wavedrom_{index}.svg where {entity_name} is the name of the entity that uses the SVG
# and {index} is the index of the SVG in the list of SVGs used by the entity. It will also update the Markdown files
# to reflect the new SVG filenames.

# Define source directory
SOURCE_DIRECTORY = Path("source")
FILE_NAME_PATTERN = re.compile(r"wavedrom_[A-Za-z0-9]{5}\.svg")


def find_used_svgs(markdown_files: list[Path]):
    """Extracts used Wavedrom SVG filenames from Markdown files."""

    used_svgs: dict[str, list[str]] = {}

    for md_file in markdown_files:
        entity_name = md_file.parent.name  # Using the folder name as entity_name
        with md_file.open("r", encoding="utf-8") as f:
            content = f.read()
            matches = FILE_NAME_PATTERN.findall(content)

            if matches:
                if entity_name not in used_svgs:
                    used_svgs[entity_name] = []

                for match in matches:
                    if match not in used_svgs[entity_name]:
                        used_svgs[entity_name].append(match)

    return used_svgs


def update_markdown_references(
    markdown_files: list[Path], rename_map: dict[str, str]
) -> None:
    """Updates Markdown files to reflect the new SVG filenames."""

    for md_file in markdown_files:
        content: str = md_file.read_text(encoding="utf-8")
        renamed_refs = 0
        for old_name, new_name in rename_map.items():
            if old_name == new_name:
                continue
            content = content.replace(f"{old_name}", f"{new_name}")
            renamed_refs += 1
        md_file.write_text(content, encoding="utf-8")

        if renamed_refs > 0:
            print(f"Updated {renamed_refs} SVG references in Markdown file: {md_file}")


def cleanup_and_rename_svgs(directory: Path):
    """This script will iterate through all folders within specified directory. It will read all Markdown files within each folder
    and find the names of all used WaveDrom SVGs. It will remove the unused WaveDrom SVGs, and it will rename the used
    WaveDrom SVGs to `{entity_name}_wavedrom_{index}.svg` where `{entity_name}` is the name of the entity that uses the SVG
    and `{index}` is the index of the SVG in the list of SVGs used by the entity. It will also update the Markdown files
    to reflect the new SVG filenames."""

    for entity_folder in directory.rglob("*"):
        if entity_folder.is_dir():
            markdown_files = list(entity_folder.glob("*.md"))

            svg_files: list[Path] = entity_folder.glob("*.svg")
            for svg_file in svg_files:
                add_white_background(svg_file)

            wavedrom_svg_files: list[Path] = [
                f
                for f in entity_folder.glob("wavedrom_*.svg")
                if FILE_NAME_PATTERN.match(f.name)
            ]

            used_svgs = find_used_svgs(markdown_files)
            entity_name = entity_folder.name

            used_svg_set = set(used_svgs.get(entity_name, []))
            rename_map: dict[str, str] = {}

            # Remove unused SVGs
            for svg_file in wavedrom_svg_files:
                if svg_file.name not in used_svg_set:
                    svg_file.unlink()
                    print(f"Removed unused SVG: {svg_file}")

            # Rename used SVGs and fix the Markdown file links to them
            for index, old_svg_name in enumerate(used_svgs.get(entity_name, [])):
                add_white_background(entity_folder / old_svg_name)

                old_svg_path = entity_folder / old_svg_name
                new_svg_name = f"{entity_name}_wavedrom_{index}.svg"
                new_svg_path = entity_folder / new_svg_name

                if old_svg_path == new_svg_path:
                    continue

                if old_svg_path.exists():
                    try:
                        old_svg_path.rename(new_svg_path)
                    except FileExistsError:
                        # If the new file name already exists, remove the old one and rename the new one
                        new_svg_path.unlink()
                        old_svg_path.rename(new_svg_path)
                    rename_map[old_svg_name] = new_svg_name
                    print(f"Renamed SVG: {old_svg_path} -> {new_svg_path}")

            update_markdown_references(markdown_files, rename_map)


if __name__ == "__main__":
    cleanup_and_rename_svgs(SOURCE_DIRECTORY)
