#!/usr/bin/env python3
"""
Importa datos de pokeemerald-expansion a JSON + enums GDScript.

No descarga el repo. Apunta --src al clon local.

Uso:
  python tools/import_expansion.py ^
    --src "C:/path/pokeemerald-expansion" ^
    --out "C:/Users/ASUS/Desktop/pokemon-eternal-bond" ^
    --sprites "C:/Users/ASUS/Desktop/pokemon-eternal-bond/Graficos/Pokemon"

Genera:
  Scripts/Pokemon/species_id.gd
  Scripts/Moves/move_id.gd
  Scripts/Abilities/ability_id.gd
  Scripts/Item/item_id.gd
  Datos/Pokemon/species.json
  Datos/Moves/moves.json
  Datos/Abilities/abilities.json
  Datos/Items/items.json
  tools/import_expansion_report.txt
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

SKIP_SPECIES = {"NONE", "EGG"}
SKIP_MOVE = {"NONE"}
SKIP_ABILITY = {"NONE"}
SKIP_ITEM = {"NONE"}

GROWTH = {
    "GROWTH_MEDIUM_FAST": "MEDIUM_FAST",
    "GROWTH_ERRATIC": "ERRATIC",
    "GROWTH_FLUCTUATING": "FLUCTUATING",
    "GROWTH_MEDIUM_SLOW": "MEDIUM_SLOW",
    "GROWTH_FAST": "FAST",
    "GROWTH_SLOW": "SLOW",
}

EGG = {
    "EGG_GROUP_NONE": "NONE",
    "EGG_GROUP_MONSTER": "MONSTER",
    "EGG_GROUP_WATER_1": "WATER_1",
    "EGG_GROUP_WATER1": "WATER_1",
    "EGG_GROUP_BUG": "BUG",
    "EGG_GROUP_FLYING": "FLYING",
    "EGG_GROUP_FIELD": "FIELD",
    "EGG_GROUP_FAIRY": "FAIRY",
    "EGG_GROUP_GRASS": "GRASS",
    "EGG_GROUP_PLANT": "GRASS",
    "EGG_GROUP_HUMAN_LIKE": "HUMAN_LIKE",
    "EGG_GROUP_HUMANLIKE": "HUMAN_LIKE",
    "EGG_GROUP_WATER_3": "WATER_3",
    "EGG_GROUP_WATER3": "WATER_3",
    "EGG_GROUP_MINERAL": "MINERAL",
    "EGG_GROUP_AMORPHOUS": "AMORPHOUS",
    "EGG_GROUP_WATER_2": "WATER_2",
    "EGG_GROUP_WATER2": "WATER_2",
    "EGG_GROUP_DITTO": "DITTO",
    "EGG_GROUP_DRAGON": "DRAGON",
    "EGG_GROUP_NO_EGGS": "NO_EGGS",
    "EGG_GROUP_UNDISCOVERED": "NO_EGGS",
}

POCKET = {
    "POCKET_NONE": "NONE",
    "POCKET_ITEMS": "ITEMS",
    "POCKET_MEDICINE": "MEDICINE",
    "POCKET_POKE_BALLS": "BALLS",
    "POCKET_POKEBALLS": "BALLS",
    "POCKET_BALLS": "BALLS",
    "POCKET_BATTLE_ITEMS": "BATTLE",
    "POCKET_BERRIES": "BERRIES",
    "POCKET_KEY_ITEMS": "KEY_ITEMS",
    "POCKET_TM_HM": "TMS",
    "POCKET_TMS": "TMS",
    "POCKET_TM_CASE": "TMS",
}

SPECIES_FLAGS = {
    "SPECIES_FLAG_LEGENDARY": "is_restricted_legendary",
    "SPECIES_FLAG_RESTRICTED_LEGENDARY": "is_restricted_legendary",
    "SPECIES_FLAG_SUB_LEGENDARY": "is_sub_legendary",
    "SPECIES_FLAG_MYTHICAL": "is_mythical",
    "SPECIES_FLAG_ULTRA_BEAST": "is_ultra_beast",
    "SPECIES_FLAG_PARADOX": "is_paradox",
    "SPECIES_FLAG_TOTEM": "is_totem",
    "SPECIES_FLAG_MEGA_EVOLUTION": "is_mega",
    "SPECIES_FLAG_MEGA": "is_mega",
    "SPECIES_FLAG_PRIMAL_REVERSION": "is_primal",
    "SPECIES_FLAG_ULTRA_BURST": "is_ultra_burst",
    "SPECIES_FLAG_GIGANTAMAX": "is_gigantamax",
    "SPECIES_FLAG_TERA_FORM": "is_tera_form",
    "SPECIES_FLAG_ALOLAN_FORM": "is_alolan",
    "SPECIES_FLAG_GALARIAN_FORM": "is_galarian",
    "SPECIES_FLAG_HISUIAN_FORM": "is_hisuian",
    "SPECIES_FLAG_PALDEAN_FORM": "is_paldean",
}

MOVE_BOOLS = {
    "makesContact": "makes_contact",
    "ignoresProtect": "ignores_protect",
    "soundMove": "sound",
    "punchingMove": "punch",
    "bitingMove": "bite",
    "pulseMove": "pulse",
    "ballisticMove": "ballistic",
    "powderMove": "powder",
    "slicingMove": "slicing",
    "windMove": "wind",
    "danceMove": "dance",
    "healingMove": "healing",
    "ignoresSubstitute": "ignores_substitute",
}

ABILITY_BOOLS = {
    "cantBeCopied": "cant_be_copied",
    "cantBeSwapped": "cant_be_swapped",
    "cantBeTraced": "cant_be_traced",
    "cantBeSuppressed": "cant_be_suppressed",
    "cantBeOverwritten": "cant_be_overwritten",
    "breakable": "breakable",
    "failsOnImposter": "fails_on_imposter",
}

FORM_SUFFIXES = (
    "_MEGA_X", "_MEGA_Y", "_MEGA_Z", "_MEGA",
    "_GMAX", "_PRIMAL", "_ORIGIN", "_THERIAN", "_SKY",
    "_ALOLA", "_ALOLAN", "_GALAR", "_GALARIAN",
    "_HISUI", "_HISUIAN", "_PALDEA", "_PALDEAN",
    "_BLOODMOON", "_DADA",
)


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def strip_comments(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return re.sub(r"//.*?$", "", text, flags=re.M)


def parse_enum(text: str, prefix: str) -> tuple[list[str], dict[str, str]]:
    """Ids sin el prefijo, en orden, y alias token -> token canónico."""
    text = strip_comments(text)
    names: list[str] = []
    seen: set[str] = set()
    aliases: dict[str, str] = {}
    m = re.search(r"enum\b.*?\{", text, flags=re.S)
    if not m:
        return names, aliases
    body = text[m.end():]
    depth = 1
    chunk = []
    for ch in body:
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                break
        chunk.append(ch)
    for raw in "".join(chunk).split(","):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        line = line.split("\n")[-1].strip()
        mm = re.match(r"([A-Za-z_][A-Za-z0-9_]*)\s*(?:=\s*([^,]+))?$", line)
        if not mm:
            continue
        full = mm.group(1)
        rhs = (mm.group(2) or "").strip()
        if not full.startswith(prefix):
            continue
        short = full[len(prefix):]
        if not short:
            continue
        if rhs and re.match(r"[A-Za-z_][A-Za-z0-9_]*$", rhs) and rhs.startswith(prefix):
            aliases[short] = rhs[len(prefix):]
            continue
        if short in seen:
            continue
        seen.add(short)
        names.append(short)
    return names, aliases


def iter_blocks(text: str, kind: str) -> list[tuple[str, str]]:
    """[SPECIES_X] = { ... }  kind = SPECIES | MOVE | ABILITY | ITEM."""
    text = strip_comments(text)
    token = kind + "_"
    out: list[tuple[str, str]] = []
    i = 0
    key = "[" + token
    while True:
        a = text.find(key, i)
        if a < 0:
            break
        b = text.find("]", a)
        if b < 0:
            break
        name = text[a + 1:b].strip()
        if not name.startswith(token) or not re.fullmatch(r"[A-Z0-9_]+", name):
            i = b + 1
            continue
        brace = text.find("{", b)
        if brace < 0:
            break
        depth = 0
        j = brace
        in_str = False
        while j < len(text):
            c = text[j]
            if c == '"' and text[j - 1] != "\\":
                in_str = not in_str
            elif not in_str:
                if c == "{":
                    depth += 1
                elif c == "}":
                    depth -= 1
                    if depth == 0:
                        j += 1
                        break
            j += 1
        out.append((name[len(token):], text[brace:j]))
        i = j
    return out


def compound_string(expr: str) -> str:
    """Junta literales. Si hay #else, se queda con la rama #if (la moderna va primero)."""
    if "#else" in expr:
        expr = expr.split("#else", 1)[0]
    parts = re.findall(r'"((?:\\.|[^"\\])*)"', expr)
    text = "".join(parts)
    return text.replace("\\n", "\n").replace("\\'", "'").replace('\\"', '"').strip()


