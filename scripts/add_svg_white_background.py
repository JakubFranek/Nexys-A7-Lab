import re
from pathlib import Path

SOURCE_DIRECTORY = Path("source")
FILE_NAME_PATTERN = re.compile(r"wavedrom_[A-Za-z0-9]{5}\.svg")


def add_white_background(svg_file: Path):
    with open(svg_file, "r", encoding="utf-8") as f:
        content = f.read()

    # Skip if the SVG already has a white background
    if '<rect width="100%" height="100%" fill="white"/>' in content:
        return

    # Regex to find the <svg> tag and insert the <rect>
    modified_content = re.sub(
        r"(<svg[^>]*>)", r'\1<rect width="100%" height="100%" fill="white"/>', content
    )

    with open(svg_file, "w", encoding="utf-8") as f:
        f.write(modified_content)

    print(f"Added white background to SVG: {svg_file}")


if __name__ == "__main__":
    for entity_folder in SOURCE_DIRECTORY.rglob("*"):
        if entity_folder.is_dir():
            svg_files: list[Path] = entity_folder.glob("*.svg")

            for svg_file in svg_files:
                add_white_background(svg_file)
