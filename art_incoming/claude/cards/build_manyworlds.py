"""Manyworlds card icons (Claude's attempt, following Codex's build_terran.py method):
drawn on a 32px grid from flat shapes, at most six colours plus a 1px dark outline,
exported 4x with nearest-neighbour."""
from pathlib import Path
import json
import numpy as np
from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent
PAL = {
    't': '#3fbf8a', 'th': '#9cf0c4', 'ts': '#217a5a',   # teal-green (water, life)
    'p': '#8a5cd6', 'ph': '#c7a6ff', 'ps': '#553591',   # purple (spores, links)
    'm': '#8a6440', 'mh': '#b8935e', 'ms': '#523822',   # mud
    'k': '#14161f',
}

def canvas():
    im = Image.new('RGBA', (32, 32)); return im, ImageDraw.Draw(im)
def rect(d, b, c): d.rectangle(b, fill=PAL[c])
def poly(d, pts, c): d.polygon(pts, fill=PAL[c])
def line(d, pts, c, width=1): d.line(pts, fill=PAL[c], width=width)
def ell(d, b, c): d.ellipse(b, fill=PAL[c])
def px(d, pts, c):
    for p in pts: d.point(p, fill=PAL[c])

CLEAR = (0, 0, 0, 0)

def wave_layer():
    """A breaking wave on its own 32px layer: a crescent curl breaking to the right,
    foam along the crest, sitting on a band of water. Mirror it to break left."""
    im, d = canvas()
    ell(d, (5, 3, 27, 25), 't')
    d.ellipse((12, 9, 24, 21), fill=CLEAR)          # hollow of the curl
    d.rectangle((19, 13, 31, 31), fill=CLEAR)       # open the curl's mouth
    d.arc((5, 3, 27, 25), 185, 320, fill=PAL['th'], width=2)   # foam on the crest
    d.arc((12, 9, 24, 21), 150, 300, fill=PAL['ts'])            # shade inside the curl
    rect(d, (20, 8, 23, 12), 'th')                  # the lip falling over
    rect(d, (2, 17, 29, 21), 't')                   # water underneath
    line(d, [(2, 17), (12, 17)], 'th'); line(d, [(19, 17), (29, 17)], 'th')
    line(d, [(3, 21), (28, 21)], 'ts')
    return im

def paste_wave(im, flip):
    w = wave_layer()
    if flip:
        w = w.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    im.alpha_composite(w)

def water_lines(d, rows=(5, 11, 17), x0=4, x1=27):
    """The plain water symbol: wavy bands 3px thick, light on top, dark underneath."""
    import math
    for i, y in enumerate(rows):
        for x in range(x0, x1 + 1):
            yy = y + round(2 * math.sin((x + i * 2) / 2.2))
            d.point((x, yy), fill=PAL['th']); d.point((x, yy + 1), fill=PAL['t']); d.point((x, yy + 2), fill=PAL['ts'])

def arrow(d, x, y, left=True, c='p', hc='ph'):
    """A 10-wide arrow; tip at x (left) or x+10 (right)."""
    if left:
        poly(d, [(x, y + 3), (x + 4, y), (x + 4, y + 2), (x + 10, y + 2), (x + 10, y + 4), (x + 4, y + 4), (x + 4, y + 6)], c)
        line(d, [(x + 1, y + 2), (x + 4, y)], hc); line(d, [(x + 4, y + 2), (x + 10, y + 2)], hc)
    else:
        poly(d, [(x + 10, y + 3), (x + 6, y), (x + 6, y + 2), (x, y + 2), (x, y + 4), (x + 6, y + 4), (x + 6, y + 6)], c)
        line(d, [(x, y + 2), (x + 6, y + 2)], hc); line(d, [(x + 6, y), (x + 9, y + 2)], hc)

def mud_puddle(d, x0, y0, x1, y1):
    ell(d, (x0, y0, x1, y1), 'm')
    ell(d, (x0 + 2, y0, x1 - 4, y1 - 3), 'mh')
    line(d, [(x0 + 3, y1 - 1), (x1 - 3, y1 - 1)], 'ms')