def first_number(expr: str, default: int = 0) -> int:
    expr = expr.strip().rstrip(",")
    m = re.search(r"\?\s*(-?\d+)", expr)
    if m:
        return int(m.group(1))
    m = re.search(r"-?\d+", expr)
    return int(m.group(0)) if m else default


def as_bool(expr: str) -> bool:
    e = expr.strip().rstrip(",")
    if re.search(r"\?\s*TRUE", e):
        return True
    if re.search(r"\?\s*FALSE", e):
        return False
    if "TRUE" in e and "FALSE" not in e:
        return True
    if e == "FALSE":
        return False
    if ">=" in e:
        return True
    return False


def field_map(block: str) -> dict[str, str]:
    fields: dict[str, str] = {}
    i = 0
    while True:
        m = re.search(r"\.([A-Za-z0-9_]+)\s*=", block[i:])
        if not m:
            break
        name = m.group(1)
        start = i + m.end()
        depth_p = depth_b = depth_c = 0
        in_str = False
        j = start
        while j < len(block):
            c = block[j]
            if c == '"' and (j == 0 or block[j - 1] != "\\"):
                in_str = not in_str
            elif not in_str:
                if c == "(":
                    depth_p += 1
                elif c == ")":
                    depth_p -= 1
                elif c == "{":
                    depth_b += 1
                elif c == "}":
                    if depth_p == depth_b == depth_c == 0:
                        break
                    depth_b -= 1
                elif c == "[":
                    depth_c += 1
                elif c == "]":
                    depth_c -= 1
                elif c == "," and depth_p == depth_b == depth_c == 0:
                    break
            j += 1
        fields[name] = block[start:j].strip()
        i = j + 1
    return fields


