#!/usr/bin/env python3
"""
Refactor sprites (layout pokeemerald) → layout Pokémon Essentials.

Fuente: pokemon_sprites.json
Nombres: Front/SPECIES.png, SPECIES_1.png, SPECIES_female.png, etc.

NO inventa formas copiando vecinas.
--fill-shiny solo copia normal→shiny de la MISMA forma.

Uso:
  python tools/refactor_sprites.py ^
    --src "Graficos/Pokemon" ^
    --out "Graficos/Pokemon_Essentials" ^
    --manifest "Datos/Species/pokemon_sprites.json" ^
    --forms "Datos/Species/forms.json" ^
    --fill-shiny ^
    --report "tools/sprite_restructure_report.txt"
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import sys
from pathlib import Path

KIND_MAP: dict[str, tuple[str, bool]] = {
    "front": ("Front", False),
    "front_shiny": ("Front shiny", False),
    "back": ("Back", False),
    "back_shiny": ("Back shiny", False),
    "icon": ("Icons", False),
    "front_female": ("Front", True),
    "front_female_shiny": ("Front shiny", True),
    "back_female": ("Back", True),
    "back_female_shiny": ("Back shiny", True),
}

FOLDER_TO_SPECIES: dict[str, str] = {
    "nidoran_f": "NIDORANF",
    "nidoran_m": "NIDORANM",
    "mr_mime": "MRMIME",
    "mime_jr": "MIMEJR",
    "type_null": "TYPENULL",
    "jangmo_o": "JANGMOO",
    "hakamo_o": "HAKAMOO",
    "kommo_o": "KOMMOO",
    "tapu_koko": "TAPUKOKO",
    "tapu_lele": "TAPULELE",
    "tapu_bulu": "TAPUBULU",
    "tapu_fini": "TAPUFINI",
    "sirfetchd": "SIRFETCHD",
    "mr_rime": "MRRIME",
    "great_tusk": "GREATTUSK",
    "scream_tail": "SCREAMTAIL",
    "brute_bonnet": "BRUTEBONNET",
    "flutter_mane": "FLUTTERMANE",
    "slither_wing": "SLITHERWING",
    "sandy_shocks": "SANDYSHOCKS",
    "iron_treads": "IRONTREADS",
    "iron_bundle": "IRONBUNDLE",
    "iron_hands": "IRONHANDS",
    "iron_jugulis": "IRONJUGULIS",
    "iron_moth": "IRONMOTH",
    "iron_thorns": "IRONTHORNS",
    "roaring_moon": "ROARINGMOON",
    "iron_valiant": "IRONVALIANT",
    "walking_wake": "WALKINGWAKE",
    "iron_leaves": "IRONLEAVES",
    "gouging_fire": "GOUGINGFIRE",
    "raging_bolt": "RAGINGBOLT",
    "iron_boulder": "IRONBOULDER",
    "iron_crown": "IRONCROWN",
    "wo_chien": "WOCHIEN",
    "chien_pao": "CHIENPAO",
    "ting_lu": "TINGLU",
    "chi_yu": "CHIYU",
    "ho_oh": "HOOH",
    "porygon_z": "PORYGONZ",
    "farfetchd": "FARFETCHD",
    "flabebe": "FLABEBE",
    "question_mark": "QUESTIONMARK",
}

# Mapa manual: arte real en carpeta → número de forma Essentials.
# Gana sobre forms.json cuando este está mal o duplicado.
EXTRA_FORM: dict[tuple[str, str], int] = {
    # Megas / Z
    ("ABSOL", "mega"): 1,
    ("ABSOL", "mega_z"): 2,
    ("GARCHOMP", "mega"): 1,
    ("GARCHOMP", "mega_z"): 2,
    ("LUCARIO", "mega"): 1,
    ("LUCARIO", "mega_z"): 2,
    ("ZYGARDE", "mega"): 4,
    ("FLOETTE", "mega"): 6,
    ("FLOETTE", "yellow"): 1,
    ("GRENINJA", "ash"): 2,
    ("MAGEARNA", "mega"): 2,
    ("MAGEARNA", "original_color"): 1,
    ("MAGEARNA", "original_color/mega"): 3,
    ("TATSUGIRI", "mega"): 3,
    ("TATSUGIRI", "stretchy"): 2,
    ("TATSUGIRI", "stretchy/mega"): 5,
    ("FURFROU", "kabuki"): 8,
    ("FURFROU", "pharaoh"): 9,
    # Gmax
    ("VENUSAUR", "gmax"): 2,
    ("CHARIZARD", "gmax"): 3,
    ("BLASTOISE", "gmax"): 2,
    ("BUTTERFREE", "gmax"): 1,
    ("MEOWTH", "gmax"): 3,
    ("MACHAMP", "gmax"): 1,
    ("GENGAR", "gmax"): 2,
    ("KINGLER", "gmax"): 1,
    ("LAPRAS", "gmax"): 1,
    ("EEVEE", "gmax"): 2,
    ("EEVEE", "partner"): 1,
    ("SNORLAX", "gmax"): 1,
    ("GARBODOR", "gmax"): 1,
    ("MELMETAL", "gmax"): 1,
    ("RILLABOOM", "gmax"): 1,
    ("CINDERACE", "gmax"): 1,
    ("INTELEON", "gmax"): 1,
    ("CORVIKNIGHT", "gmax"): 1,
    ("ORBEETLE", "gmax"): 1,
    ("DREDNAW", "gmax"): 1,
    ("COALOSSAL", "gmax"): 1,
    ("APPLETUN", "gmax"): 1,
    ("FLAPPLE", "gmax"): 1,
    ("SANDACONDA", "gmax"): 1,
    ("CENTISKORCH", "gmax"): 1,
    ("HATTERENE", "gmax"): 1,
    ("GRIMMSNARL", "gmax"): 1,
    ("COPPERAJAH", "gmax"): 1,
    ("DURALUDON", "gmax"): 1,
    ("URSHIFU", "single_strike_gmax"): 2,
    ("URSHIFU", "rapid_strike_gmax"): 3,
    # Pikachu cosplay / gorras (por nombre de carpeta real)
    ("PIKACHU", "partner"): 14,
    ("PIKACHU", "phd"): 5,
    ("PIKACHU", "rock_star"): 7,
    ("PIKACHU", "world"): 15,
    ("PIKACHU", "hoenn"): 9,
    ("PIKACHU", "kalos"): 12,
    # Vivillon (orden típico PE por patrón)
    ("VIVILLON", "polar"): 1,
    ("VIVILLON", "meadow"): 6,
    ("VIVILLON", "modern"): 7,
    ("VIVILLON", "high_plains"): 10,
    ("VIVILLON", "monsoon"): 13,
    ("VIVILLON", "savanna"): 14,
    ("VIVILLON", "ocean"): 16,
    ("VIVILLON", "poke_ball"): 19,
    # Otros
    ("BASCULIN", "blue_striped"): 3,
    ("BASCULIN", "red_striped"): 1,
    ("BASCULIN", "white_striped"): 2,
    ("ZARUDE", "dada"): 1,
    ("ETERNATUS", "eternamax"): 1,
    ("TOXTRICITY", "low_key"): 1,
    ("MINIOR", "core"): 7,
    ("MINIOR", "core/red"): 7,
    ("MINIOR", "core/orange"): 8,
    ("MINIOR", "core/yellow"): 9,
    ("MINIOR", "core/green"): 10,
    ("MINIOR", "core/blue"): 11,
    ("MINIOR", "core/indigo"): 12,
    ("MINIOR", "core/violet"): 13,
    ("MINIOR", "red"): 1,
    ("MINIOR", "orange"): 2,
    ("MINIOR", "yellow"): 3,
    ("MINIOR", "green"): 4,
    ("MINIOR", "blue"): 5,
    ("MINIOR", "indigo"): 6,
    ("QUESTIONMARK", "circled"): 1,
    ("QUESTIONMARK", "double"): 2,
}

TYPE_FORM: dict[str, int] = {
    "fighting": 1,
    "flying": 2,
    "poison": 3,
    "ground": 4,
    "rock": 5,
    "bug": 6,
    "ghost": 7,
    "steel": 8,
    "unknown": 9,
    "qmarks": 9,
    "fire": 10,
    "water": 11,
    "grass": 12,
    "electric": 13,
    "psychic": 14,
    "ice": 15,
    "dragon": 16,
    "dark": 17,
    "fairy": 18,
}

UNOWN_SPECIAL: dict[str, int] = {
    "exclamation": 27,
    "question": 26,
}


def normalize_species_token(folder: str) -> str:
    raw = folder.strip().lower()
    if raw in FOLDER_TO_SPECIES:
        return FOLDER_TO_SPECIES[raw]
    return re.sub(r"[^a-z0-9]", "", raw).upper()


def load_forms_map(path: Path | None) -> dict[str, dict[str, int]]:
    """species -> { sprite_folder: form }. Si hay duplicados, se queda la forma MÁS BAJA."""
    out: dict[str, dict[str, int]] = {}
    if path is None or not path.is_file():
        return out
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, list):
        return out
    for e in data:
        if not isinstance(e, dict):
            continue
        sp = str(e.get("species", "")).strip().upper()
        folder = str(e.get("sprite_folder") or "").strip().replace("\\", "/")
        try:
            form = int(e.get("form", 0))
        except (TypeError, ValueError):
            continue
        if not sp or form <= 0 or not folder:
            continue
        cur = out.setdefault(sp, {})
        if folder not in cur or form < cur[folder]:
            cur[folder] = form
    return out


def resolve_form(
    species: str,
    folder_rel: str,
    forms_map: dict[str, dict[str, int]],
) -> int | None:
    folder_rel = folder_rel.replace("\\", "/").strip("/")
    if not folder_rel:
        return 0

    key = (species, folder_rel)
    if key in EXTRA_FORM:
        return EXTRA_FORM[key]

    if species == "UNOWN":
        if folder_rel in UNOWN_SPECIAL:
            return UNOWN_SPECIAL[folder_rel]
        if len(folder_rel) == 1 and folder_rel.isalpha():
            letter = folder_rel.lower()
            if letter == "a":
                return 0
            return ord(letter) - ord("a")
        return None

    if species in ("ARCEUS", "SILVALLY") and folder_rel in TYPE_FORM:
        return TYPE_FORM[folder_rel]

    sp_map = forms_map.get(species, {})
    if folder_rel in sp_map:
        return sp_map[folder_rel]
    last = folder_rel.split("/")[-1]
    if last in sp_map and "/" not in folder_rel:
        return sp_map[last]

    # Fallbacks seguros por nombre de carpeta
    if folder_rel == "mega":
        return 1
    if folder_rel == "gmax":
        # si el JSON no lo lista, usar 1 (o 2 si ya hay forma 1 en mapa)
        known = set(sp_map.values()) if sp_map else set()
        return 2 if 1 in known else 1

    return None


def essentials_name(species: str, form: int, female: bool) -> str:
    parts = [species]
    if form > 0:
        parts.append(str(form))
    if female:
        parts.append("female")
    return "_".join(parts) + ".png"


def copy_one(src: Path, dest: Path, lines: list[str], dry: bool) -> bool:
    if not src.is_file():
        lines.append(f"MISSING {src}")
        return False
    dest.parent.mkdir(parents=True, exist_ok=True)
    if dest.exists():
        lines.append(f"SKIP exists {dest.as_posix()}")
        return False
    if not dry:
        shutil.copy2(src, dest)
    lines.append(f"OK {src.as_posix()} → {dest.as_posix()}")
    return True


def fill_shiny_gaps(out_root: Path, lines: list[str], dry: bool) -> int:
    n = 0
    for normal, shiny in (("Front", "Front shiny"), ("Back", "Back shiny")):
        src_dir = out_root / normal
        dst_dir = out_root / shiny
        if not src_dir.is_dir():
            continue
        dst_dir.mkdir(parents=True, exist_ok=True)
        for src in src_dir.glob("*.png"):
            dest = dst_dir / src.name
            if dest.exists():
                continue
            if not dry:
                shutil.copy2(src, dest)
            lines.append(f"SHINY {shiny}/{src.name} <= {normal}/{src.name}")
            n += 1
    return n


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--manifest", type=Path, required=True)
    ap.add_argument("--forms", type=Path, default=None)
    ap.add_argument("--report", type=Path, default=None)
    ap.add_argument("--fill-shiny", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    src = args.src.resolve()
    out = args.out.resolve()
    manifest_path = args.manifest.resolve()
    if not src.is_dir():
        print(f"No existe src: {src}", file=sys.stderr)
        return 1
    if not manifest_path.is_file():
        print(f"No existe manifiesto: {manifest_path}", file=sys.stderr)
        return 1

    manifest: dict = json.loads(manifest_path.read_text(encoding="utf-8"))
    forms_map = load_forms_map(args.forms.resolve() if args.forms else None)
    print(f"Manifiesto: {len(manifest)} entradas")
    print(f"Formas en JSON (folder→form, min si dup): {sum(len(v) for v in forms_map.values())}")

    lines: list[str] = []
    ok = skipped_form = omitted_kind = 0

    for key, files in sorted(manifest.items()):
        if not isinstance(files, dict):
            continue
        key = str(key).replace("\\", "/")
        if "/" in key:
            folder, folder_rel = key.split("/", 1)
        else:
            folder, folder_rel = key, ""

        species = normalize_species_token(folder)
        form = resolve_form(species, folder_rel, forms_map)
        if form is None:
            lines.append(f"NO_FORM {key} (species={species})")
            skipped_form += 1
            continue

        for kind, rel_path in files.items():
            if kind in ("recolored_from", "palette_from"):
                continue
            if kind not in KIND_MAP:
                lines.append(f"OMIT kind {key}/{kind}")
                omitted_kind += 1
                continue
            dest_folder, female = KIND_MAP[kind]
            dest_name = essentials_name(species, form, female)
            src_file = src / str(rel_path).replace("\\", "/")
            dest_file = out / dest_folder / dest_name
            if copy_one(src_file, dest_file, lines, args.dry_run):
                ok += 1

    shiny_n = 0
    if args.fill_shiny:
        shiny_n = fill_shiny_gaps(out, lines, args.dry_run)

    report = (args.report or (out / "_export_report.txt")).resolve()
    report.parent.mkdir(parents=True, exist_ok=True)
    report.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(f"Copiados: {ok}")
    print(f"Sin forma mapeada: {skipped_form}")
    print(f"Kinds omitidos (cremas etc.): {omitted_kind}")
    if args.fill_shiny:
        print(f"Shiny rellenados (misma forma): {shiny_n}")
    print(f"Informe: {report}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())