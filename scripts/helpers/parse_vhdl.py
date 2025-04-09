import re


def uncomment_psl(code: str) -> str:
    cleaned_lines = []
    inside_psl = False
    psl_block = []
    for line in code:
        if "-- psl" in line:
            inside_psl = True
            line = line.replace(
                "-- psl", "--"
            ).strip()  # Start PSL block, remove leading marker

        if inside_psl:
            stripped_line = line.replace("--", "").strip()
            psl_block.append(stripped_line)  # Collect multiline PSL assume
            if ";" in stripped_line:
                inside_psl = False  # End PSL block
                cleaned_lines.append(
                    " ".join(psl_block) + "\n"
                )  # Reassemble as a single line
                psl_block = []
            continue

        cleaned_lines.append(
            re.sub(r"--(?!\s*psl).*", "", line)
        )  # Remove non-PSL comments

    return "\n".join(cleaned_lines)