def ident_list(expr: str, prefix: str) -> list[str]:
    return [t[len(prefix):] for t in re.findall(rf"\b{prefix}[A-Z0-9_]+\b", expr)]


def gender_ratio(expr: str) -> int:
    expr = expr.strip()
    if "MON_GENDERLESS" in expr or "PERCENT_UNKNOWN" in expr:
        return 255
    if "MON_MALE" in expr or "PERCENT_FEMALE(0)" in expr:
        return 0
    if "MON_FEMALE" in expr or "PERCENT_FEMALE(100)" in expr:
        return 254
    m = re.search(r"PERCENT_FEMALE\s*\(\s*([0-9.]+)\s*\)", expr)
    if m:
        pct = float(m.group(1))
        return min(254, int(pct * 255 / 100))
    m = re.search(r"\d+", expr)
    return int(m.group(0)) if m else 127


def parse_evolutions(expr: str) -> list[dict]:
    inner = expr.strip()
    if inner.startswith("EVOLUTION"):
        inner = inner[len("EVOLUTION"):].strip()
    if inner.startswith("(") and inner.endswith(")"):
        inner = inner[1:-1]
    rows: list[dict] = []
    for group in re.findall(r"\{([^{}]*)\}", inner):
        parts = [p.strip() for p in group.split(",") if p.strip()]
        if len(parts) < 3:
            continue
        rows.append({
            "method": parts[0].removeprefix("EVO_"),
            "param": parts[1],
            "target": parts[2].removeprefix("SPECIES_"),
        })
    return rows