def draw(name):
    im, d = canvas()
    if name == 'riptide':
        # a wave breaking toward you, pulling an arrow left
        water_lines(d)
        arrow(d, 6, 24, left=True)
    elif name == 'mire':
        # a flat mud puddle with bubbles domed on its surface
        ell(d, (2, 18, 29, 29), 'ms')
        ell(d, (4, 19, 27, 27), 'm')
        ell(d, (7, 20, 16, 23), 'mh')
        for x0, y0, x1, y1 in ((9, 14, 17, 22), (18, 17, 23, 22)):
            d.chord((x0, y0, x1, y1), 180, 360, fill=PAL['p'])
            d.point((x0 + 2, y0 + 1), fill=PAL['ph'])
        ell(d, (20, 8, 24, 12), 'p'); d.point((21, 9), fill=PAL['ph'])
        ell(d, (14, 5, 16, 7), 'p')
    elif name == 'flood':
        # deep water with a rounded, foamy surface, and an arrow showing it rising
        rect(d, (3, 17, 28, 29), 't')
        for cx in (6, 12, 18, 24):
            ell(d, (cx - 3, 14, cx + 3, 20), 't')
            d.arc((cx - 3, 14, cx + 3, 20), 190, 350, fill=PAL['th'])
        line(d, [(4, 24), (10, 24)], 'th'); line(d, [(15, 26), (24, 26)], 'th')
        line(d, [(3, 29), (28, 29)], 'ts')
        poly(d, [(16, 1), (22, 7), (19, 7), (19, 12), (13, 12), (13, 7), (10, 7)], 'p')
        line(d, [(13, 7), (16, 2)], 'ph')
    elif name == 'spore_bloom':
        # a puffball cap on a short stalk, spores drifting up
        rect(d, (14, 20, 18, 27), 'th'); line(d, [(18, 20), (18, 27)], 'ts')
        poly(d, [(10, 27), (22, 27), (21, 29), (11, 29)], 'ts')
        ell(d, (6, 9, 26, 23), 'p')
        ell(d, (8, 10, 20, 18), 'ph')
        line(d, [(8, 21), (24, 21)], 'ps')
        px(d, [(12, 13), (16, 15), (20, 12)], 'ps')
        for cx, cy in ((7, 5), (13, 3), (20, 4), (25, 7), (16, 7)):
            rect(d, (cx, cy, cx + 1, cy + 1), 't'); d.point((cx, cy), fill=PAL['th'])
    elif name == 'undertow_surge':
        # a wave breaking away from you, pushing an arrow right
        water_lines(d)
        arrow(d, 16, 24, left=False)
    elif name == 'regrowth':
        # a sprout with two leaves out of a mound, with a heal sparkle
        poly(d, [(6, 27), (10, 23), (22, 23), (26, 27)], 'm'); line(d, [(10, 23), (22, 23)], 'mh')
        line(d, [(16, 24), (16, 13)], 'ts', 2)
        poly(d, [(16, 16), (11, 12), (6, 12), (8, 16), (12, 18)], 't'); line(d, [(7, 12), (11, 12)], 'th')
        poly(d, [(17, 13), (21, 8), (27, 7), (25, 12), (20, 15)], 't'); line(d, [(21, 8), (26, 7)], 'th')
        line(d, [(9, 14), (14, 16)], 'ts'); line(d, [(19, 13), (24, 9)], 'ts')
        rect(d, (24, 15, 26, 21), 'p'); rect(d, (22, 17, 28, 19), 'p')
    elif name == 'mudslide':
        # a dark hillside with a tongue of mud sliding down its face into a heap
        poly(d, [(3, 28), (28, 5), (28, 28)], 'ms')
        poly(d, [(9, 22), (25, 7), (28, 7), (28, 12), (16, 22), (12, 26), (4, 27)], 'm')
        line(d, [(10, 21), (25, 7)], 'mh')
        ell(d, (2, 22, 16, 29), 'm'); line(d, [(5, 23), (11, 23)], 'mh')
        # lumps in the flow and purple pebbles tumbling with it (faction accent)
        for x, y in ((19, 13), (23, 10)):
            d.point((x, y), fill=PAL['mh'])
        for x, y in ((21, 10), (14, 18), (8, 25)):
            rect(d, (x, y, x + 1, y + 1), 'p'); d.point((x, y), fill=PAL['ph'])
    elif name == 'mycelial_link':
        # three spore nodes joined by root lines
        line(d, [(9, 22), (16, 8)], 'ts', 2); line(d, [(16, 8), (23, 22)], 'ts', 2); line(d, [(9, 23), (23, 23)], 'ts', 2)
        line(d, [(12, 15), (16, 18), (20, 15)], 't')
        for cx, cy in ((16, 8), (8, 23), (24, 23)):
            ell(d, (cx - 4, cy - 4, cx + 4, cy + 4), 'p')
            ell(d, (cx - 3, cy - 3, cx + 1, cy + 1), 'ph')
            d.point((cx + 2, cy + 2), fill=PAL['ps'])
    elif name == 'tide_pool':
        # a pool with ripples and a heal cross above it
        ell(d, (3, 15, 28, 28), 'ts')
        ell(d, (5, 16, 26, 26), 't')
        ell(d, (10, 18, 21, 24), 'th'); ell(d, (12, 19, 19, 23), 't')
        rect(d, (14, 3, 17, 13), 'p'); rect(d, (11, 6, 20, 9), 'p')
        line(d, [(14, 3), (17, 3)], 'ph'); line(d, [(11, 6), (13, 6)], 'ph')
    # one source pixel of dark outline, no anti-aliasing (same as Codex's build)
    a = np.array(im); mask = a[:, :, 3] > 0; outline = np.zeros(mask.shape, bool)
    for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1)):
        sh = np.zeros_like(mask)
        sh[max(0, dy):min(32, 32 + dy), max(0, dx):min(32, 32 + dx)] = mask[max(0, -dy):min(32, 32 - dy), max(0, -dx):min(32, 32 - dx)]
        outline |= sh
    a[outline & ~mask] = [20, 22, 31, 255]
    return Image.fromarray(a)

