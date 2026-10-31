"""Native 32px card-set-2 art. Reuses the existing cardkit outline unchanged.

Run: python -B build_set2.py terran|ascendancy|manyworlds|long|check
All writes are confined to this folder. No game imports or asset installation.
"""
from pathlib import Path
import hashlib
import importlib
import json
import sys

sys.dont_write_bytecode = True
OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[2]
sys.path.insert(0, str(ROOT / "art_incoming/claude/cards"))
from cardkit import Pen, OUTLINE
import numpy as np
from PIL import Image, ImageDraw, ImageFont

FACTIONS = ("terran", "ascendancy", "manyworlds", "long")
LABELS = {"terran": "Terran Partition Authority", "ascendancy": "Ascendancy League",
          "manyworlds": "Manyworlds Resistance", "long": "The Long Tomorrow"}
PALETTES = {
    "terran": dict(o="#e8742a", h="#ffb65c", s="#a74724", g="#66717d", l="#c4ced3", d="#39414e"),
    "ascendancy": dict(c="#38d6e8", h="#b4f6ff", s="#1b8798", w="#e8eef2", g="#9aa6b0", d="#5a6470"),
    "manyworlds": dict(t="#3fbf8a", h="#9cf0c4", s="#217a5a", p="#8a5cd6", ph="#c7a6ff", ps="#553591", m="#8a6440", mh="#b8935e", ms="#523822"),
    "long": dict(r="#e04a3a", h="#ff8f6e", s="#8c2a26", y="#e8b84a", yh="#ffe39a", ys="#9a7226", v="#6e40b8", vh="#a983ea", vs="#3b2170"),
}
for palette in PALETTES.values():
    palette["k"] = "#14161f"


def pen(faction):
    return Pen(PALETTES[faction])


def neighbors(mask):
    out = np.zeros_like(mask)
    out[1:] |= mask[:-1]
    out[:-1] |= mask[1:]
    out[:, 1:] |= mask[:, :-1]
    out[:, :-1] |= mask[:, 1:]
    return out


def inspect_icon(card_id, faction):
    im = Image.open(OUT / "source_32" / f"{card_id}.png").convert("RGBA")
    a = np.array(im)
    visible = a[:, :, 3] == 255
    colors = sorted({"#%02x%02x%02x" % tuple(p[:3]) for p in a[visible]})
    ink = np.all(a == OUTLINE, axis=2)
    body = visible & ~ink
    required_outline = neighbors(body) & ~body
    outline_ok = bool(np.all(ink[required_outline]))
    border_clear = not bool(visible[0].any() or visible[-1].any() or visible[:, 0].any() or visible[:, -1].any())
    export = np.array(Image.open(OUT / f"{card_id}.png").convert("RGBA"))
    nearest_ok = bool(np.array_equal(export, np.repeat(np.repeat(a, 4, axis=0), 4, axis=1)))
    alpha_values = sorted(int(x) for x in np.unique(a[:, :, 3]))
    palette_ok = set(colors) <= set(PALETTES[faction].values())
    result = dict(faction=faction, size=list(im.size), colour_count=len(colors), colours=colors,
                  alpha_values=alpha_values, alpha_only_0_255=alpha_values == [0, 255],
                  palette_valid=palette_ok, outline_1px_valid=outline_ok,
                  border_clear=border_clear, nearest_neighbor_4x=nearest_ok,
                  content_bbox=list(im.getbbox()), sha256=hashlib.sha256(a.tobytes()).hexdigest())
    result["pass"] = (im.size == (32, 32) and 5 <= len(colors) <= 7 and
                      result["alpha_only_0_255"] and palette_ok and outline_ok and border_clear and nearest_ok)
    return result


def modules():
    return [(f, importlib.import_module(f"draw_{f}")) for f in FACTIONS if (OUT / f"draw_{f}.py").exists()]


def validate():
    report = {}
    notes = ["# Card set 2 icon notes", "",
             "Drawn directly at 32 x 32 with the existing cardkit.Pen; 4x exports use nearest-neighbour.",
             "All icons use only their faction palette and #14161f. No borrowed accents.",
             "Sheet labels are outside the icon canvases; the icons contain no text or numbers.", ""]
    for faction, module in modules():
        done = [item for item in module.CARDS if (OUT / "source_32" / f"{item[0]}.png").exists()]
        if not done:
            continue
        notes += [f"## {LABELS[faction]}", ""]
        for card_id, name, meaning in done:
            report[card_id] = inspect_icon(card_id, faction)
            notes.append(f"- `{card_id}` — {meaning}")
        notes.append("")
    assert len({r["sha256"] for r in report.values()}) == len(report), "Duplicate icon"
    existing = []
    for path in (ROOT / "assets/cards").glob("*.png"):
        old = Image.open(path).convert("RGBA").resize((32, 32), Image.Resampling.NEAREST)
        existing.append((path.stem, np.array(old)))
    for card_id, result in report.items():
        pixels = np.array(Image.open(OUT / "source_32" / f"{card_id}.png").convert("RGBA"))
        mask = pixels[:, :, 3] > 0
        result["identical_to_existing"] = [name for name, old in existing if np.array_equal(pixels, old)]
        result["identical_existing_silhouette"] = [name for name, old in existing if np.array_equal(mask, old[:, :, 3] > 0)]
        result["pass"] &= not result["identical_to_existing"] and not result["identical_existing_silhouette"]
    (OUT / "checks.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    (OUT / "notes.md").write_text("\n".join(notes), encoding="utf-8")
    failed = {key: value for key, value in report.items() if not value["pass"]}
    assert not failed, json.dumps(failed, indent=2)
    print(f"PASS: {len(report)} icons; native size, 5-7 colours, exact palettes, binary alpha, 1px outline, 4x exports, uniqueness.")


def sheet(faction, cards):
    im = Image.new("RGB", (960, 420), "#222832")
    d = ImageDraw.Draw(im)
    font = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 17)
    header = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 18)
    d.text((24, 14), LABELS[faction] + " / Card set 2", font=header, fill="#c4ced3")
    for i, (card_id, title, _) in enumerate(cards):
        x = 24 + (i % 5) * 184 + 28
        y = 48 + (i // 5) * 184
        icon = Image.open(OUT / f"{card_id}.png").convert("RGBA")
        im.paste(icon, (x, y), icon)
        d.text((x + 64, y + 144), title, font=font, anchor="mm", fill="#e8eef2")
    im.save(OUT / f"sheet_{faction}.png")


if __name__ == "__main__":
    faction = sys.argv[1]
    if faction == "check":
        validate()
    else:
        assert faction in FACTIONS
        mod = importlib.import_module(f"draw_{faction}")
        (OUT / "source_32").mkdir(exist_ok=True)
        for card_id, _, _ in mod.CARDS:
            native = mod.draw(card_id)
            native.save(OUT / "source_32" / f"{card_id}.png")
            native.resize((128, 128), Image.Resampling.NEAREST).save(OUT / f"{card_id}.png")
        validate()
        sheet(faction, mod.CARDS)
        print(f"Saved sheet_{faction}.png (two rows of five, 4x).")