def parse_levelups(text: str) -> dict[str, list[dict]]:
    text = strip_comments(text)
    out: dict[str, list[dict]] = {}
    for m in re.finditer(
        r"(s[A-Za-z0-9_]*LevelUpLearnset)\s*\[\]\s*=\s*\{(.*?)\};",
        text,
        flags=re.S,
    ):
        moves = []
        for lv, mv in re.findall(r"LEVEL_UP_MOVE\(\s*(\d+)\s*,\s*MOVE_([A-Z0-9_]+)\s*\)", m.group(2)):
            moves.append({"level": int(lv), "move": mv})
        out[m.group(1)] = moves
    return out


def parse_move_lists(text: str, suffix: str) -> dict[str, list[str]]:
    text = strip_comments(text)
    out: dict[str, list[str]] = {}
    pattern = rf"(s[A-Za-z0-9_]*{suffix})\s*\[\]\s*=\s*\{{(.*?)\}};"
    for m in re.finditer(pattern, text, flags=re.S):
        moves = [
            mv for mv in re.findall(r"\bMOVE_([A-Z0-9_]+)\b", m.group(2))
            if mv not in ("NONE", "UNAVAILABLE")
        ]
        out[m.group(1)] = moves
    return out


def parse_form_tables(text: str) -> dict[str, list[str]]:
    text = strip_comments(text)
    out: dict[str, list[str]] = {}
    for m in re.finditer(
        r"(s[A-Za-z0-9_]*FormSpeciesIdTable)\s*\[\]\s*=\s*\{(.*?)\};",
        text,
        flags=re.S,
    ):
        species = [
            s for s in re.findall(r"\bSPECIES_([A-Z0-9_]+)\b", m.group(2))
            if s not in ("NONE", "EGG")
        ]
        out[m.group(1)] = species
    return out


def sprite_candidates(token: str) -> list[str]:
    t = token.lower()
    cands = [t]

    for suf in FORM_SUFFIXES:
        low = suf.lower()
        if t.endswith(low):
            base = t[: -len(low)]
            form = low[1:]
            aliases = {
                "alola": ["alolan", "alola"],
                "alolan": ["alolan", "alola"],
                "galar": ["galarian", "galar"],
                "galarian": ["galarian", "galar"],
                "hisui": ["hisuian", "hisui"],
                "hisuian": ["hisuian", "hisui"],
                "paldea": ["paldean", "paldea"],
                "paldean": ["paldean", "paldea"],
            }
            for f in aliases.get(form, [form]):
                cands.append(f"{base}/{f}")
            cands.append(base)
            break

    # patrones / colores (fuera del bucle de FORM_SUFFIXES)
    for suf in (
        "_icy_snow", "_polar", "_tundra", "_continental", "_garden",
        "_elegant", "_meadow", "_modern", "_marine", "_archipelago",
        "_high_plains", "_sandstorm", "_river", "_monsoon", "_savanna",
        "_sun", "_ocean", "_jungle", "_fancy", "_pokeball", "_poke_ball",
        "_red", "_yellow", "_orange", "_blue", "_white", "_normal",
    ):
        if t.endswith(suf):
            base = t[: -len(suf)]
            form = suf[1:]
            cands.append(f"{base}/{form}")
            cands.append(base)
            break

    return cands

def resolve_folder(token: str, folders: set[str]) -> str:
    for c in sprite_candidates(token):
        if c in folders:
            return c
    for c in sprite_candidates(token):
        if "/" in c and c.split("/")[0] in folders:
            return c.split("/")[0]
    return ""


def load_front_pic_folders(src: Path) -> dict[str, str]:
    """gMonFrontPic_PikachuHoenn -> pikachu/hoenn."""
    path = src / "src/data/graphics/pokemon.h"
    if not path.is_file():
        print(f"AVISO: no existe {path}")
        return {}
    found: dict[str, str] = {}
    gfx_of: dict[str, str] = {}
    pat = re.compile(
        r'gMonFrontPic_([A-Za-z0-9_]+)\s*\[\s*\]\s*=\s*'
        r'(?:INCGFX_U32|INCBIN_\w+)\(\s*"(graphics/pokemon/[^"]+)"'
    )
    for sym, gfx in pat.findall(read(path)):
        rel = gfx.split("graphics/pokemon/", 1)[1]
        folder = str(Path(rel).parent).replace("\\", "/")
        if folder in ("", "."):
            continue
        prev = gfx_of.get(sym, "")
        if not prev or ("_gba" in prev and "_gba" not in gfx):
            found[sym] = folder
            gfx_of[sym] = gfx
    return found

