"""Bullet sprites, one per unit, drawn by Claude in the card-art house style: flat
shapes, a few colours, a 1px dark outline. 16px canvas, facing right (the game mirrors
them for the enemy side and turns the mortar shell along its arc).
Writes assets/bullets/<faction>/<unit>.png (16px) and a preview sheet here."""
from pathlib import Path
import math
import numpy as np
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
GAME = HERE.parents[2]
S = 16
CLEAR = (0, 0, 0, 0)
OUTLINE = (20, 22, 31, 255)


def hexc(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


class Pen:
    def __init__(self, pal):
        self.pal = {k: hexc(v) for k, v in pal.items()}
        self.im = Image.new('RGBA', (S, S))
        self.d = ImageDraw.Draw(self.im)

    def c(self, name): return CLEAR if name is None else self.pal[name]
    def rect(self, b, c): self.d.rectangle(b, fill=self.c(c))
    def poly(self, pts, c): self.d.polygon(pts, fill=self.c(c))
    def line(self, pts, c, w=1): self.d.line(pts, fill=self.c(c), width=w)
    def ell(self, b, c): self.d.ellipse(b, fill=self.c(c))
    def arc(self, b, a0, a1, c, w=1): self.d.arc(b, a0, a1, fill=self.c(c), width=w)
    def px(self, pts, c):
        for p in pts:
            self.d.point(p, fill=self.c(c))

    def finish(self):
        a = np.array(self.im); mask = a[:, :, 3] > 0; out = np.zeros(mask.shape, bool)
        for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            sh = np.zeros_like(mask)
            sh[max(0, dy):min(S, S + dy), max(0, dx):min(S, S + dx)] = mask[max(0, -dy):min(S, S - dy), max(0, -dx):min(S, S - dx)]
            out |= sh
        a[out & ~mask] = OUTLINE
        return Image.fromarray(a)


TERRAN = {'o': '#e8742a', 'h': '#ffb65c', 'r': '#a74724', 'g': '#66717d', 'l': '#c4ced3', 'd': '#39414e',
          'b': '#d9a441', 'B': '#f6d77f', 's': '#9a6a24'}
ASC = {'c': '#4fd8ff', 'C': '#c8f6ff', 'w': '#f2f6f8', 'g': '#9aa8b4', 'k': '#2a3240', 'r': '#ff3a4a'}
MANY = {'v': '#9a6cff', 'V': '#cdb4ff', 'a': '#3fc4d8', 'A': '#a8f0f4', 'w': '#f4fbff', 'n': '#7cc456',
        'N': '#c4ec8a', 'e': '#3f7a3a', 'm': '#f0a83c', 'M': '#ffd98a', 'k': '#2a2230', 'b': '#3a7ae0', 'B': '#9cc8ff'}
LONG = {'y': '#ffe27a', 'o': '#ff8a2a', 'r': '#e24a3a', 'R': '#8a2420', 't': '#39b3a6', 'T': '#9ee8dc',
        'w': '#f2f2ea', 'p': '#7a4ac8', 'P': '#c8a8ff', 'k': '#140c1e', 'b': '#3a6ae8', 'B': '#a8c8ff', 'g': '#f2cc66'}


def draw(key):
    fac, unit = key.split('/')
    p = Pen({'terran': TERRAN, 'ascendancy': ASC, 'manyworlds': MANY, 'long': LONG}[fac])
    # --- Terran: brass and gunmetal rounds with orange tracers
    if unit == 'banner_marshal':        # officer's pistol round, orange tracer
        p.rect((1, 7, 4, 8), 'o'); p.px([(4, 7)], 'h')
        p.rect((5, 6, 11, 9), 'b'); p.poly([(12, 6), (13, 6), (15, 7), (15, 8), (13, 9), (12, 9)], 'b')
        p.line([(6, 6), (13, 6)], 'B'); p.line([(6, 9), (13, 9)], 's'); p.line([(5, 6), (5, 9)], 's')
    elif unit == 'claim_lord':          # heavy gunmetal slug with an orange claim band
        p.rect((0, 7, 3, 8), 'o')
        p.rect((4, 5, 11, 10), 'g'); p.ell((8, 5, 14, 10), 'g')
        p.rect((8, 5, 9, 10), 'o'); p.line([(4, 5), (12, 5)], 'l'); p.line([(4, 10), (12, 10)], 'd')
        p.px([(12, 6)], 'l')
    elif unit == 'breacher':            # blunt breaching slug, ridged
        p.rect((0, 6, 2, 9), 'o'); p.px([(0, 7), (0, 8)], 'h')
        p.rect((3, 4, 12, 11), 'g'); p.rect((12, 5, 13, 10), 'l')
        p.line([(6, 4), (6, 11)], 'd'); p.line([(9, 4), (9, 11)], 'd'); p.line([(3, 4), (11, 4)], 'l')
    elif unit == 'standard_guard':      # issue rifle round: small, plain, grey tracer
        p.rect((2, 7, 6, 8), 'l'); p.px([(1, 8)], 'g')
        p.rect((7, 7, 11, 8), 'b'); p.poly([(12, 7), (14, 7), (14, 8), (12, 8)], 'b'); p.px([(14, 7)], 'B')
        p.line([(7, 7), (12, 7)], 'B')
    elif unit == 'pathfinder':          # long scout tracer, needle-thin
        p.rect((2, 7, 11, 8), 'o'); p.rect((10, 7, 14, 8), 'h'); p.px([(15, 7), (15, 8)], 'B')
        p.px([(0, 8)], 'r')
    elif unit == 'siege_rig':           # mortar shell: finned, orange band
        p.poly([(1, 4), (5, 6), (5, 9), (1, 11)], 'd')
        p.rect((4, 5, 10, 10), 'g'); p.ell((7, 5, 14, 10), 'g')
        p.rect((7, 5, 8, 10), 'o'); p.line([(4, 5), (11, 5)], 'l'); p.line([(4, 10), (11, 10)], 'd')
    # --- Ascendancy: clean white and cyan light
    elif unit == 'chief_visionary':     # a scout drone's eye
        p.rect((1, 7, 3, 8), 'c')
        p.ell((4, 4, 12, 12), 'w'); p.ell((7, 6, 11, 10), 'c'); p.px([(9, 7)], 'C')
        p.arc((4, 4, 12, 12), 120, 240, 'g')
    elif unit == 'director_zero':       # a black blade shard with the red eye
        p.poly([(1, 7), (8, 4), (15, 7), (15, 8), (8, 11), (1, 8)], 'k')
        p.line([(2, 7), (8, 4), (14, 7)], 'w'); p.rect((8, 7, 9, 8), 'r')
    elif unit == 'synapse_brute':       # plasma orb (scaled by charge)
        p.ell((3, 3, 12, 12), 'c'); p.ell((5, 5, 10, 10), 'C'); p.ell((6, 6, 8, 8), 'w')
        p.px([(2, 5), (13, 10), (12, 2), (1, 10)], 'c')
    elif unit == 'protocol_warden':     # a bracketed packet: [ ■ ]
        for x0, x1 in ((3, 4), (11, 12)):
            p.rect((x0, 4, x1, 11), 'w')
        p.rect((5, 4, 5, 4), 'w'); p.rect((5, 11, 5, 11), 'w'); p.rect((10, 4, 10, 4), 'w'); p.rect((10, 11, 10, 11), 'w')
        p.rect((6, 6, 9, 9), 'c'); p.px([(6, 6), (7, 6)], 'C')
    elif unit == 'field_scholar':       # data dart trailing scan dashes
        p.px([(0, 7), (1, 7), (3, 8), (4, 8)], 'c')
        p.poly([(6, 7), (10, 4), (15, 7), (15, 8), (10, 11), (6, 8)], 'c')
        p.line([(8, 7), (13, 7)], 'C'); p.px([(10, 5)], 'w')
    elif unit == 'courtesy_android':    # a polite round pellet
        p.ell((5, 5, 11, 10), 'w'); p.line([(8, 5), (8, 10)], 'c'); p.px([(6, 6)], 'C'); p.px([(3, 8)], 'g')
    # --- Manyworlds: water, crystal, spores, chitin
    elif unit == 'tide_speaker':        # an ink-and-water droplet
        p.poly([(1, 7), (9, 4), (9, 11)], 'a'); p.ell((6, 4, 14, 11), 'a')
        p.ell((9, 6, 12, 9), 'v'); p.px([(11, 5)], 'w'); p.px([(3, 7)], 'A')
    elif unit == 'reef_bulwark':        # a curling wave (Undertow)
        p.poly([(1, 12), (3, 8), (7, 5), (11, 4), (14, 5), (15, 8), (13, 9), (12, 7), (10, 7), (9, 9), (9, 12)], 'b')
        p.line([(3, 8), (7, 5), (11, 4), (14, 5), (15, 7)], 'w'); p.px([(12, 7), (13, 8)], 'B')
        p.rect((2, 11, 8, 12), 'B')
    elif unit == 'reed_runner':         # a fletched thorn dart
        p.poly([(1, 5), (5, 7), (1, 7)], 'N'); p.poly([(1, 10), (5, 8), (1, 8)], 'N')
        p.rect((3, 7, 11, 8), 'e'); p.poly([(11, 6), (15, 7), (15, 8), (11, 9)], 'n'); p.px([(13, 7)], 'N')
    elif unit == 'prism_elder':         # an amber shard with a cyan heart
        p.poly([(1, 8), (7, 3), (15, 7), (15, 8), (7, 12)], 'm')
        p.poly([(7, 3), (15, 7), (7, 8)], 'M'); p.rect((7, 7, 9, 8), 'a'); p.px([(8, 7)], 'w')
    elif unit == 'spore_keeper':        # a spore glob, dripping
        p.px([(1, 9), (2, 8)], 'n')
        p.ell((4, 4, 12, 12), 'n'); p.ell((5, 5, 9, 8), 'N')
        p.px([(7, 9), (10, 7), (9, 10)], 'v'); p.px([(6, 6)], 'w')
    elif unit == 'glasswing':           # a striped stinger
        p.poly([(1, 5), (9, 6), (15, 8), (9, 9), (1, 10)], 'm')
        p.line([(4, 5), (4, 10)], 'k'); p.line([(7, 6), (7, 9)], 'k'); p.px([(14, 8), (15, 8)], 'w')
        p.px([(2, 6)], 'M')
    # --- The Long Tomorrow: embers, decay and the void
    elif unit == 'mission_mother':      # a medic's dart
        p.rect((1, 7, 2, 8), 'g'); p.rect((3, 6, 9, 9), 'w'); p.rect((4, 7, 8, 8), 't'); p.px([(5, 7)], 'T')
        p.rect((10, 7, 10, 8), 'g'); p.line([(11, 7), (15, 7)], 'w')
    elif unit == 'red_giant':           # a molten slug, glowing
        p.rect((1, 7, 4, 8), 'R'); p.px([(0, 8)], 'R')
        p.ell((4, 4, 13, 11), 'r'); p.ell((6, 6, 12, 9), 'o'); p.rect((9, 7, 10, 8), 'y')
    elif unit == 'cinder_scout':        # an ember fireball
        p.poly([(1, 5), (8, 6), (5, 8)], 'r'); p.poly([(1, 11), (8, 9), (5, 8)], 'r')
        p.poly([(2, 8), (9, 4), (9, 12)], 'o'); p.ell((7, 4, 14, 11), 'o'); p.ell((9, 6, 13, 9), 'y')
        p.px([(12, 7)], 'w')
    elif unit == 'captain_everafter':   # a scythe's crescent
        p.ell((2, 1, 15, 14), 'p'); p.ell((-1, 3, 10, 12), None)
        p.arc((3, 1, 15, 14), 300, 60, 'P'); p.px([(14, 7), (14, 8)], 'g')
    elif unit == 'deadweight':          # a void orb in a gravity ring
        p.arc((1, 6, 15, 11), 180, 360, 'P')
        p.ell((4, 3, 12, 12), 'p'); p.ell((5, 4, 11, 11), 'k'); p.px([(6, 5), (7, 5)], 'P')
        p.arc((1, 6, 15, 11), 0, 180, 'P')
    elif unit == 'parallax':            # a star mote and its afterimage
        pts = lambda cx, cy, ro, ri: [(round(cx + (ro if i % 2 == 0 else ri) * math.cos(math.radians(-90 + i * 36))),
                                       round(cy + (ro if i % 2 == 0 else ri) * math.sin(math.radians(-90 + i * 36)))) for i in range(10)]
        p.poly(pts(4, 8, 3, 1), 'b')
        p.poly(pts(10, 8, 5, 2), 'B'); p.px([(10, 8)], 'w'); p.px([(10, 7)], 'w')
    else:
        raise KeyError(key)
    return p.finish()


UNITS = ['terran/banner_marshal', 'terran/siege_rig', 'terran/pathfinder', 'terran/claim_lord', 'terran/breacher', 'terran/standard_guard',
         'ascendancy/chief_visionary', 'ascendancy/synapse_brute', 'ascendancy/field_scholar', 'ascendancy/director_zero', 'ascendancy/protocol_warden', 'ascendancy/courtesy_android',
         'manyworlds/tide_speaker', 'manyworlds/reef_bulwark', 'manyworlds/reed_runner', 'manyworlds/prism_elder', 'manyworlds/spore_keeper', 'manyworlds/glasswing',
         'long/mission_mother', 'long/red_giant', 'long/cinder_scout', 'long/captain_everafter', 'long/deadweight', 'long/parallax']

if __name__ == '__main__':
    sheet = Image.new('RGB', (6 * 120 + 20, 4 * 120 + 20), '#141a28'); sd = ImageDraw.Draw(sheet)
    for i, key in enumerate(UNITS):
        im = draw(key)
        a = np.array(im)
        assert set(np.unique(a[:, :, 3])) <= {0, 255}, key
        out = GAME / 'assets' / 'bullets' / (key + '.png'); out.parent.mkdir(parents=True, exist_ok=True)
        im.save(out)
        x, y = 10 + (i % 6) * 120, 10 + (i // 6) * 120
        big = im.resize((96, 96), Image.Resampling.NEAREST); sheet.paste(big, (x + 12, y), big)
        sheet.paste(im.resize((32, 32), Image.Resampling.NEAREST), (x + 44, y + 92), im.resize((32, 32), Image.Resampling.NEAREST))
        sd.text((x + 60, y + 88), key.split('/')[1][:16], fill='#9aa4b4', anchor='mm')
    sheet.save(HERE / 'bullets_sheet.png')
    print('wrote', len(UNITS), 'bullets')
