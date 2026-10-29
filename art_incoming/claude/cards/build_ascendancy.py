"""Ascendancy card icons, redrawn by Claude in the same flat style as build_manyworlds.py
(Codex's method: 32px grid, flat shapes, at most six colours plus a 1px dark outline,
exported 4x with nearest-neighbour). Codex's originals stay in art_incoming/cards/."""
from pathlib import Path
import json
import math
import numpy as np
from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent / 'ascendancy'
PAL = {
    'c': '#38d6e8', 'ch': '#b4f6ff', 'cs': '#1b8798',   # cyan (energy, screens)
    'w': '#e8eef2', 'g': '#9aa6b0', 'gs': '#5a6470',   # white and silver (casings)
    'k': '#14161f',
}
CLEAR = (0, 0, 0, 0)

def canvas():
    im = Image.new('RGBA', (32, 32)); return im, ImageDraw.Draw(im)
def rect(d, b, c): d.rectangle(b, fill=PAL[c])
def poly(d, pts, c): d.polygon(pts, fill=PAL[c])
def line(d, pts, c, width=1): d.line(pts, fill=PAL[c], width=width)
def ell(d, b, c): d.ellipse(b, fill=PAL[c])
def px(d, pts, c):
    for p in pts: d.point(p, fill=PAL[c])

def outline(im):
    a = np.array(im); mask = a[:, :, 3] > 0; out = np.zeros(mask.shape, bool)
    for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1)):
        sh = np.zeros_like(mask)
        sh[max(0, dy):min(32, 32 + dy), max(0, dx):min(32, 32 + dx)] = mask[max(0, -dy):min(32, 32 - dy), max(0, -dx):min(32, 32 - dx)]
        out |= sh
    a[out & ~mask] = [20, 22, 31, 255]
    return Image.fromarray(a)

def drone(d, cx, cy, r=7):
    """A round white drone with a cyan eye."""
    ell(d, (cx - r, cy - r, cx + r, cy + r), 'w')
    d.chord((cx - r, cy - r, cx + r, cy + r), 20, 160, fill=PAL['g'])        # shaded underside
    ell(d, (cx - 3, cy - 3, cx + 3, cy + 3), 'cs')
    ell(d, (cx - 2, cy - 2, cx + 2, cy + 2), 'c')
    d.point((cx - 1, cy - 1), fill=PAL['ch'])