_FORM_PIC_TAIL = re.compile(
    r"(IcySnow|Polar|Tundra|Continental|Garden|Elegant|Meadow|Modern|Marine|"
    r"Archipelago|HighPlains|Sandstorm|River|Monsoon|Savanna|Sun|Ocean|Jungle|"
    r"Fancy|PokeBall|Red|Yellow|Orange|Blue|White|Normal)$"
)

def folder_from_front_pic(front_expr: str, pic_folders: dict[str, str], disk: set[str]) -> str:
    m = re.search(r"gMonFrontPic_([A-Za-z0-9_]+)", front_expr)
    if not m:
        return ""
    sym = m.group(1)
    for candidate in (sym, _FORM_PIC_TAIL.sub("", sym)):
        if not candidate:
            continue
        folder = pic_folders.get(candidate, "")
        if not folder:
            continue
        if folder in disk:
            return folder
        parent = folder.split("/")[0]
        if parent in disk:
            return parent
    return ""


def collect_folders(root: Path) -> set[str]:
    out: set[str] = set()
    if not root.is_dir():
        return out
    for p in root.rglob("*"):
        if p.is_dir():
            rel = p.relative_to(root).as_posix()
            if rel != ".":
                out.add(rel)
    return out


def write_enum(path: Path, class_name: str, ids: list[str], aliases: dict[str, str], extra: str = "") -> None:
    lines = [
        f"class_name {class_name}",
        "extends Object",
        "## Generado por tools/import_expansion.py. No editar a mano.",
        "",
        "enum Id {",
        "\tNONE = 0,",
    ]
    for name in ids:
        if name == "NONE":
            continue
        lines.append(f"\t{name},")
    lines.append("}")
    lines.append("")
    lines.append("const _TOKEN_TO_ID: Dictionary = {")
    for name in ids:
        if name == "NONE":
            continue
        lines.append(f'\t"{name}": Id.{name},')
    for alias, canon in sorted(aliases.items()):
        if not canon or alias == canon:
            continue
        if canon != "NONE" and canon not in ids:
            continue
        target = "NONE" if canon == "NONE" else canon
        lines.append(f'\t"{alias}": Id.{target},')
    lines.append("}")
    lines.append("")
    if extra:
        lines.append(extra.rstrip())
        lines.append("")
    lines += [
        "static func from_token(token: String) -> Id:",
        '\tvar key: String = token.strip_edges().to_upper().replace("-", "_").replace(" ", "_")',
        "\tif key.is_empty():",
        "\t\treturn Id.NONE",
        "\treturn _TOKEN_TO_ID.get(key, Id.NONE) as Id",
        "",
        "static func to_token(id: Id) -> String:",
        "\tif id == Id.NONE:",
        '\t\treturn ""',
        "\treturn Id.keys()[id]",
        "",
    ]
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines), encoding="utf-8")


def write_json(path: Path, data) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")