NAMES = ['riptide', 'mire', 'flood', 'spore_bloom', 'undertow_surge', 'regrowth', 'mudslide', 'mycelial_link', 'tide_pool']

def main():
    native = OUT / 'source_32'; native.mkdir(exist_ok=True); report = {}
    sheet = Image.new('RGB', (1000, 460), '#222832'); sd = ImageDraw.Draw(sheet)
    for i, name in enumerate(NAMES):
        im = draw(name); a = np.array(im); im.save(native / (name + '.png'))
        large = im.resize((128, 128), Image.Resampling.NEAREST); large.save(OUT / (name + '.png'))
        unique = np.unique(a[a[:, :, 3] > 0], axis=0)
        assert 5 <= len(unique) <= 7, (name, len(unique))
        assert np.array_equal(np.array(Image.open(OUT / (name + '.png'))), np.repeat(np.repeat(a, 4, axis=0), 4, axis=1))
        x = (i % 5) * 200; y = (i // 5) * 230
        for xx, yy, size in ((x + 34, y + 12, 128), (x + 82, y + 153, 32)):
            for cy in range(0, size, 8):
                for cx in range(0, size, 8):
                    sd.rectangle((xx + cx, yy + cy, xx + cx + 7, yy + cy + 7), fill='#303946' if (cy // 8 + cx // 8) % 2 else '#384351')
        sheet.paste(large, (x + 34, y + 12), large); sheet.paste(im, (x + 82, y + 153), im)
        sd.text((x + 100, y + 204), name, fill='#ebedf0', anchor='mm')
        report[name] = {'colours_including_outline': len(unique), 'bbox': im.getbbox()}
    sheet.save(OUT / 'review_manyworlds.png'); (OUT / 'manyworlds_checks.json').write_text(json.dumps(report, indent=2) + '\n')
    print('9 Manyworlds cards built:', {k: v['colours_including_outline'] for k, v in report.items()})

if __name__ == '__main__':
    main()