def draw(name):
    im, d = canvas()
    if name == 'overclock':
        # a gauge with its needle pushed into the top of the dial
        ell(d, (3, 5, 28, 30), 'gs'); ell(d, (5, 7, 26, 28), 'w')
        d.pieslice((5, 7, 26, 28), 290, 360, fill=PAL['c'])                # the overclock zone, in the red
        for a in range(150, 391, 40):
            r = math.radians(a)
            px(d, [(round(15.5 + 8 * math.cos(r)), round(17.5 + 8 * math.sin(r)))], 'g')
        line(d, [(15, 18), (23, 11)], 'cs', 2)
        ell(d, (13, 16, 18, 21), 'cs')
        rect(d, (13, 1, 18, 4), 'g'); line(d, [(13, 1), (18, 1)], 'w')     # top button
    elif name == 'containment':
        # a hexagonal cyan cage on a silver base
        hexpts = [(16, 2), (27, 8), (27, 21), (16, 27), (5, 21), (5, 8)]
        poly(d, hexpts, 'c')
        poly(d, [(16, 5), (24, 10), (24, 19), (16, 24), (8, 19), (8, 10)], 'cs')
        for x in (11, 16, 21):
            line(d, [(x, 6), (x, 24)], 'ch')
        line(d, [(16, 2), (27, 8)], 'ch'); line(d, [(5, 8), (16, 2)], 'ch')
        rect(d, (6, 26, 26, 29), 'g'); line(d, [(6, 26), (26, 26)], 'w'); line(d, [(6, 29), (26, 29)], 'gs')
    elif name == 'deploy_drone':
        # a drone with rotor arms and a thruster glow, dropping into place
        line(d, [(3, 11), (28, 11)], 'g', 2)
        rect(d, (2, 9, 7, 10), 'gs'); rect(d, (24, 9, 29, 10), 'gs')
        drone(d, 16, 15, 8)
        poly(d, [(13, 23), (19, 23), (17, 26), (15, 26)], 'c'); line(d, [(15, 24), (16, 24)], 'ch')
    elif name == 'issue_protocol':
        # an order sheet with a folded corner, text lines and a cyan seal
        poly(d, [(6, 2), (21, 2), (27, 8), (27, 30), (6, 30)], 'w')
        poly(d, [(21, 2), (27, 8), (21, 8)], 'g')
        line(d, [(6, 30), (27, 30)], 'g'); line(d, [(27, 9), (27, 30)], 'g')
        for y, x1 in ((7, 18), (11, 23), (15, 23), (19, 16)):
            line(d, [(9, y), (x1, y)], 'gs')
        ell(d, (16, 19, 25, 28), 'cs'); ell(d, (17, 20, 24, 27), 'c')
        poly(d, [(18, 24), (20, 22), (23, 25), (20, 25)], 'ch')
    elif name == 'target_lock':
        # crosshair ring, ticks and a bright centre
        ell(d, (5, 5, 26, 26), 'c'); ell(d, (8, 8, 23, 23), CLEAR) if False else d.ellipse((8, 8, 23, 23), fill=CLEAR)
        d.arc((5, 5, 26, 26), 200, 290, fill=PAL['ch'])
        for b in ((14, 1, 17, 9), (14, 22, 17, 30), (1, 14, 9, 17), (22, 14, 30, 17)):
            rect(d, b, 'w')
        ell(d, (13, 13, 18, 18), 'cs'); ell(d, (14, 14, 17, 17), 'ch')
    elif name == 'shield_drone':
        # a cyan shield with a drone eye at its heart
        poly(d, [(5, 4), (27, 4), (27, 17), (23, 24), (16, 29), (9, 24), (5, 17)], 'c')
        poly(d, [(16, 4), (27, 4), (27, 17), (23, 24), (16, 29)], 'cs')
        line(d, [(6, 4), (26, 4)], 'ch'); line(d, [(5, 5), (5, 16)], 'ch')
        drone(d, 16, 15, 6)
    elif name == 'recompile':
        # a circular arrow wrapped around a fresh card
        d.arc((3, 3, 28, 28), 200, 500, fill=PAL['c'], width=3)
        poly(d, [(2, 12), (9, 12), (5, 6)], 'c')                          # arrowhead
        d.arc((3, 3, 28, 28), 210, 300, fill=PAL['ch'])
        rect(d, (11, 9, 20, 22), 'w'); rect(d, (11, 20, 20, 22), 'g')
        line(d, [(13, 12), (18, 12)], 'cs'); line(d, [(13, 15), (18, 15)], 'cs'); line(d, [(13, 18), (16, 18)], 'cs')
    elif name == 'firewall':
        # a wall of glowing cyan blocks on a silver footing
        for row, y in enumerate((5, 11, 17)):
            off = 0 if row % 2 == 0 else 4
            for x in range(3 - off, 29, 8):
                x0, x1 = max(x, 3), min(x + 6, 28)
                if x1 - x0 < 2:
                    continue
                rect(d, (x0, y, x1, y + 4), 'c'); line(d, [(x0, y), (x1, y)], 'ch'); line(d, [(x0, y + 4), (x1, y + 4)], 'cs')
        rect(d, (2, 23, 29, 27), 'g'); line(d, [(2, 23), (29, 23)], 'w'); line(d, [(2, 27), (29, 27)], 'gs')
    elif name == 'data_breach':
        # an open padlock with a crack through its body
        d.arc((8, 2, 22, 16), 180, 360, fill=PAL['g'], width=3)
        rect(d, (8, 8, 10, 13), 'g')                                       # left leg of the shackle, lifted out
        rect(d, (5, 13, 26, 28), 'c'); line(d, [(5, 13), (26, 13)], 'ch'); line(d, [(26, 14), (26, 28)], 'cs')
        line(d, [(17, 13), (15, 18), (18, 21), (15, 27)], 'k', 2)          # the crack
        ell(d, (9, 18, 12, 21), 'cs')                                      # keyhole
        px(d, [(26, 4), (28, 6), (27, 9)], 'ch')                           # sparks off the shackle
    return outline(im)

NAMES = ['overclock', 'containment', 'deploy_drone', 'issue_protocol', 'target_lock', 'shield_drone', 'recompile', 'firewall', 'data_breach']

def main():
    native = OUT / 'source_32'; native.mkdir(parents=True, exist_ok=True); report = {}
    for name in NAMES:
        im = draw(name); a = np.array(im); im.save(native / (name + '.png'))
        im.resize((128, 128), Image.Resampling.NEAREST).save(OUT / (name + '.png'))
        unique = np.unique(a[a[:, :, 3] > 0], axis=0)
        assert 5 <= len(unique) <= 7, (name, len(unique))
        assert set(np.unique(a[:, :, 3])) <= {0, 255}
        report[name] = len(unique)
    # comparison: Codex's version above, this one below
    codex = Path(__file__).resolve().parents[2] / 'cards' / 'source_32'
    sheet = Image.new('RGB', (9 * 104 + 20, 2 * 188 + 20), '#222832'); sd = ImageDraw.Draw(sheet)
    for r, (folder, label) in enumerate(((codex, 'Codex (current)'), (native, 'Claude (redraw)'))):
        y = r * 188 + 30; sd.text((12, y - 22), label, fill='#ebedf0')
        for i, n in enumerate(NAMES):
            im = Image.open(folder / (n + '.png')).convert('RGBA'); x = 12 + i * 104
            big = im.resize((96, 96), Image.Resampling.NEAREST); sheet.paste(big, (x, y), big); sheet.paste(im, (x + 32, y + 104), im)
    sheet.save(OUT / 'compare_ascendancy.png')
    print('9 Ascendancy icons:', report)

if __name__ == '__main__':
    main()
