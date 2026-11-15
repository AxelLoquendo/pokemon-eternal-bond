#!/usr/bin/env python3
"""Crea una ficha propia por cada id listado en form_species que no exista.
El import a .tres solo emite especies de primer nivel; sin esto Alcremie
(y otras familias) quedan como una sola entrada.

Uso:
  python3 tools/expand_missing_forms.py Datos/Pokemon/species.json
Luego en Godot: tools/import_species_tres.gd → File → Run
"""
import copy, json, sys
from pathlib import Path

SWEETS = ["STRAWBERRY", "BERRY", "LOVE", "STAR", "CLOVER", "FLOWER", "RIBBON"]


def pretty(token: str) -> str:
    return " ".join(p.capitalize() for p in token.split("_") if p)


def alcremie_folder(token: str) -> str:
    if token == "ALCREMIE_GMAX":
        return "alcremie/gmax"
    if not token.startswith("ALCREMIE_"):
        return "alcremie"
    rest = token[len("ALCREMIE_") :]
    for sweet in SWEETS:
        prefix = sweet + "_"
        if rest.startswith(prefix):
            cream = rest[len(prefix) :].lower()
            sweet_l = sweet.lower()
            if sweet_l == "strawberry" and cream == "vanilla_cream":
                return "alcremie"
            if sweet_l == "strawberry":
                return f"alcremie/{cream}"
            return f"alcremie/{sweet_l}"
    return "alcremie"


def main() -> None:
    path = Path(sys.argv[1] if len(sys.argv) > 1 else "Datos/Pokemon/species.json")
    data = json.loads(path.read_text(encoding="utf-8"))
    ids = {d["id"] for d in data if isinstance(d, dict) and d.get("id")}
    added = 0
    for d in data:
        if isinstance(d, dict) and d.get("id") == "ALCREMIE_STRAWBERRY_VANILLA_CREAM":
            d["sprite_folder"] = "alcremie"
            d["is_gigantamax"] = False
    for d in list(data):
        if not isinstance(d, dict):
            continue
        for fid in d.get("form_species") or []:
            if not isinstance(fid, str) or fid in ids:
                continue
            clone = copy.deepcopy(d)
            clone["id"] = fid
            clone["display_name"] = pretty(fid)
            clone["is_gigantamax"] = fid.endswith("_GMAX") or fid.endswith("_GIGANTAMAX")
            if fid.startswith("ALCREMIE_"):
                clone["sprite_folder"] = alcremie_folder(fid)
            data.append(clone)
            ids.add(fid)
            added += 1
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"expand_missing_forms: +{added} especies, total {len(data)} → {path}")


if __name__ == "__main__":
    main()
