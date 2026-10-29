"""The Long Tomorrow card icons (Claude): red-orange and gold, with void purple accents."""
from pathlib import Path
from cardkit import Pen, build, star_points

OUT = Path(__file__).resolve().parent / 'long'
PAL = {
    'r': '#e04a3a', 'rh': '#ff8f6e', 'rs': '#8c2a26',   # red-orange
    'y': '#e8b84a', 'yh': '#ffe39a', 'ys': '#9a7226',   # gold
    'v': '#6e40b8', 'vh': '#a983ea', 'vs': '#3b2170',   # void purple
}

def clock(p, cx, cy, r):
    p.ell((cx - r, cy - r, cx + r, cy + r), 'ys')
    p.ell((cx - r + 2, cy - r + 2, cx + r - 2, cy + r - 2), 'yh')
    for a, b in ((0, -1), (1, 0), (0, 1), (-1, 0)):
        p.px([(cx + a * (r - 4), cy + b * (r - 4))], 'y')
    p.line([(cx, cy), (cx, cy - r + 5)], 'rs'); p.line([(cx, cy), (cx + r - 6, cy)], 'rs')

def draw(name):
    p = Pen(PAL)
    if name == 'borrowed_time':
        # an hourglass whose sand is a heart draining away
        p.rect((7, 2, 24, 4), 'y'); p.rect((7, 27, 24, 29), 'y')
        p.line([(7, 2), (24, 2)], 'yh'); p.line([(7, 29), (24, 29)], 'ys')
        p.poly([(9, 5), (22, 5), (17, 15), (17, 16), (22, 26), (9, 26), (14, 16), (14, 15)], 'yh')
        p.poly([(11, 7), (13, 6), (15, 7), (16, 7), (18, 6), (20, 7), (20, 9), (15.5, 13), (11, 9)], 'r')   # heart
        p.px([(12, 7)], 'rh')
        p.line([(15, 14), (15, 21)], 'r')
        p.poly([(11, 26), (20, 26), (15, 22)], 'r')
        p.line([(9, 5), (14, 15)], 'ys'); p.line([(22, 26), (17, 16)], 'ys')
    elif name == 'rewind':
        # a clock with an arrow curling back around it
        clock(p, 17, 17, 10)
        p.arc((3, 3, 31, 31), 150, 290, 'r', 3)
        p.poly([(2, 18), (8, 18), (5, 24)], 'r')
        p.arc((3, 3, 31, 31), 200, 280, 'rh')
    elif name == 'medpod':
        # a gold med capsule with a red cross, on a purple tether
        p.line([(16, 1), (16, 6)], 'vh', 2)
        p.ell((5, 6, 27, 29), 'ys'); p.ell((6, 6, 26, 27), 'y')
        p.chord((6, 6, 26, 27), 200, 290, 'yh')
        p.rect((14, 10, 18, 23), 'r'); p.rect((10, 14, 22, 18), 'r')
        p.line([(14, 10), (18, 10)], 'rh'); p.line([(10, 14), (13, 14)], 'rh')
    elif name == 'void_orb':
        # a dark purple orb with a gold ring around it
        p.ell((6, 6, 26, 26), 'vs'); p.ell((7, 6, 24, 23), 'v'); p.ell((9, 8, 16, 15), 'vh')
        p.arc((1, 12, 31, 22), 160, 380, 'y', 2)
        p.arc((1, 12, 31, 22), 0, 160, 'ys')
        p.px([(11, 10)], 'yh')
    elif name == 'last_stand':
        # a cracked red shield, still standing, with a gold rim
        pts = [(5, 3), (27, 3), (27, 16), (23, 23), (16, 29), (9, 23), (5, 16)]
        p.poly(pts, 'y')
        p.poly([(7, 5), (25, 5), (25, 16), (22, 22), (16, 27), (10, 22), (7, 16)], 'r')
        p.poly([(16, 5), (25, 5), (25, 16), (22, 22), (16, 27)], 'rs')
        p.line([(8, 6), (14, 6)], 'rh')
        p.line([(17, 5), (14, 11), (18, 16), (15, 22), (16, 27)], None, 2)    # the crack, cut right through
    elif name == 'burn_bright':
        # a flame: red outside, gold inside, bright core
        p.poly([(16, 1), (20, 7), (25, 11), (26, 18), (23, 25), (16, 29), (9, 25), (6, 18), (8, 12), (11, 15), (12, 8)], 'r')
        p.poly([(16, 9), (20, 14), (22, 19), (20, 25), (16, 27), (12, 25), (10, 20), (13, 16)], 'y')
        p.poly([(16, 16), (18, 20), (18, 24), (16, 26), (14, 24), (14, 20)], 'yh')
        p.line([(16, 1), (12, 8)], 'rh'); p.line([(23, 25), (16, 29), (9, 25)], 'rs')
    elif name == 'echo_strike':
        # a gold lightning bolt with its purple echo behind it
        bolt = [(14, 1), (24, 1), (18, 11), (25, 11), (10, 30), (14, 16), (7, 16)]
        p.poly([(x - 4, y + 1) for x, y in bolt], 'v')
        p.poly([(x - 4, y + 1) for x, y in bolt[:2]] + [(x - 4, y + 1) for x, y in bolt[2:3]], 'vh')
        p.poly([(x + 3, y) for x, y in bolt], 'y')
        p.line([(17, 1), (26, 1)], 'yh'); p.line([(21, 11), (28, 11)], 'yh')
        p.line([(13, 30), (28, 11)], 'ys')
    elif name == 'supernova':
        # a bursting star: long gold rays, red flares, white-hot core
        p.poly(star_points(16, 16, 15, 5, 8, -90), 'r')
        p.poly(star_points(16, 16, 12, 5, 4, -90), 'y')
        p.poly(star_points(16, 16, 12, 5, 4, -45), 'y')
        p.ell((11, 11, 21, 21), 'yh')
        p.px([(13, 13), (14, 12)], 'rh')
    elif name == 'flash_forward':
        # a gold arrow dashing forward, leaving purple afterimage chevrons
        for x, c in ((3, 'vs'), (9, 'v')):
            p.poly([(x, 8), (x + 5, 8), (x + 11, 16), (x + 5, 24), (x, 24), (x + 6, 16)], c)
        p.poly([(15, 6), (21, 6), (29, 16), (21, 26), (15, 26), (22, 16)], 'y')
        p.line([(16, 6), (21, 6), (28, 15)], 'yh'); p.line([(21, 26), (28, 17)], 'ys')
    elif name == 'collapse':
        # a falling star with a red trail, about to hit
        p.poly([(30, 1), (20, 21), (10, 12)], 'rs')                # streak, thin at the top
        p.poly([(30, 1), (18, 18), (13, 13)], 'r')
        p.line([(30, 1), (15, 15)], 'rh')
        p.poly(star_points(11, 21, 10, 4, 5, -90), 'y')
        p.poly(star_points(11, 21, 5, 2, 5, -90), 'yh')
        p.line([(3, 29), (20, 29)], 'v', 2)                        # the ground it falls toward
    return p.finish()

NAMES = ['borrowed_time', 'rewind', 'medpod', 'void_orb', 'last_stand', 'burn_bright', 'echo_strike', 'supernova', 'flash_forward', 'collapse']

if __name__ == '__main__':
    print('Long Tomorrow:', build(OUT, NAMES, draw, label='Claude (Long Tomorrow)'))
