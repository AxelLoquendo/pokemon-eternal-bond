#!/usr/bin/env python3
"""
Si existe Front/X.png y no Front shiny/X.png, copia el normal.
Igual con Back -> Back shiny.
No crea formas nuevas. No toca Icons.
"""
import argparse
import shutil
import sys
from pathlib import Path

PAIRS = (
    ("Front", "Front shiny"),
    ("Back", "Back shiny"),
)

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--essentials", type=Path, required=True)
    ap.add_argument("--report", type=Path, default=None)
    args = ap.parse_args()
    root = args.essentials.resolve()
    if not root.is_dir():
        print(f"No existe: {root}", file=sys.stderr)
        return 1

    lines: list[str] = []
    total = 0
    for src_name, dst_name in PAIRS:
        src_dir = root / src_name
        dst_dir = root / dst_name
        if not src_dir.is_dir():
            continue
        dst_dir.mkdir(parents=True, exist_ok=True)
        n = 0
        for src in src_dir.glob("*.png"):
            dest = dst_dir / src.name
            if dest.exists():
                continue
            shutil.copy2(src, dest)
            n += 1
            lines.append(f"SHINY {dst_name}/{src.name}  <=  {src_name}/{src.name}")
        print(f"{dst_name}: {n}")
        total += n

    report = args.report or (root / "_shiny_gaps_report.txt")
    report.write_text("\n".join(lines) + ("\n" if lines else ""), encoding="utf-8")
    print(f"Total: {total}")
    print(f"Informe: {report}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())