def import_moves(src: Path) -> tuple[list[str], dict[str, str], list[dict]]:
    header = src / "include/constants/moves.h"
    info = src / "src/data/moves_info.h"
    ids, aliases = parse_enum(read(header), "MOVE_")
    rows = []
    by_name = {n: b for n, b in iter_blocks(read(info), "MOVE")}
    for name in ids:
        if name in SKIP_MOVE or name not in by_name:
            continue
        f = field_map(by_name[name])
        types = ident_list(f.get("type", ""), "TYPE_")
        cat = f.get("category", "DAMAGE_CATEGORY_STATUS")
        if "PHYSICAL" in cat:
            cat = "PHYSICAL"
        elif "SPECIAL" in cat:
            cat = "SPECIAL"
        else:
            cat = "STATUS"
        row = {
            "id": name,
            "display_name": compound_string(f.get("name", name)),
            "description": compound_string(f.get("description", "")),
            "type": types[0] if types else "NORMAL",
            "category": cat,
            "power": first_number(f.get("power", "0")),
            "accuracy": first_number(f.get("accuracy", "100")),
            "pp": first_number(f.get("pp", "5"), 5),
            "priority": first_number(f.get("priority", "0")),
            "target": f.get("target", "TARGET_SELECTED").strip(),
            "effect": f.get("effect", "EFFECT_HIT").strip(),
            "strike_count": first_number(f.get("strikeCount", "1"), 1),
            "critical_stage": first_number(f.get("criticalHitStage", "0")),
            "recoil": first_number(f.get("recoil", "0")),
            "extra_flags": [],
            "z_effect": "",
        }
        for src_name, dst in MOVE_BOOLS.items():
            if src_name in f:
                row[dst] = as_bool(f[src_name])
        for flag_name in (
            "metronomeBanned", "mirrorMoveBanned", "meFirstBanned",
            "copycatBanned", "assistBanned", "sketchBanned",
        ):
            if flag_name in f and as_bool(f[flag_name]):
                row["extra_flags"].append(flag_name)
        zm = re.search(r"Z_EFFECT_[A-Z0-9_]+", f.get("zMove", ""))
        if zm:
            row["z_effect"] = zm.group(0)
        rows.append(row)
    return ids, aliases, rows


def import_abilities(src: Path) -> tuple[list[str], dict[str, str], list[dict]]:
    header = src / "include/constants/abilities.h"
    info = src / "src/data/abilities.h"
    ids, aliases = parse_enum(read(header), "ABILITY_")
    rows = []
    blocks = {n: b for n, b in iter_blocks(read(info), "ABILITY")}
    for name in ids:
        if name in SKIP_ABILITY or name not in blocks:
            continue
        f = field_map(blocks[name])
        row = {
            "id": name,
            "display_name": compound_string(f.get("name", name)),
            "description": compound_string(f.get("description", "")),
            "ai_rating": first_number(f.get("aiRating", "0")),
        }
        for src_name, dst in ABILITY_BOOLS.items():
            if src_name in f:
                row[dst] = as_bool(f[src_name])
        rows.append(row)
    return ids, aliases, rows


def import_items(src: Path) -> tuple[list[str], dict[str, str], list[dict]]:
    header = src / "include/constants/items.h"
    info = next((
        p for p in (
            src / "src/data/items.h",
            src / "src/data/items/items.h",
        ) if p.is_file()
    ), None)
    ids, aliases = parse_enum(read(header), "ITEM_")
    rows = []
    if info is None:
        return ids, aliases, rows
    blocks = {n: b for n, b in iter_blocks(read(info), "ITEM")}
    for name in ids:
        if name in SKIP_ITEM or name not in blocks:
            continue
        f = field_map(blocks[name])
        pocket_raw = f.get("pocket", "POCKET_ITEMS").strip()
        row = {
            "id": name,
            "display_name": compound_string(f.get("name", name)),
            "description": compound_string(f.get("description", "")),
            "pocket": POCKET.get(pocket_raw, "ITEMS"),
            "price": first_number(f.get("price", "0")),
            "hold_effect": f.get("holdEffect", "").strip().removeprefix("HOLD_EFFECT_"),
            "hold_effect_param": first_number(f.get("holdEffectParam", "0")),
            "field_use": f.get("fieldUseFunc", "").strip(),
            "battle_use": f.get("battleUseFunc", f.get("battleUsage", "")).strip(),
            "sort_type": f.get("type", "").strip(),
            "fling_power": first_number(f.get("flingPower", "0")),
            "important": as_bool(f.get("importance", "FALSE")),
            "tm_move": "",
        }
        tm = re.search(r"\bMOVE_([A-Z0-9_]+)\b", f.get("secondaryId", "") + f.get("tm", ""))
        if tm:
            row["tm_move"] = tm.group(1)
        rows.append(row)
    return ids, aliases, rows


