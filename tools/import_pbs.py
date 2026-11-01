#!/usr/bin/env python3
"""Importa PBS → enums + JSON. Imprime entradas omitidas.

Uso:
  python tools/import_pbs.py abilities tools/abilities.txt
  python tools/import_pbs.py moves tools/moves.txt
  python tools/import_pbs.py species tools/pokemon.txt
  python tools/import_pbs.py all tools/PBS --root "C:/Users/ASUS/Desktop/pokemon-eternal-bond"
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

# Mayúsculas y minúsculas: NIDORANfE, NIDORANmA, etc.
SECTION_RE = re.compile(r"^\[([A-Za-z0-9_]+)\]$")
ID_RE = re.compile(r"^[A-Za-z0-9_]+$")


def parse_pbs(text: str, label: str) -> list[dict]:
    text = text.lstrip("\ufeff")
    items: list[dict] = []
    current: dict | None = None
    line_no = 0
    skipped_empty_sections = 0

    for raw in text.splitlines():
        line_no += 1
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        m = SECTION_RE.match(line)
        if m:
            if current is not None:
                # current tiene id + campos; _line es metadata
                field_count = len([k for k in current if k not in ("id", "_line")])
                if field_count == 0:
                    skipped_empty_sections += 1
                    print(
                        f"[{label}] OMITIDA sección vacía "
                        f"id={current.get('id')} (antes de línea {line_no})"
                    )
                else:
                    items.append(current)
            current = {"id": m.group(1), "_line": line_no}
            continue
        if current is None:
            print(f"[{label}] OMITIDA línea huérfana {line_no}: {line[:80]}")
            continue
        if "=" not in line:
            print(f"[{label}] OMITIDA línea sin '=': {line_no}: {line[:80]}")
            continue
        key, val = line.split("=", 1)
        current[key.strip()] = val.strip()

    if current is not None:
        field_count = len([k for k in current if k not in ("id", "_line")])
        if field_count == 0:
            skipped_empty_sections += 1
            print(f"[{label}] OMITIDA sección vacía al final id={current.get('id')}")
        else:
            items.append(current)

    for it in items:
        it.pop("_line", None)

    if skipped_empty_sections:
        print(f"[{label}] Total secciones vacías omitidas: {skipped_empty_sections}")
    return items


FROM_TOKEN_BODY = '''
static func from_token(token: String) -> Id:
	var t: String = token.strip_edges()
	if t.is_empty():
		return Id.NONE
	if t.is_valid_int():
		var n: int = int(t)
		if n >= 0 and n < Id.size():
			return n as Id
		push_warning("{cls}: id fuera de rango: %s" % t)
		return Id.NONE
	var keys: Array = Id.keys()
	# Match exacto (NIDORANfE / NIDORANmA)
	for i: int in keys.size():
		if str(keys[i]) == t:
			return i as Id
	# Case-insensitive
	var upper: String = t.to_upper()
	for i: int in keys.size():
		if str(keys[i]).to_upper() == upper:
			return i as Id
	push_error("{cls}: no declarado '%s'" % t)
	return Id.NONE


static func to_key(id: Id) -> String:
	if id == Id.NONE:
		return ""
	return str(Id.keys()[id])
'''.lstrip("\n")


def write_enum(class_name: str, ids: list[str], path: Path, header_note: str) -> None:
    lines = [
        "extends Object",
        f"class_name {class_name}",
        f"## {header_note}",
        "",
        "enum Id {",
        "\tNONE = 0,",
        "",
    ]
    for i in ids:
        lines.append(f"\t{i},")
    lines.append("}")
    lines.append("")
    lines.append("")
    body = FROM_TOKEN_BODY.replace("{cls}", class_name)
    lines.append(body.rstrip())
    lines.append("")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines), encoding="utf-8")


def write_json(rows: list[dict], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(rows, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def _unique_ids(raw: list[dict], label: str) -> list[dict]:
    seen: set[str] = set()
    out: list[dict] = []
    for r in raw:
        i = r.get("id", "")
        if not i:
            print(f"[{label}] OMITIDA entrada sin id: {r}")
            continue
        if i in seen:
            print(f"[{label}] OMITIDA id duplicado: {i}")
            continue
        seen.add(i)
        out.append(r)
    return out


def import_abilities(src: Path, root: Path) -> int:
    label = "abilities"
    raw = _unique_ids(parse_pbs(src.read_text(encoding="utf-8"), label), label)
    rows: list[dict] = []
    ids: list[str] = []
    for r in raw:
        i = r["id"]
        if not ID_RE.fullmatch(i):
            print(f"[{label}] OMITIDA id inválido: {i!r}")
            continue
        ids.append(i)
        rows.append({
            "id": i,
            "name": r.get("Name", i),
            "description": r.get("Description", ""),
        })
    write_enum(
        "AbilityId",
        ids,
        root / "Scripts/Data/Abilities/ability_id.gd",
        "Generado por tools/import_pbs.py abilities",
    )
    write_json(rows, root / "Datos/Abilities/abilities.json")
    print(f"[{label}] OK: {len(rows)} exportadas")
    return len(rows)


def import_moves(src: Path, root: Path) -> int:
    label = "moves"
    raw = _unique_ids(parse_pbs(src.read_text(encoding="utf-8"), label), label)
    rows: list[dict] = []
    ids: list[str] = []
    for r in raw:
        i = r["id"]
        if not ID_RE.fullmatch(i):
            print(f"[{label}] OMITIDA id inválido: {i!r}")
            continue
        flags = [f.strip() for f in r.get("Flags", "").split(",") if f.strip()]
        try:
            power = int(r.get("Power", "0") or 0)
            accuracy = int(r.get("Accuracy", "0") or 0)
            total_pp = int(r.get("TotalPP", "5") or 5)
            priority = int(r.get("Priority", "0") or 0)
        except ValueError as e:
            print(f"[{label}] OMITIDA {i}: número inválido ({e})")
            continue
        ids.append(i)
        rows.append({
            "id": i,
            "name": r.get("Name", i),
            "type": r.get("Type", ""),
            "category": r.get("Category", "Status"),
            "power": power,
            "accuracy": accuracy,
            "total_pp": total_pp,
            "priority": priority,
            "target": r.get("Target", "NearOther"),
            "function_code": r.get("FunctionCode", "None"),
            "flags": flags,
            "description": r.get("Description", ""),
        })
        if not r.get("Type"):
            print(f"[{label}] AVISO {i}: sin Type")
    write_enum(
        "MoveId",
        ids,
        root / "Scripts/Data/Moves/move_id.gd",
        "Generado por tools/import_pbs.py moves",
    )
    write_json(rows, root / "Datos/Moves/moves.json")
    print(f"[{label}] OK: {len(rows)} exportadas")
    return len(rows)


def _split_csv(s: str) -> list[str]:
    return [x.strip() for x in s.split(",") if x.strip()]


def _parse_level_moves(s: str, species_id: str) -> list[dict]:
    parts = _split_csv(s)
    out: list[dict] = []
    i = 0
    bad = 0
    while i < len(parts):
        # Acepta 0, 5, -1 (prevo), etc.
        try:
            level = int(parts[i])
        except ValueError:
            bad += 1
            if bad <= 3:
                print(f"[species] AVISO {species_id}: token no numérico en Moves: {parts[i]!r}")
            i += 1
            continue
        if i + 1 >= len(parts):
            bad += 1
            print(f"[species] AVISO {species_id}: nivel sin movimiento: {level}")
            break
        move = parts[i + 1]
        out.append({"level": level, "move": move})
        i += 2
    if bad:
        print(f"[species] AVISO {species_id}: {bad} tokens raros en Moves (tras fix debería ser 0)")
    return out

def _parse_stats(s: str, species_id: str) -> dict | None:
    try:
        p = [int(x) for x in _split_csv(s)]
    except ValueError:
        print(f"[species] OMITIDA {species_id}: BaseStats no numérico: {s!r}")
        return None
    if len(p) < 6:
        print(f"[species] OMITIDA {species_id}: BaseStats incompleto ({len(p)}/6): {s!r}")
        return None
    return {
        "base_hp": p[0],
        "base_atk": p[1],
        "base_def": p[2],
        "base_spe": p[3],
        "base_spa": p[4],
        "base_spd": p[5],
    }


def import_species(src: Path, root: Path) -> int:
    label = "species"
    raw = _unique_ids(parse_pbs(src.read_text(encoding="utf-8"), label), label)
    rows: list[dict] = []
    ids: list[str] = []
    for r in raw:
        i = r["id"]
        if not ID_RE.fullmatch(i):
            print(f"[{label}] OMITIDA id inválido: {i!r}")
            continue
        if "BaseStats" not in r:
            print(f"[{label}] OMITIDA {i}: sin BaseStats")
            continue
        stats = _parse_stats(r["BaseStats"], i)
        if stats is None:
            continue
        ids.append(i)
        rows.append({
            "id": i,
            "name": r.get("Name", i),
            "types": _split_csv(r.get("Types", "")),
            **stats,
            "catch_rate": int(r.get("CatchRate", "45") or 45),
            "base_exp": int(r.get("BaseExp", "0") or 0),
            "base_happiness": int(r.get("Happiness", "50") or 50),
            "gender_ratio": r.get("GenderRatio", "Female50Percent"),
            "growth_rate": r.get("GrowthRate", "Medium"),
            "abilities": _split_csv(r.get("Abilities", "")),
            "hidden_abilities": _split_csv(r.get("HiddenAbilities", "")),
            "level_moves": _parse_level_moves(r.get("Moves", ""), i),
            "tutor_moves": _split_csv(r.get("TutorMoves", "")),
            "egg_moves": _split_csv(r.get("EggMoves", "")),
            "egg_groups": _split_csv(r.get("EggGroups", "")),
            "hatch_steps": int(r.get("HatchSteps", "0") or 0),
            "height_m": float(r.get("Height", "0") or 0),
            "weight_kg": float(r.get("Weight", "0") or 0),
            "color": r.get("Color", ""),
            "shape": r.get("Shape", ""),
            "category": r.get("Category", ""),
            "pokedex": r.get("Pokedex", ""),
            "generation": int(r.get("Generation", "1") or 1),
            "evolutions": _split_csv(r.get("Evolutions", "")),
        })
        if not r.get("Types"):
            print(f"[{label}] AVISO {i}: sin Types")
        if not r.get("Abilities"):
            print(f"[{label}] AVISO {i}: sin Abilities")
    write_enum(
        "SpeciesId",
        ids,
        root / "Scripts/Data/Species/species_id.gd",
        "Generado por tools/import_pbs.py species",
    )
    write_json(rows, root / "Datos/Species/species.json")
    print(f"[{label}] OK: {len(rows)} exportadas")
    return len(rows)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("kind", choices=["abilities", "moves", "species", "all"])
    ap.add_argument("path", type=Path)
    ap.add_argument("--root", type=Path, default=None)
    args = ap.parse_args()

    root = (args.root or Path(__file__).resolve().parents[1]).resolve()
    path: Path = args.path

    print(f"root = {root}")
    print(f"path = {path}")

    if args.kind == "all":
        if not path.is_dir():
            print("all requiere carpeta PBS", file=sys.stderr)
            return 1
        for name, fn in [
            ("abilities.txt", import_abilities),
            ("moves.txt", import_moves),
            ("pokemon.txt", import_species),
        ]:
            f = path / name
            if not f.is_file():
                print(f"NO ENCONTRADO: {f}")
                continue
            print(f"\n=== {name} ===")
            fn(f, root)
        return 0

    if not path.is_file():
        print(f"No existe: {path}", file=sys.stderr)
        return 1

    print(f"\n=== {args.kind} ===")
    if args.kind == "abilities":
        import_abilities(path, root)
    elif args.kind == "moves":
        import_moves(path, root)
    else:
        import_species(path, root)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())