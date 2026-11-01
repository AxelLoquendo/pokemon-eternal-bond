#!/usr/bin/env python3
"""PBS items.txt (Essentials / La Base de Sky) → item_id.gd + items.json

Uso:
  python tools/import_items.py "ruta/a/items.txt"
  python tools/import_items.py "ruta/a/items.txt" --root "ruta/proyecto_godot"
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

POCKET_MAP = {
    1: "ITEMS",
    2: "MEDICINE",
    3: "BALLS",
    4: "TMS",
    5: "BERRIES",
    6: "MAIL",
    7: "BATTLE",
    8: "KEY",
}


def parse_pbs(text: str) -> list[dict]:
    text = text.lstrip("\ufeff")
    items: list[dict] = []
    current: dict | None = None
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        m = re.match(r"^\[([A-Z0-9_]+)\]$", line)
        if m:
            if current:
                items.append(current)
            current = {"id": m.group(1)}
            continue
        if current is None or "=" not in line:
            continue
        key, val = line.split("=", 1)
        current[key.strip()] = val.strip()
    if current:
        items.append(current)
    return items


def to_godot_entry(raw: dict) -> dict:
    pocket = int(raw.get("Pocket", "1") or 1)
    price = int(raw.get("Price", "0") or 0)
    sell = raw.get("SellPrice")
    consumable = raw.get("Consumable", "true").lower() != "false"
    flags = [f.strip() for f in raw.get("Flags", "").split(",") if f.strip()]
    return {
        "id": raw["id"],
        "name": raw.get("Name", raw["id"]),
        "name_plural": raw.get("NamePlural", ""),
        "description": raw.get("Description", ""),
        "pocket": POCKET_MAP.get(pocket, "ITEMS"),
        "price": price,
        "sell_price": int(sell) if sell not in (None, "") else max(price // 2, 0),
        "field_use": raw.get("FieldUse", ""),
        "battle_use": raw.get("BattleUse", ""),
        "consumable": consumable,
        "flags": flags,
        "move": raw.get("Move", ""),
    }


def write_enum(items: list[dict], path: Path) -> None:
    lines = [
        "extends Object",
        "class_name ItemId",
        "## Generado por tools/import_items.py — no editar a mano.",
        "",
        "enum Id {",
        "\tNONE = 0,",
        "",
    ]
    for it in items:
        lines.append(f"\t{it['id']},")
    lines += [
        "}",
        "",
        "",
        "static func from_token(token: String) -> Id:",
        "\tvar t: String = token.strip_edges()",
        "\tif t.is_empty():",
        "\t\treturn Id.NONE",
        "\tif t.is_valid_int():",
        "\t\tvar n: int = int(t)",
        "\t\tif n >= 0 and n < Id.size():",
        "\t\t\treturn n as Id",
        "\t\tpush_warning(\"ItemId: id numérico fuera de rango: %s\" % t)",
        "\t\treturn Id.NONE",
        "\tvar upper: String = t.to_upper()",
        "\tif upper.begins_with(\"ITEM_\"):",
        "\t\tupper = upper.substr(5)",
        "\tvar keys: Array = Id.keys()",
        "\tfor i: int in keys.size():",
        "\t\tif str(keys[i]) == upper:",
        "\t\t\treturn i as Id",
        "\tpush_error(\"ItemId: no declarado '%s'. Regenera desde PBS o añade el id.\" % t)",
        "\treturn Id.NONE",
        "",
        "",
        "static func to_key(id: Id) -> String:",
        "\tif id == Id.NONE:",
        "\t\treturn \"\"",
        "\treturn str(Id.keys()[id])",
        "",
    ]
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines), encoding="utf-8")


def write_json(items: list[dict], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(items, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def main() -> int:
    parser = argparse.ArgumentParser(description="Importar items PBS → Godot")
    parser.add_argument("items_txt", type=Path, help="Ruta a PBS/items.txt")
    parser.add_argument(
        "--root",
        type=Path,
        default=None,
        help="Raíz del proyecto Godot (default: padre de tools/)",
    )
    args = parser.parse_args()

    src: Path = args.items_txt
    if not src.is_file():
        print(f"No existe: {src}", file=sys.stderr)
        return 1

    if args.root is not None:
        root = args.root.resolve()
    else:
        # tools/import_items.py → raíz del repo
        root = Path(__file__).resolve().parents[1]

    raw_items = parse_pbs(src.read_text(encoding="utf-8"))
    if not raw_items:
        print("No se encontraron ítems en el PBS.", file=sys.stderr)
        return 1

    entries = [to_godot_entry(r) for r in raw_items]

    out_enum = root / "Scripts" / "Data" / "Items" / "item_id.gd"
    out_json = root / "Datos" / "Items" / "items.json"

    write_enum(entries, out_enum)
    write_json(entries, out_json)

    print(f"OK: {len(entries)} ítems")
    print(f"  → {out_enum}")
    print(f"  → {out_json}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())