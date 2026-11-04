#!/usr/bin/env python3
"""
Exporta sprites de pokeemerald-expansion -> PNG indexados para Godot.

PRINCIPIO CLAVE (así lo hace el juego):
  gbagfx convierte el PNG usando SOLO los índices de cada píxel y el color
  sale de normal.pal / shiny.pal. La paleta embebida en el PNG se ignora
  (front y back suelen traerla distinta o incluso "shiny"). Por eso aquí
  SIEMPRE se pinta por índice: nunca se compara ni se empareja por color.

Reglas:
  - Ignora archivos con '_gba' en el nombre.
  - Frente: anim_front.png si existe; si no, front.png. Primer frame 64x64.
  - Índice 0 = transparente.
  - Paleta normal/shiny: normal.pal/shiny.pal, o (Alcremie) *_default.pal /
    *_shiny.pal, o la del padre si la carpeta no tiene paleta propia.
  - Carpeta sin cuerpo pero con paleta (Arceus, Flabébé): recolorea el
    sprite del padre.
  - Paletas extra (p.ej. berry_ruby_cream.pal) -> front_<nombre>.png y, si
    existe <nombre>_shiny.pal, front_<nombre>_shiny.png.
  - Icon: se copia tal cual (el juego usa 3 paletas globales de icon_palettes,
    la paleta embebida del icon.png ya es la correcta para verlo).
  - Manifiesto JSON + informe TXT.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from PIL import Image

FRAME = 64
TRANSPARENT_INDEX = 0
NUM_COLORS = 16
Color = tuple[int, int, int]


# --------------------------------------------------------------------------
# Paletas
# --------------------------------------------------------------------------
def load_pal(path: Path) -> list[Color]:
    lines = path.read_text(encoding="utf-8", errors="replace").strip().splitlines()
    if len(lines) < 3 or not lines[0].strip().upper().startswith("JASC-PAL"):
        raise ValueError(f"No es JASC-PAL: {path}")
    count = int(lines[2].strip())
    colors: list[Color] = []
    for line in lines[3 : 3 + count]:
        parts = line.split()
        if len(parts) >= 3:
            colors.append((int(parts[0]), int(parts[1]), int(parts[2])))
    return colors


def paint(im: Image.Image, cols: list[Color]) -> Image.Image:
    """Cambia SOLO la paleta; los índices de píxel no se tocan."""
    out = im.copy()
    flat: list[int] = []
    for i in range(NUM_COLORS):  # exactamente 16 -> PNG de 4 bits
        flat.extend(cols[i] if i < len(cols) else (0, 0, 0))
    out.putpalette(flat)
    return out


# --------------------------------------------------------------------------
# Imágenes
# --------------------------------------------------------------------------
def open_indexed(path: Path) -> Image.Image:
    im = Image.open(path)
    im.load()
    if im.mode != "P":
        # convert("P") cuantizaría y destruiría los índices originales.
        raise ValueError(f"{path.name} no es PNG indexado (modo {im.mode})")
    return im


def first_frame(im: Image.Image) -> Image.Image:
    w, h = im.size
    if w >= FRAME and h >= FRAME:
        return im.crop((0, 0, FRAME, FRAME))
    return im.copy()


def save_indexed(path: Path, im: Image.Image) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path, format="PNG", transparency=TRANSPARENT_INDEX)


# --------------------------------------------------------------------------
# Búsqueda de archivos
# --------------------------------------------------------------------------
def skip_name(name: str) -> bool:
    n = name.lower()
    return "_gba" in n or n.startswith("overworld")


def battle_pals(folder: Path) -> list[Path]:
    return sorted(p for p in folder.glob("*.pal") if not skip_name(p.name))


def pick(folder: Path, names: tuple[str, ...]) -> Path | None:
    for n in names:
        p = folder / n
        if p.is_file():
            return p
    return None


def local_sprites(folder: Path) -> dict[str, Path]:
    table = {
        "front": ("anim_front.png", "front.png"),
        "back": ("back.png",),
        "front_female": ("anim_frontf.png", "frontf.png"),
        "back_female": ("backf.png",),
        "icon": ("icon.png",),
    }
    found: dict[str, Path] = {}
    for key, names in table.items():
        p = pick(folder, names)
        if p is not None:
            found[key] = p
    return found


def find_pal_pair(folder: Path) -> tuple[Path | None, Path | None]:
    normal, shiny = folder / "normal.pal", folder / "shiny.pal"
    if normal.is_file() or shiny.is_file():
        return (normal if normal.is_file() else None,
                shiny if shiny.is_file() else None)
    pals = battle_pals(folder)
    defaults = [p for p in pals if p.name.lower().endswith("_default.pal")]
    shinies = [p for p in pals if p.name.lower().endswith("_shiny.pal")]
    if not defaults and not shinies:
        return None, None
    d = defaults[0] if defaults else None
    s = None
    if d is not None:
        prefix = d.name[: -len("_default.pal")]
        s = next((p for p in shinies if p.name == f"{prefix}_shiny.pal"), None)
    if s is None and shinies:
        s = shinies[0]
    return d, s


FEMALE_NAMES = {
    "normal": ("normalf.pal", "normal_female.pal"),
    "shiny": ("shinyf.pal", "shiny_female.pal"),
}


def find_female_pair(*folders: Path) -> tuple[Path | None, Path | None]:
    """normalf.pal / shinyf.pal (o *_female.pal) en la primera carpeta que los tenga."""
    for folder in folders:
        n = pick(folder, FEMALE_NAMES["normal"])
        sh = pick(folder, FEMALE_NAMES["shiny"])
        if n is not None or sh is not None:
            return n, sh
    return None, None


def extra_pals(folder: Path, used: set[Path]) -> list[tuple[Path, Path | None]]:
    """Paletas de variantes + su pareja shiny (<nombre>_shiny.pal)."""
    pals = battle_pals(folder)
    by_name = {p.name.lower(): p for p in pals}
    out: list[tuple[Path, Path | None]] = []
    for p in pals:
        n = p.name.lower()
        if (p in used or n in ("normal.pal", "shiny.pal")
                or n in FEMALE_NAMES["normal"] or n in FEMALE_NAMES["shiny"]):
            continue
        if n.endswith("_shiny.pal") or n.endswith("_default.pal"):
            continue  # las _shiny se toman como pareja de su <nombre>.pal
        shiny = by_name.get(f"{p.stem.lower()}_shiny.pal")
        out.append((p, shiny))
    return out


def ancestor_with_body(folder: Path, root: Path) -> Path | None:
    cur = folder
    while cur != root:
        cur = cur.parent
        s = local_sprites(cur)
        if "front" in s or "back" in s:
            return cur
    return None


def ancestor_with_pal(folder: Path, root: Path):
    cur = folder
    while cur != root:
        cur = cur.parent
        n, s = find_pal_pair(cur)
        if n is not None or s is not None:
            return cur, n, s
    return None, None, None


def find_palette_owner(folder: Path, root: Path, overrides: dict[str, str],
                       avisos: list[str]):
    rel = rel_key(folder, root)
    if rel in overrides:
        owner = root / overrides[rel]
        n, s = find_pal_pair(owner)
        if n is None and s is None:
            raise ValueError(f"--pal-override: {overrides[rel]} no tiene paleta")
        return owner, n, s
    parts = folder.relative_to(root).parts
    if any("mega" in x.lower() for x in parts):
        # 1) un ancestro "mega" con paleta propia (mega/droopy)
        cur = folder
        while cur != root:
            cur = cur.parent
            if cur != root and "mega" in cur.name.lower():
                n, s = find_pal_pair(cur)
                if n is not None or s is not None:
                    return cur, n, s
        # 2) carpeta "mega" hermana/tía con paleta (tatsugiri/mega)
        cur = folder
        while cur != root:
            cur = cur.parent
            cands = [d for d in sorted(cur.iterdir())
                     if d.is_dir() and d != folder and "mega" in d.name.lower()
                     and any(find_pal_pair(d))]
            if not cands:
                continue
            exact = [d for d in cands if d.name.lower() == "mega"]
            pick_ = exact[0] if exact else (cands[0] if len(cands) == 1 else None)
            if pick_ is None:
                avisos.append(f"{rel}: varias paletas mega posibles "
                              f"({', '.join(d.name for d in cands)}); usa --pal-override")
                break
            n, s = find_pal_pair(pick_)
            return pick_, n, s
    return ancestor_with_pal(folder, root)


def rel_key(folder: Path, root: Path) -> str:
    rel = folder.relative_to(root).as_posix()
    return "_root" if rel == "." else rel


# --------------------------------------------------------------------------
# Proceso por carpeta
# --------------------------------------------------------------------------
def process_folder(folder: Path, src_root: Path, out_root: Path, avisos: list[str],
                   overrides: dict[str, str] | None = None):
    overrides = overrides or {}
    rel = rel_key(folder, src_root)
    sprites = local_sprites(folder)
    normal_path, shiny_path = find_pal_pair(folder)
    has_body = "front" in sprites or "back" in sprites
    has_local_pal = normal_path is not None or shiny_path is not None
    palette_from = recolored_from = None
    search_dirs: list[Path] = [folder]

    if not has_body and not has_local_pal and "icon" not in sprites:
        return None

    if has_body and not has_local_pal:
        owner, n, s = find_palette_owner(folder, src_root, overrides, avisos)
        if owner is not None:
            normal_path, shiny_path = n, s
            palette_from = rel_key(owner, src_root)
            search_dirs.append(owner)
            avisos.append(f"{rel}: paleta heredada de {palette_from}")

    if not has_body and has_local_pal:
        owner = ancestor_with_body(folder, src_root)
        if owner is None:
            avisos.append(f"{rel}: paleta sin sprite padre")
        else:
            for key, p in local_sprites(owner).items():
                if key != "icon":
                    sprites[key] = p
            recolored_from = rel_key(owner, src_root)
            search_dirs.append(owner)
            pn, ps = find_pal_pair(owner)
            if normal_path is None:
                normal_path = pn
            if shiny_path is None:
                shiny_path = ps
            avisos.append(f"{rel}: sprite recoloreado desde {recolored_from}")

    if not any(k in sprites for k in ("front", "back", "icon")):
        return None

    dest_dir = out_root / folder.relative_to(src_root)
    entry: dict[str, str] = {}
    if recolored_from:
        entry["recolored_from"] = recolored_from
    if palette_from:
        entry["palette_from"] = palette_from

    normal_cols = load_pal(normal_path) if normal_path else None
    shiny_cols = load_pal(shiny_path) if shiny_path else None
    fn_path, fs_path = find_female_pair(*search_dirs)
    female_normal = load_pal(fn_path) if fn_path else normal_cols
    female_shiny = load_pal(fs_path) if fs_path else shiny_cols
    if (fn_path or fs_path):
        avisos.append(f"{rel}: paleta femenina "
                      f"({fn_path.name if fn_path else 'normal heredada'}, "
                      f"{fs_path.name if fs_path else 'shiny heredada'})")

    def write(src: Path, name: str, cols: list[Color] | None) -> None:
        frame = first_frame(open_indexed(src))
        if cols is not None:
            hi = frame.getextrema()[1]
            if hi >= NUM_COLORS:
                avisos.append(f"{rel}: {name} usa índice {hi} (>15, no cabe en 16 colores)")
            elif hi >= len(cols):
                avisos.append(f"{rel}: {name} usa índice {hi} pero la paleta "
                              f"solo tiene {len(cols)} colores")
            frame = paint(frame, cols)
        path = dest_dir / name
        save_indexed(path, frame)
        entry[name.removesuffix(".png")] = path.relative_to(out_root).as_posix()

    for stem in ("front", "back", "front_female", "back_female"):
        src = sprites.get(stem)
        if src is None:
            continue
        is_f = stem.endswith("_female")
        n_cols = female_normal if is_f else normal_cols
        s_cols = female_shiny if is_f else shiny_cols
        if n_cols is not None:
            write(src, f"{stem}.png", n_cols)
        else:
            write(src, f"{stem}.png", None)
            avisos.append(f"{rel}: {stem} sin paleta normal (paleta embebida)")
        if s_cols is not None:
            write(src, f"{stem}_shiny.png", s_cols)
        else:
            avisos.append(f"{rel}: sin shiny para {stem}")

    # Paletas de variantes (Alcremie, etc.)
    used = {p for p in (normal_path, shiny_path) if p is not None}
    for pal, pal_shiny in extra_pals(folder, used):
        cols = load_pal(pal)
        scols = load_pal(pal_shiny) if pal_shiny else None
        suffix = pal.stem
        if scols is None:
            avisos.append(f"{rel}: {pal.name} sin pareja {pal.stem}_shiny.pal")
        for stem in ("front", "back"):
            src = sprites.get(stem)
            if src is None:
                continue
            write(src, f"{stem}_{suffix}.png", cols)
            if scols is not None:
                write(src, f"{stem}_{suffix}_shiny.png", scols)

    icon = sprites.get("icon")
    if icon is not None and icon.parent == folder:
        im = open_indexed(icon)
        pal = im.getpalette() or []
        emb = [tuple(pal[i * 3 : i * 3 + 3]) for i in range(NUM_COLORS)]
        if im.getextrema()[1] >= NUM_COLORS:
            avisos.append(f"{rel}: icon usa índice >15")
        im = paint(im, emb)
        dest = dest_dir / "icon.png"
        save_indexed(dest, im)
        entry["icon"] = dest.relative_to(out_root).as_posix()

    if not [k for k in entry if k not in ("recolored_from", "palette_from")]:
        return None
    return {"folder": rel, "files": entry}


# --------------------------------------------------------------------------
# Informe
# --------------------------------------------------------------------------
def write_report(report_path: Path, src: Path, out: Path,
                 manifest: dict[str, dict], avisos: list[str]) -> None:
    meta = {"recolored_from", "palette_from"}
    lines = ["=== EXPORT POKEMON SPRITES ===", f"src: {src}", f"out: {out}",
             f"carpetas_exportadas: {len(manifest)}", ""]
    counts: dict[str, int] = {}
    missing = {"front": [], "back": [], "icon": [], "front_shiny": []}
    for key in sorted(manifest):
        files = manifest[key]
        lines.append(f"[{key}]")
        for m in sorted(meta & files.keys()):
            lines.append(f"  {m}: {files[m]}")
        for stem in sorted(k for k in files if k not in meta):
            lines.append(f"  {stem}: {files[stem]}")
            counts[stem] = counts.get(stem, 0) + 1
        for need in ("front", "back", "icon"):
            if need not in files:
                missing[need].append(key)
        if "front" in files and "front_shiny" not in files:
            missing["front_shiny"].append(key)
        lines.append("")
    lines.append("=== RESUMEN POR TIPO ===")
    lines += [f"  {k}: {v}" for k, v in sorted(counts.items())]
    lines += ["", "=== FALTANTES ==="]
    for label, key in (("sin front", "front"), ("sin back", "back"),
                       ("sin icon", "icon"), ("front sin shiny", "front_shiny")):
        lines.append(f"{label}: {len(missing[key])}")
        lines += [f"  - {k}" for k in missing[key]]
    lines += ["", "=== AVISOS ===", f"total: {len(avisos)}"]
    lines += [f"  - {a}" for a in avisos]
    lines += ["", "=== FIN ==="]
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    ap = argparse.ArgumentParser(description="Export sprites pokeemerald -> Godot")
    ap.add_argument("--src", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--manifest", type=Path, required=True)
    ap.add_argument("--report", type=Path, default=None)
    ap.add_argument("--pal-override", action="append", default=[],
                    metavar="CARPETA=DUEÑA",
                    help="fuerza la paleta de una carpeta, p.ej. "
                         "tatsugiri/mega_droopy=tatsugiri/mega (repetible)")
    args = ap.parse_args()
    overrides = dict(x.split("=", 1) for x in args.pal_override)

    src, out = args.src.resolve(), args.out.resolve()
    if not src.is_dir():
        print(f"No existe src: {src}", file=sys.stderr)
        return 1
    out.mkdir(parents=True, exist_ok=True)

    manifest: dict[str, dict] = {}
    avisos: list[str] = []
    folders = sorted({d for d in src.rglob("*") if d.is_dir()} | {src},
                     key=lambda p: p.as_posix())
    for folder in folders:
        try:
            entry = process_folder(folder, src, out, avisos, overrides)
        except Exception as e:  # noqa: BLE001
            msg = f"ERROR {rel_key(folder, src)}: {e}"
            print(f"[{msg}]")
            avisos.append(msg)
            continue
        if entry is None:
            continue
        manifest[entry["folder"]] = entry["files"]
        print(f"[OK] {entry['folder']}")

    args.manifest.parent.mkdir(parents=True, exist_ok=True)
    args.manifest.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
                             encoding="utf-8")
    report_path = (args.report or (out / "_export_report.txt")).resolve()
    write_report(report_path, src, out, manifest, avisos)
    print(f"\nExportadas {len(manifest)} carpetas")
    print(f"Manifiesto: {args.manifest}")
    print(f"Informe:    {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())