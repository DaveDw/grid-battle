"""Terran set 2: native pixel geometry, orange and gunmetal."""
from build_set2 import pen

CARDS = [
    ("quick_march", "Quick March", "A marching boot with orange cuff and forward pace marks."),
    ("field_repairs", "Field Repairs", "An open-jaw field wrench with an orange insulated grip."),
    ("spotter_flare", "Spotter Flare", "An orange-gripped flare pistol launching a bright orange signal burst."),
    ("razor_wire", "Razor Wire", "A silver wire coil with sharp barbs between orange stakes."),
    ("creeping_barrage", "Creeping Barrage", "Three orange impact bursts stepping down a narrow column track."),
    ("overwatch", "Overwatch", "Orange-capped binoculars with two bright watchful lenses."),
    ("smoke_screen", "Smoke Screen", "A gunmetal smoke cloud billowing from an orange smoke canister."),
    ("volley_fire", "Volley Fire", "Three fanned gun barrels firing together from one mount."),
    ("annex", "Annex", "An orange territory plate pinned onto adjoining gunmetal ground by a silver fastener."),
    ("orbital_strike", "Orbital Strike", "A small orbital emitter with solar panels and a precise orange strike beam."),
]


def draw(name):
    p = pen("terran")
    if name == "quick_march":
        p.poly([(12, 9), (21, 9), (21, 19), (27, 21), (28, 26), (10, 26), (9, 22), (12, 19)], "g")
        p.poly([(20, 10), (21, 10), (21, 19), (27, 21), (28, 26), (10, 26), (10, 24), (24, 24), (24, 22), (19, 20)], "d")
        p.line([(12, 10), (12, 19), (10, 22)], "l")
        p.rect((12, 6, 21, 11), "o"); p.line([(12, 6), (21, 6)], "h"); p.line([(13, 11), (21, 11)], "s")
        p.line([(15, 14), (19, 14)], "l"); p.line([(15, 17), (19, 17)], "l")
        for x, y in ((3, 5), (3, 14)):
            p.poly([(x, y), (x + 4, y + 3), (x, y + 6), (x, y + 4), (x + 2, y + 3), (x, y + 2)], "o")
            p.px([(x, y), (x + 1, y + 1)], "h")
    elif name == "field_repairs":
        p.poly([(19, 3), (24, 3), (20, 8), (24, 12), (29, 8), (28, 14), (24, 17), (20, 16), (10, 27), (5, 27), (3, 24), (4, 21), (17, 11), (16, 7)], "g")
        p.line([(19, 3), (24, 3), (20, 8)], "l"); p.line([(17, 7), (17, 11), (5, 22)], "l")
        p.line([(28, 12), (26, 15), (22, 16), (9, 27), (5, 27)], "d")
        p.poly([(13, 15), (17, 19), (10, 26), (6, 26), (4, 24), (5, 22)], "o")
        p.line([(5, 22), (13, 16)], "h"); p.line([(8, 26), (16, 19)], "s")
        p.ell((6, 22, 8, 24), "d")
    elif name == "spotter_flare":
        p.poly([(4, 16), (16, 10), (20, 16), (11, 21), (9, 28), (3, 26), (6, 20)], "g")
        p.line([(4, 16), (16, 10)], "l"); p.line([(20, 16), (11, 21)], "d", 2)
        p.poly([(6, 20), (11, 21), (9, 28), (3, 26)], "o")
        p.line([(6, 20), (4, 25)], "h"); p.line([(9, 22), (8, 27)], "s")
        p.line([(12, 22), (15, 22), (16, 19)], "d")
        p.line([(16, 11), (19, 15)], "d")
        p.poly([(25, 2), (26, 6), (29, 7), (26, 9), (25, 12), (23, 9), (20, 7), (24, 6)], "o")
        p.line([(25, 4), (25, 8)], "h"); p.line([(23, 7), (26, 7)], "h")
    elif name == "razor_wire":
        for x in (4, 26):
            p.rect((x, 10, x + 1, 27), "o"); p.line([(x, 10), (x, 25)], "h"); p.px([(x + 1, 27)], "s")
        for x in (7, 14, 21):
            p.ell((x - 3, 10, x + 4, 23), "g"); p.ell((x - 1, 12, x + 2, 21), None)
            p.arc((x - 3, 10, x + 4, 23), 170, 285, "l")
            p.arc((x - 3, 10, x + 4, 23), 0, 90, "d")
        p.line([(3, 20), (28, 15)], "l")
        for x, y in ((9, 18), (17, 17), (24, 15)):
            p.line([(x - 1, y - 3), (x + 1, y + 3)], "g")
            p.px([(x - 1, y - 3)], "l")
    elif name == "creeping_barrage":
        p.rect((13, 3, 19, 28), "d"); p.line([(13, 3), (13, 27)], "l")
        for y in (6, 14, 22):
            p.rect((14, y, 19, y + 2), "g")
        for x, y in ((19, 5), (15, 14), (19, 23)):
            p.poly([(x, y - 3), (x + 1, y), (x + 4, y - 1), (x + 2, y + 2), (x + 3, y + 4), (x, y + 3), (x - 3, y + 4), (x - 2, y + 1), (x - 4, y - 1), (x - 1, y)], "o")
            p.line([(x - 2, y), (x, y + 2)], "h"); p.line([(x, y + 3), (x + 2, y + 3)], "s")
        p.poly([(4, 10), (6, 10), (6, 22), (9, 22), (5, 27), (2, 22), (4, 22)], "g")
        p.line([(4, 11), (4, 21)], "l")
    elif name == "overwatch":
        p.rect((12, 10, 19, 16), "g"); p.line([(12, 10), (19, 10)], "l")
        for x in (4, 19):
            p.poly([(x + 2, 5), (x + 6, 5), (x + 9, 17), (x - 1, 17)], "o")
            p.line([(x + 2, 5), (x + 6, 5)], "h"); p.line([(x + 6, 7), (x + 8, 15)], "s")
            p.ell((x - 2, 14, x + 10, 26), "d"); p.ell((x, 16, x + 8, 24), "g")
            p.arc((x, 16, x + 8, 24), 180, 280, "l", 2)
            p.ell((x + 3, 19, x + 6, 22), "d")
    elif name == "smoke_screen":
        p.ell((3, 5, 16, 17), "g"); p.ell((11, 2, 26, 17), "g"); p.ell((18, 8, 29, 20), "g")
        p.poly([(11, 14), (23, 15), (21, 20), (17, 23), (13, 22), (16, 19)], "g")
        p.arc((3, 5, 16, 17), 175, 275, "l"); p.arc((11, 2, 26, 17), 190, 280, "l")
        p.line([(27, 16), (24, 19), (20, 19), (17, 22)], "d", 2)
        p.poly([(8, 21), (14, 19), (18, 26), (11, 29)], "o")
        p.line([(8, 21), (14, 19)], "h"); p.line([(11, 29), (18, 26)], "s")
        p.line([(10, 20), (14, 19)], "d")
    elif name == "volley_fire":
        p.poly([(11, 24), (21, 24), (24, 28), (8, 28)], "d")
        p.line([(11, 24), (21, 24)], "l")
        for pts in ([(9, 22), (5, 13), (9, 11), (14, 21)], [(14, 21), (14, 9), (18, 9), (18, 21)], [(19, 21), (23, 11), (27, 13), (23, 22)]):
            p.poly(pts, "g"); p.line(pts[:2], "l"); p.line(pts[2:], "d")
        for x, y in ((6, 8), (16, 4), (26, 8)):
            p.poly([(x, y - 2), (x + 1, y), (x + 3, y), (x + 1, y + 2), (x + 1, y + 4), (x - 1, y + 4), (x - 1, y + 2), (x - 3, y), (x - 1, y)], "o")
            p.line([(x, y), (x, y + 2)], "h"); p.px([(x + 1, y + 3)], "s")
    elif name == "annex":
        p.rect((3, 17, 26, 28), "g"); p.line([(3, 17), (25, 17)], "l")
        p.rect((3, 26, 26, 28), "d"); p.line([(10, 18), (10, 25)], "d")
        p.rect((12, 11, 28, 24), "o"); p.line([(12, 11), (27, 11)], "h")
        p.line([(28, 12), (28, 24), (12, 24)], "s", 2)
        p.line([(13, 12), (13, 21)], "h")
        p.line([(19, 8), (16, 19)], "k", 5)
        p.line([(19, 8), (16, 19)], "g", 3); p.line([(18, 9), (15, 18)], "l")
        p.poly([(14, 3), (24, 6), (23, 10), (13, 7)], "g")
        p.line([(14, 3), (24, 6)], "l"); p.line([(13, 7), (23, 10)], "d")
    elif name == "orbital_strike":
        p.poly([(3, 5), (8, 2), (12, 8), (7, 11)], "g")
        p.poly([(14, 12), (19, 9), (23, 15), (18, 18)], "g")
        p.line([(3, 5), (8, 2), (11, 7)], "l"); p.line([(14, 12), (19, 9)], "l")
        p.line([(7, 5), (10, 9)], "d"); p.line([(18, 12), (21, 16)], "d")
        p.poly([(8, 11), (12, 7), (16, 11), (12, 15)], "o")
        p.line([(8, 11), (12, 7)], "h"); p.line([(12, 15), (16, 11)], "s")
        p.line([(14, 15), (24, 25)], "o", 3); p.line([(15, 16), (24, 25)], "h")
        p.poly([(24, 21), (25, 25), (29, 25), (26, 27), (26, 29), (23, 28), (20, 28), (22, 25)], "o")
        p.px([(24, 25), (24, 26)], "h")
    else:
        raise ValueError(name)
    return p.finish()
