
#!/usr/bin/env python3
"""Importa PBS → enums + JSON.

Uso:
  python tools/import_pbs.py abilities tools/abilities.txt
  python tools/import_pbs.py moves tools/moves.txt
  python tools/import_pbs.py species tools/pokemon.txt
  python tools/import_pbs.py forms tools/pokemon_forms.txt
  python tools/import_pbs.py all tools/PBS --root "C:/Users/ASUS/Desktop/pokemon-eternal-bond"
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

# [BULBASAUR] o [VENUSAUR,1] o [NIDORANfE]
SECTION_RE = re.compile(r"^\[([A-Za-z0-9_]+)(?:\s*,\s*(\d+))?\]$")
ID_RE = re.compile(r"^[A-Za-z0-9_]+$")

# Métodos que en este PBS NO llevan parámetro.
# "None" = evolución especial/plugin (Basculegion Hisui, etc.).
_EVO_NO_PARAM = {
    "None",
    "Happiness",
    "HappinessMale",
    "HappinessFemale",
    "HappinessDay",
    "HappinessNight",
    "HappinessMorning",
    "HappinessAfternoon",
    "HappinessEvening",
    "Trade",
    "BattleDealCriticalHit",
}

# Métodos que SIEMPRE llevan parámetro, aunque parezca un id.
_EVO_WITH_PARAM = {
    "Level", "LevelMale", "LevelFemale", "LevelDay", "LevelNight",
    "LevelMorning", "LevelAfternoon", "LevelEvening", "LevelRain",
    "LevelDarkInParty", "LevelUseMoveCount", "LevelWalk", "LevelCoins",
    "LevelRandForm", "LevelRecoilDamageForm0", "LevelDefeatItsKindWithItem",
    "Item", "ItemMale", "ItemFemale", "ItemDay", "ItemNight",
    "HoldItem", "HoldItemMale", "HoldItemFemale", "DayHoldItem", "NightHoldItem",
    "HasMove", "HasMoveType", "HasMoveRandForm", "HasInParty",
    "HappinessMove", "HappinessMoveType",
    "Location", "LocationFlag", "Region",
    "TradeItem", "TradeSpecies", "CableLink", "CableLinkItem",
    "Beauty", "AttackGreater", "DefenseGreater", "AtkDefEqual",
    "Silcoon", "Cascoon", "Ninjask", "Shedinja", "Magnetic",
    "AfterBattleCounter", "AfterBattleCounterMakeReady",
    "CollectItems",
}


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
                field_count = len(
                    [k for k in current if k not in ("id", "form", "_line")]
                )
                if field_count == 0:
                    skipped_empty_sections += 1
                    print(
                        f"[{label}] OMITIDA sección vacía "
                        f"id={current.get('id')} form={current.get('form')} "
                        f"(antes de línea {line_no})"
                    )
                else:
                    items.append(current)
            current = {
                "id": m.group(1),
                "form": int(m.group(2)) if m.group(2) is not None else 0,
                "_line": line_no,
            }
            continue
        if current is None:
            print(f"[{label}] OMITIDA línea huérfana {line_no}: {line[:80]}")
            continue
        if "=" not in line:
            print(f"[{label}] OMITIDA línea sin '=': {line_no}: {line[:80]}")
            continue
        key, val = line.split("=", 1)
        key = key.strip()
        val = val.strip()
        # La misma clave puede repetirse. Un valor vacío no borra lo anterior.
        # Solo se concatenan listas. El resto, si se repite, se queda con el último valor.
        _JOIN_KEYS = {
            "Evolutions", "Evolution", "Moves", "TutorMoves", "EggMoves",
            "Abilities", "HiddenAbilities", "Flags", "Types", "EggGroups",
            "Offspring",
        }
        if key in current and key not in ("id", "form"):
            prev = str(current[key]).strip()
            if not val:
                continue
            if key in _JOIN_KEYS and prev:
                current[key] = f"{prev},{val}"
            else:
                current[key] = val
        else:
            current[key] = val

    if current is not None:
        field_count = len([k for k in current if k not in ("id", "form", "_line")])
        if field_count == 0:
            skipped_empty_sections += 1
            print(
                f"[{label}] OMITIDA sección vacía al final "
                f"id={current.get('id')} form={current.get('form')}"
            )
        else:
            items.append(current)

    for it in items:
        it.pop("_line", None)

    if skipped_empty_sections:
        print(f"[{label}] Total secciones vacías omitidas: {skipped_empty_sections}")
    return items


FROM_TOKEN_BODY = """
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
	for i: int in keys.size():
		if str(keys[i]) == t:
			return i as Id
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
""".lstrip("\n")


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


def _split_csv(s: str) -> list[str]:
    return [x.strip() for x in s.split(",") if x.strip()]


def _split_evo_tokens(s: str) -> list[str]:
    """Conserva huecos vacíos del medio y quita comas finales."""
    if not s.strip():
        return []
    parts = [x.strip() for x in s.split(",")]
    while parts and parts[-1] == "":
        parts.pop()
    return parts


def _looks_like_method(tok: str) -> bool:
    if not tok:
        return False
    if tok in _EVO_NO_PARAM or tok in _EVO_WITH_PARAM:
        return True
    return any(c.islower() for c in tok)


def _looks_like_species(tok: str) -> bool:
    if not tok or tok.isdigit():
        return False
    core = tok.replace("_", "")
    return core.isalnum() and tok == tok.upper()


def _parse_level_moves(s: str, species_id: str) -> list[dict]:
    parts = _split_csv(s)
    out: list[dict] = []
    i = 0
    bad = 0
    while i < len(parts):
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
        out.append({"level": level, "move": parts[i + 1]})
        i += 2
    if bad:
        print(f"[species] AVISO {species_id}: {bad} tokens raros en Moves")
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


def _parse_evs(s: str) -> dict:
    """PBS: STAT,amount,STAT,amount. Orden: hp, atk, def, spe, spa, spd."""
    parts = _split_csv(s)
    evs = {"hp": 0, "atk": 0, "def": 0, "spe": 0, "spa": 0, "spd": 0}
    key_map = {
        "HP": "hp",
        "ATTACK": "atk",
        "DEFENSE": "def",
        "SPEED": "spe",
        "SPECIAL_ATTACK": "spa",
        "SPECIAL_DEFENSE": "spd",
    }
    i = 0
    while i + 1 < len(parts):
        stat = key_map.get(parts[i].upper())
        try:
            amount = int(parts[i + 1])
        except ValueError:
            amount = 0
        if stat:
            evs[stat] = amount
        i += 2
    return evs


def _parse_evolutions(s: str, species_id: str) -> list[dict]:
    parts = _split_evo_tokens(s)
    out: list[dict] = []
    i = 0
    while i + 1 < len(parts):
        into = parts[i]
        method = parts[i + 1]
        if not into or not method:
            i += 1
            continue
        i += 2
        param = ""
        if method in _EVO_NO_PARAM:
            # HappinessDay,,UMBREON  o  BASCULEGION,None,
            if i < len(parts) and parts[i] == "":
                i += 1
        else:
            if i >= len(parts):
                print(f"[species] AVISO {species_id}: {into},{method} sin param")
                break
            nxt = parts[i]
            nxt2 = parts[i + 1] if i + 1 < len(parts) else ""
            if (
                method not in _EVO_WITH_PARAM
                and nxt != ""
                and _looks_like_species(nxt)
                and _looks_like_method(nxt2)
            ):
                print(
                    f"[species] AVISO {species_id}: método '{method}' "
                    f"tratado sin parámetro (siguiente rama {nxt},{nxt2})"
                )
            else:
                param = nxt
                i += 1
        out.append({"into": into, "method": method, "param": param})
    if i < len(parts):
        print(f"[species] AVISO {species_id}: Evolutions tokens sobrantes: {parts[i:]}")
    return out


def _optional_int(r: dict, key: str):
    if key not in r or str(r[key]).strip() == "":
        return None
    try:
        return int(r[key])
    except ValueError:
        return None


def _optional_float(r: dict, key: str):
    if key not in r or str(r[key]).strip() == "":
        return None
    try:
        return float(r[key])
    except ValueError:
        return None


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
            "flags": _split_csv(r.get("Flags", "")),
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
            effect_chance = int(r.get("EffectChance", "0") or 0)
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
            "effect_chance": effect_chance,
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


def _species_common_fields(r: dict, tag: str) -> dict:
    """Campos opcionales compartidos por species y forms."""
    row: dict = {}
    if "Types" in r:
        row["types"] = _split_csv(r["Types"])
    if "BaseStats" in r:
        stats = _parse_stats(r["BaseStats"], tag)
        if stats:
            row.update(stats)
    if "EVs" in r:
        row["evs"] = _parse_evs(r["EVs"])
    if "BaseExp" in r:
        row["base_exp"] = int(r.get("BaseExp") or 0)
    if "CatchRate" in r:
        row["catch_rate"] = int(r.get("CatchRate") or 0)
    if "Happiness" in r:
        row["base_happiness"] = int(r.get("Happiness") or 0)
    if "GenderRatio" in r:
        row["gender_ratio"] = r.get("GenderRatio", "")
    if "GrowthRate" in r:
        row["growth_rate"] = r.get("GrowthRate", "")
    if "Abilities" in r:
        row["abilities"] = _split_csv(r["Abilities"])
    if "HiddenAbilities" in r:
        row["hidden_abilities"] = _split_csv(r["HiddenAbilities"])
    if "Moves" in r:
        row["level_moves"] = _parse_level_moves(r["Moves"], tag)
    if "TutorMoves" in r:
        row["tutor_moves"] = _split_csv(r["TutorMoves"])
    if "EggMoves" in r:
        row["egg_moves"] = _split_csv(r["EggMoves"])
    if "EggGroups" in r:
        row["egg_groups"] = _split_csv(r["EggGroups"])
    if "HatchSteps" in r:
        row["hatch_steps"] = int(r.get("HatchSteps") or 0)
    if "Height" in r:
        row["height_m"] = float(r.get("Height") or 0)
    if "Weight" in r:
        row["weight_kg"] = float(r.get("Weight") or 0)
    if "Color" in r:
        row["color"] = r.get("Color", "")
    if "Shape" in r:
        row["shape"] = r.get("Shape", "")
    if "Category" in r:
        row["category"] = r.get("Category", "")
    if "Habitat" in r:
        row["habitat"] = r.get("Habitat", "")
    if "Pokedex" in r:
        row["pokedex"] = r.get("Pokedex", "")
    if "PokedexForm" in r:
        row["pokedex_form"] = r.get("PokedexForm", "")
    if "Generation" in r:
        row["generation"] = int(r.get("Generation") or 0)
    if "Flags" in r:
        row["flags"] = _split_csv(r["Flags"])
    if "WildItemCommon" in r:
        row["wild_item_common"] = r.get("WildItemCommon", "")
    if "WildItemUncommon" in r:
        row["wild_item_uncommon"] = r.get("WildItemUncommon", "")
    if "WildItemRare" in r:
        row["wild_item_rare"] = r.get("WildItemRare", "")
    if "Incense" in r:
        row["incense"] = r.get("Incense", "")
    if "Offspring" in r:
        row["offspring"] = _split_csv(r["Offspring"])
    if "FormName" in r:
        row["form_name"] = r.get("FormName", "")
    if "Evolutions" in r or "Evolution" in r:
        evo_str = r.get("Evolutions", "") or r.get("Evolution", "")
        row["evolutions"] = _parse_evolutions(evo_str, tag)
    if "MegaStone" in r:
        row["mega_stone"] = r.get("MegaStone", "")
    if "MegaName" in r:
        row["mega_name"] = r.get("MegaName", "")
    if "MegaMove" in r:
        row["mega_move"] = r.get("MegaMove", "")
    if "MegaMessage" in r:
        row["mega_message"] = r.get("MegaMessage", "")
    if "UnmegaForm" in r and str(r.get("UnmegaForm", "")).strip() != "":
        row["unmega_form"] = int(r.get("UnmegaForm") or 0)
    return row


def import_species(src: Path, root: Path) -> int:
    label = "species"
    raw = _unique_ids(parse_pbs(src.read_text(encoding="utf-8"), label), label)
    rows: list[dict] = []
    ids: list[str] = []
    missing_evo_key = 0

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
        if "Evolutions" not in r and "Evolution" not in r:
            missing_evo_key += 1

        ids.append(i)
        row = {
            "id": i,
            "name": r.get("Name", i),
            "types": _split_csv(r.get("Types", "")),
            **stats,
            "evs": _parse_evs(r.get("EVs", "")),
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
            "habitat": r.get("Habitat", ""),
            "pokedex": r.get("Pokedex", ""),
            "generation": int(r.get("Generation", "1") or 1),
            "flags": _split_csv(r.get("Flags", "")),
            "wild_item_common": r.get("WildItemCommon", ""),
            "wild_item_uncommon": r.get("WildItemUncommon", ""),
            "wild_item_rare": r.get("WildItemRare", ""),
            "incense": r.get("Incense", ""),
            "offspring": _split_csv(r.get("Offspring", "")),
            "form_name": r.get("FormName", ""),
            "evolutions": _parse_evolutions(r.get("Evolutions", "") or r.get("Evolution", ""), i),
        }
        rows.append(row)
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

    with_evo = sum(1 for row in rows if row["evolutions"])
    multi = sum(1 for row in rows if len(row["evolutions"]) > 1)
    print(f"[{label}] OK: {len(rows)} exportadas ({with_evo} con evoluciones, {multi} con más de una)")
    if with_evo == 0:
        print(
            f"[{label}] AVISO: 0 evoluciones. "
            f"Sin clave Evolutions: {missing_evo_key}/{len(rows)}."
        )
    for row in rows:
        if row["id"] in ("BULBASAUR", "NINCADA", "EEVEE", "WURMPLE", "TYROGUE", "PRIMEAPE"):
            print(f"[{label}] {row['id']} ({len(row['evolutions'])}) = {row['evolutions']}")
    return len(rows)


def import_forms(src: Path, root: Path) -> int:
    label = "forms"
    raw = parse_pbs(src.read_text(encoding="utf-8"), label)
    rows: list[dict] = []
    seen: set[tuple[str, int]] = set()

    for r in raw:
        base_id = r.get("id", "")
        form_idx = int(r.get("form", 0))
        if form_idx <= 0:
            print(f"[{label}] OMITIDA {base_id}: form={form_idx} (solo >0)")
            continue
        if not ID_RE.fullmatch(base_id):
            print(f"[{label}] OMITIDA id inválido: {base_id!r}")
            continue
        key = (base_id, form_idx)
        if key in seen:
            print(f"[{label}] OMITIDA duplicada: {base_id},{form_idx}")
            continue
        seen.add(key)

        tag = f"{base_id}_{form_idx}"
        row: dict = {
            "species": base_id,
            "form": form_idx,
            "form_name": r.get("FormName", ""),
        }
        row.update(_species_common_fields(r, tag))
        # form_name ya está; _species_common lo repite si existe, no pasa nada
        rows.append(row)

    out = root / "Datos/Species/forms.json"
    write_json(rows, out)
    print(f"[{label}] OK: {len(rows)} formas → {out}")
    for row in rows:
        if row["species"] == "VENUSAUR" and row["form"] == 1:
            print(f"[{label}] VENUSAUR,1 = {row.get('form_name')!r} hp={row.get('base_hp')}")
        if row["species"] == "BASCULIN" and row["form"] in (2, 3):
            print(f"[{label}] BASCULIN,{row['form']} = {row.get('evolutions')}")
    return len(rows)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "kind",
        choices=["abilities", "moves", "species", "forms", "all"],
    )
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
            ("pokemon_forms.txt", import_forms),
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
    elif args.kind == "species":
        import_species(path, root)
    else:
        import_forms(path, root)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())