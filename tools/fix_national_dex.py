"""Corrige national_dex +1 en species.json ya generado. Ejecutar desde la raíz del proyecto."""
import json
from pathlib import Path

p = Path("Datos/Pokemon/species.json")
if not p.is_file():
    raise SystemExit(f"No existe {p}")
d = json.loads(p.read_text(encoding="utf-8"))
n = 0
for x in d:
    if x.get("national_dex", 0) > 0:
        x["national_dex"] -= 1
        n += 1
p.write_text(json.dumps(d, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
print(f"Corrigidos {n} national_dex")
print("BULBASAUR =", next(x["national_dex"] for x in d if x["id"] == "BULBASAUR"))
print("MEW =", next(x["national_dex"] for x in d if x["id"] == "MEW"))
