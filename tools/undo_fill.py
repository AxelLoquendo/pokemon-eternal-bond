#!/usr/bin/env python3
"""Borra los PNG creados por fill_missing_form_sprites.py."""
import argparse
import sys
from pathlib import Path

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--essentials", type=Path, required=True)
    ap.add_argument("--report", type=Path, required=True)
    args = ap.parse_args()
    root = args.essentials.resolve()
    n = 0
    for line in args.report.read_text(encoding="utf-8").splitlines():
        if not line.startswith("FILL "):
            continue
        # FILL Front/PIKACHU_5.png  <=  PIKACHU_4.png
        left = line.split()[1]
        path = root / left
        if path.is_file():
            path.unlink()
            n += 1
    print(f"Borrados: {n}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())