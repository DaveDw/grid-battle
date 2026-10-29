"""Terran card icons, redrawn by Claude in the flat house style: orange and gunmetal.
Codex's originals stay in art_incoming/cards/."""
from pathlib import Path
from cardkit import Pen, build

OUT = Path(__file__).resolve().parent / 'terran'
CODEX = Path(__file__).resolve().parents[2] / 'cards' / 'source_32'
PAL = {
    'o': '#e8742a', 'h': '#ffb65c', 's': '#a74724',     # orange
    'g': '#66717d', 'l': '#c4ced3', 'd': '#39414e',     # gunmetal
}

def tile(p, x, y, w=22, h=7):
    """A flat ground tile seen from the front: light top edge, dark front face."""
    p.rect((x, y, x + w, y + h), 'g'); p.line([(x, y), (x + w, y)], 'l'); p.rect((x, y + h - 2, x + w, y + h), 'd')

def flag(p, x, y, cloth=10, pole=20):
    p.rect((x, y, x + 1, y + pole), 'l'); p.line([(x + 1, y + 1), (x + 1, y + pole)], 'g')
    p.poly([(x + 2, y + 1), (x + 2 + cloth, y + 1), (x + cloth - 1, y + 5), (x + 2 + cloth, y + 9), (x + 2, y + 9)], 'o')
    p.line([(x + 2, y + 1), (x + 1 + cloth, y + 1)], 'h'); p.line([(x + 2, y + 9), (x + cloth, y + 9)], 's')

def shield(p, x, y, w, h, body='o', hi='h', sh='s'):
    pts = [(x, y), (x + w, y), (x + w, y + h * 6 // 10), (x + w // 2, y + h), (x, y + h * 6 // 10)]
    p.poly(pts, body)
    p.poly([(x + w // 2, y), (x + w, y), (x + w, y + h * 6 // 10), (x + w // 2, y + h)], sh)
    p.line([(x + 1, y), (x + w // 2 - 1, y)], hi); p.line([(x, y + 1), (x, y + h * 6 // 10 - 1)], hi)

def crate(p, x, y, w, h):
    p.rect((x, y, x + w, y + h), 'g'); p.line([(x, y), (x + w, y)], 'l'); p.rect((x + w - 2, y + 1, x + w, y + h), 'd')
    p.line([(x + 2, y + 2), (x + w - 3, y + h - 1)], 'd'); p.line([(x + w - 3, y + 2), (x + 2, y + h - 1)], 'd')

def bag(p, x, y, w=8):
    p.ell((x, y, x + w, y + 5), 'o'); p.line([(x + 2, y), (x + w - 2, y)], 'h'); p.line([(x + 2, y + 5), (x + w - 2, y + 5)], 's')

def draw(name):
    p = Pen(PAL)
    if name == 'fortify':
        tile(p, 4, 22, 24)
        shield(p, 8, 3, 16, 20)
        p.rect((14, 8, 18, 15), 'l'); p.rect((12, 10, 20, 12), 'l')          # emblem
    elif name == 'stake_claim':
        tile(p, 4, 22, 24); flag(p, 10, 2, 12, 21)
    elif name == 'claim':
        for y in (8, 15, 22):
            tile(p, 3, y, 16, 5)
        flag(p, 19, 2, 9, 25)
    elif name == 'sandbags':
        for x, y in ((2, 22), (11, 22), (20, 22), (6, 16), (15, 16), (10, 10)):
            bag(p, x, y, 9)
        p.line([(2, 28), (29, 28)], 'd')
    elif name == 'barrage':
        for x, y in ((4, 3), (13, 9), (22, 3)):
            p.line([(x + 1, y - 3), (x + 1, y - 1)], 'l'); p.line([(x + 4, y - 3), (x + 4, y - 1)], 'l')   # speed lines
            p.rect((x, y, x + 5, y + 10), 'g'); p.line([(x, y), (x, y + 10)], 'l')
            p.rect((x, y + 4, x + 5, y + 5), 'o')
            p.poly([(x, y + 11), (x + 5, y + 11), (x + 3, y + 15), (x + 2, y + 15)], 'o')
        p.poly([(6, 29), (10, 24), (13, 27), (16, 22), (19, 27), (22, 24), (26, 29)], 'h')   # impact flash
    elif name == 'hold_the_line':
        shield(p, 2, 8, 11, 16, 'g', 'l', 'd'); shield(p, 19, 8, 11, 16, 'g', 'l', 'd')
        shield(p, 9, 4, 14, 22)
    elif name == 'requisition':
        crate(p, 5, 18, 22, 11)
        p.rect((11, 4, 20, 16), 'h'); p.rect((11, 14, 20, 16), 'o'); p.line([(13, 7), (18, 7)], 's'); p.line([(13, 10), (17, 10)], 's')
        p.poly([(22, 3), (27, 8), (24, 8), (24, 13), (20, 13), (20, 8)], 'o')        # card rising out
    elif name == 'suppressing_fire':
        for y, x in ((6, 12), (14, 6), (22, 12)):
            p.line([(x - 6, y + 1), (x - 2, y + 1)], 'h')                                    # tracer
            p.rect((x, y, x + 9, y + 3), 'g'); p.line([(x, y), (x + 9, y)], 'l')
            p.poly([(x + 10, y), (x + 14, y + 1), (x + 14, y + 2), (x + 10, y + 3)], 'o')
    elif name == 'supply_drop':
        p.chord((3, 2, 29, 20), 180, 360, 'o'); p.chord((3, 2, 29, 20), 180, 250, 'h'); p.chord((3, 2, 29, 20), 300, 360, 's')
        for a, b in (((4, 11), (11, 21)), ((28, 11), (21, 21)), ((16, 11), (16, 21))):
            p.line([a, b], 'l')
        crate(p, 10, 21, 12, 8)
    elif name == 'dig_in':
        p.poly([(3, 28), (8, 21), (14, 23), (20, 20), (29, 28)], 'g'); p.line([(8, 21), (14, 23), (20, 20)], 'l')
        p.rect((3, 27, 29, 29), 'd')
        p.line([(22, 3), (14, 20)], 'o', 3); p.line([(22, 3), (15, 18)], 'h')         # handle
        p.rect((19, 1, 26, 3), 'o')                                                   # grip
        p.poly([(10, 18), (17, 21), (15, 26), (9, 25)], 'l')                          # blade in the dirt
    return p.finish()

NAMES = ['fortify', 'claim', 'stake_claim', 'sandbags', 'barrage', 'hold_the_line', 'requisition', 'suppressing_fire', 'supply_drop', 'dig_in']

if __name__ == '__main__':
    print('Terran:', build(OUT, NAMES, draw, compare_with=CODEX, label='Claude (redraw)'))