def import_species(src: Path, folders: set[str]) -> tuple[list[str], dict[str, str], list[dict], list[str]]:
    header = src / "include/constants/species.h"
    ids, aliases = parse_enum(read(header), "SPECIES_")
    info_dir = src / "src/data/pokemon/species_info"
    blocks: dict[str, str] = {}
    for path in sorted(info_dir.glob("gen_*_families.h")):
        for name, body in iter_blocks(read(path), "SPECIES"):
            blocks.setdefault(name, body)

    pic_folders = load_front_pic_folders(src)
    print(f"Front pics mapeados: {len(pic_folders)}")

    levelups: dict[str, list[dict]] = {}
    eggs: dict[str, list[str]] = {}
    tutors: dict[str, list[str]] = {}
    forms: dict[str, list[str]] = {}
    data_root = src / "src/data/pokemon"
    for path in data_root.rglob("*.h"):
        text = read(path)
        if "LevelUpLearnset" in text:
            levelups.update(parse_levelups(text))
        if "EggMoveLearnset" in text:
            eggs.update(parse_move_lists(text, "EggMoveLearnset"))
        if "TeachableLearnset" in text:
            tutors.update(parse_move_lists(text, "TeachableLearnset"))
        if "FormSpeciesIdTable" in text:
            forms.update(parse_form_tables(text))

    dex_numbers: dict[str, int] = {}
    dex_header = src / "include/constants/pokedex.h"
    if dex_header.is_file():
        n = 0
        for name in parse_enum(read(dex_header), "NATIONAL_DEX_")[0]:
            n += 1
            dex_numbers[name] = n

    missing_sprite: list[str] = []
    rows = []
    for name in ids:
        if name in SKIP_SPECIES or name not in blocks:
            continue
        f = field_map(blocks[name])
        body = blocks[name]
        types = ident_list(f.get("types", ""), "TYPE_")
        abilities = ident_list(f.get("abilities", ""), "ABILITY_")
        while len(abilities) < 3:
            abilities.append("NONE")
        eggs_g = [EGG.get(g, "NONE") for g in re.findall(r"EGG_GROUP_[A-Z0-9_]+", f.get("eggGroups", ""))]
        growth = GROWTH.get(f.get("growthRate", "").strip(), "MEDIUM_FAST")
        color = f.get("bodyColor", "BODY_COLOR_RED").strip().removeprefix("BODY_COLOR_")
        tera = ident_list(f.get("forceTeraType", ""), "TYPE_")
        folder = folder_from_front_pic(f.get("frontPic", ""), pic_folders, folders)
        if not folder:
            folder = resolve_folder(name, folders)
        if not folder:
            missing_sprite.append(name)

        row = {
            "id": name,
            "display_name": compound_string(f.get("speciesName", name)),
            "category": compound_string(f.get("categoryName", "")),
            "national_dex": dex_numbers.get(
                f.get("natDexNum", "").strip().removeprefix("NATIONAL_DEX_"), 0
            ),
            "pokedex": compound_string(f.get("description", "")),
            "types": types or ["NORMAL"],
            "force_tera_type": tera[0] if tera else "NONE",
            "base_hp": first_number(f.get("baseHP", "1"), 1),
            "base_atk": first_number(f.get("baseAttack", "1"), 1),
            "base_def": first_number(f.get("baseDefense", "1"), 1),
            "base_spe": first_number(f.get("baseSpeed", "1"), 1),
            "base_spa": first_number(f.get("baseSpAttack", "1"), 1),
            "base_spd": first_number(f.get("baseSpDefense", "1"), 1),
            "ev_hp": first_number(f.get("evYield_HP", "0")),
            "ev_atk": first_number(f.get("evYield_Attack", "0")),
            "ev_def": first_number(f.get("evYield_Defense", "0")),
            "ev_spe": first_number(f.get("evYield_Speed", "0")),
            "ev_spa": first_number(f.get("evYield_SpAttack", "0")),
            "ev_spd": first_number(f.get("evYield_SpDefense", "0")),
            "catch_rate": first_number(f.get("catchRate", "45"), 45),
            "base_exp": first_number(f.get("expYield", "0")),
            "base_friendship": 50 if "STANDARD_FRIENDSHIP" in f.get("friendship", "") else first_number(f.get("friendship", "50"), 50),
            "gender_ratio": gender_ratio(f.get("genderRatio", "127")),
            "growth_rate": growth,
            "egg_cycles": first_number(f.get("eggCycles", "20"), 20),
            "egg_groups": eggs_g,
            "abilities": abilities[:3],
            "item_common": f.get("itemCommon", "ITEM_NONE").strip().removeprefix("ITEM_"),
            "item_rare": f.get("itemRare", "ITEM_NONE").strip().removeprefix("ITEM_"),
            "height_dm": first_number(f.get("height", "0")),
            "weight_hg": first_number(f.get("weight", "0")),
            "body_color": color or "RED",
            "no_flip": "noFlip" in f and as_bool(f["noFlip"]),
            "perfect_iv_count": first_number(f.get("perfectIVCount", "0")),
            "cannot_be_traded": False,
            "sprite_folder": folder,
            "level_moves": [],
            "tutor_moves": [],
            "egg_moves": [],
            "evolutions": parse_evolutions(f.get("evolutions", "")),
            "form_species": [],
            "form_changes": [],
        }
        for flag, dest in SPECIES_FLAGS.items():
            row[dest] = flag in body
        row["level_moves"] = levelups.get(f.get("levelUpLearnset", "").strip(), [])
        row["egg_moves"] = eggs.get(f.get("eggMoveLearnset", "").strip(), [])
        row["tutor_moves"] = tutors.get(f.get("teachableLearnset", "").strip(), [])
        row["form_species"] = forms.get(f.get("formSpeciesIdTable", "").strip(), [])
        if row["item_common"] == "NONE":
            row["item_common"] = ""
        if row["item_rare"] == "NONE":
            row["item_rare"] = ""
        rows.append(row)
    return ids, aliases, rows, missing_sprite


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", type=Path, required=True, help="raíz de pokeemerald-expansion")
    ap.add_argument("--out", type=Path, required=True, help="raíz de pokemon-eternal-bond")
    ap.add_argument("--sprites", type=Path, required=True, help="Graficos/Pokemon")
    args = ap.parse_args()
    src: Path = args.src.resolve()
    out: Path = args.out.resolve()
    if not (src / "include/constants/species.h").is_file():
        print(f"No parece pokeemerald-expansion: {src}", file=sys.stderr)
        return 1

    folders = collect_folders(args.sprites.resolve())
    print(f"Carpetas de sprites: {len(folders)}")

    move_ids, move_alias, moves = import_moves(src)
    ability_ids, ability_alias, abilities = import_abilities(src)
    item_ids, item_alias, items = import_items(src)
    species_ids, species_alias, species, missing = import_species(src, folders)

    write_enum(out / "Scripts/Moves/move_id.gd", "MoveId", move_ids, move_alias)
    write_enum(out / "Scripts/Abilities/ability_id.gd", "AbilityId", ability_ids, ability_alias)
    write_enum(out / "Scripts/Item/item_id.gd", "ItemId", item_ids, item_alias)

    extra = ["const _SPRITE_FOLDER: Dictionary = {"]
    for row in species:
        if row["sprite_folder"]:
            extra.append(f'\tId.{row["id"]}: "{row["sprite_folder"]}",')
    extra += [
        "}",
        "",
        "static func sprite_folder(id: Id) -> String:",
        '\treturn str(_SPRITE_FOLDER.get(id, ""))',
    ]
    write_enum(
        out / "Scripts/Pokemon/species_id.gd",
        "SpeciesId",
        species_ids,
        species_alias,
        "\n".join(extra),
    )

    write_json(out / "Datos/Moves/moves.json", moves)
    write_json(out / "Datos/Abilities/abilities.json", abilities)
    write_json(out / "Datos/Items/items.json", items)
    write_json(out / "Datos/Pokemon/species.json", species)

    report = [
        f"moves: {len(moves)} / enum {len(move_ids)}",
        f"abilities: {len(abilities)} / enum {len(ability_ids)}",
        f"items: {len(items)} / enum {len(item_ids)}",
        f"species: {len(species)} / enum {len(species_ids)}",
        f"sin carpeta de sprite: {len(missing)}",
    ]
    for name in missing:
        report.append(f"  - {name}")
    report_path = out / "tools/import_expansion_report.txt"
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text("\n".join(report) + "\n", encoding="utf-8")
    print("\n".join(report[:5]))
    print(f"Informe: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
