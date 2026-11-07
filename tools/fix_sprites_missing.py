
#!/usr/bin/env python3
"""
Rellena formas sin PNG copiando el sprite de la forma más cercana.

No pisa archivos que ya existen.
Solo crea SPECIES_N.png (y shiny/back/icon) para forms de forms.json
que no tengan archivo.

Uso (desde la raíz del proyecto):
  python tools/fill_missing_form_sprites.py ^
    --essentials "Graficos/Pokemon_Essentials" ^
    --forms "Datos/Species/forms.json"
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import sys
from pathlib import Path

FOLDERS = ("Front", "Front shiny", "Back", "Back shiny", "Icons", "Icons shiny")

# BULBASAUR.png  /  BULBASAUR_12.png  /  BULBASAUR_female.png  /  BULBASAUR_12_female.png
NAME_RE = re.compile(r"^([A-Z0-9]+)(?:_(\d+))?(_female)?\.png$", re.IGNORECASE)


def load_forms(path: Path) -> dict[str, set[int]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    out: dict[str, set[int]] = {}
    if not isinstance(data, list):
        return out
    for entry in data:
        if not isinstance(entry, dict):
            continue
        species = str(entry.get("species", "")).strip().upper()
        try:
            form = int(entry.get("form", 0))
        except (TypeError, ValueError):
            continue
        if not species or form <= 0:
            continue
        out.setdefault(species, set()).add(form)
    return out


def parse_name(filename: str) -> tuple[str, int, bool] | None:
    m = NAME_RE.match(filename)
    if not m:
        return None
    species = m.group(1).upper()
    form = int(m.group(2)) if m.group(2) else 0
    female = m.group(3) is not None
    return species, form, female


def closest(existing: set[int], wanted: int) -> int:
    return min(existing, key=lambda f: (abs(f - wanted), f))


def fill_folder(folder: Path, wanted: dict[str, set[int]], lines: list[str]) -> int:
    if not folder.is_dir():
        return 0

    # species -> female? -> {form: path}
    have: dict[str, dict[bool, dict[int, Path]]] = {}
    for png in folder.glob("*.png"):
        parsed = parse_name(png.name)
        if parsed is None:
            continue
        species, form, female = parsed
        have.setdefault(species, {}).setdefault(female, {})[form] = png

    made = 0
    for species, forms in wanted.items():
        by_gender = have.get(species)
        if not by_gender:
            continue
        # Solo el sprite base (no female). La hembra ya cae al base si no existe.
        existing = by_gender.get(False)
        if not existing:
            continue
        for form in sorted(forms):
            if form in existing:
                continue
            src_form = closest(set(existing), form)
            src = existing[src_form]
            dest_name = f"{species}_{form}.png"
            dest = folder / dest_name
            if dest.exists():
                continue
            shutil.copy2(src, dest)
            existing[form] = dest
            made += 1
            lines.append(f"FILL {folder.name}/{dest_name}  <=  {src.name}")
    return made


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--essentials", type=Path, required=True)
    ap.add_argument("--forms", type=Path, required=True)
    ap.add_argument("--report", type=Path, default=None)
    args = ap.parse_args()

    root: Path = args.essentials.resolve()
    forms_path: Path = args.forms.resolve()
    if not root.is_dir():
        print(f"No existe: {root}", file=sys.stderr)
        return 1
    if not forms_path.is_file():
        print(f"No existe: {forms_path}", file=sys.stderr)
        return 1

    wanted = load_forms(forms_path)
    print(f"Species con formas en JSON: {len(wanted)}")

    lines: list[str] = []
    total = 0
    for name in FOLDERS:
        n = fill_folder(root / name, wanted, lines)
        print(f"{name}: {n} rellenados")
        total += n

    report = args.report or (root / "_fill_missing_report.txt")
    report.write_text("\n".join(lines) + ("\n" if lines else ""), encoding="utf-8")
    print(f"Total: {total}")
    print(f"Informe: {report}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())