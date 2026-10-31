"""Long Tomorrow set 2: red-orange, gold and void purple, native pixel geometry."""
from build_set2 import pen

CARDS = [
    ("spare_parts", "Spare Parts", "A red salvage cog with a loose golden bolt."),
    ("slow_burn", "Slow Burn", "A red ground tile smouldering under a low line of golden flames."),
    ("afterglow", "Afterglow", "A red handgun whose muzzle flash rises into a golden healing heart."),
    ("lifeline", "Lifeline", "A red rescue ring with gold reinforcing bands and a short tether."),
    ("red_shift", "Red Shift", "A pointed red projectile stretching ahead of three gold speed trails."),
    ("cinder_trail", "Cinder Trail", "A golden shot leaving a curved chain of red embers."),
    ("event_horizon", "Event Horizon", "Four purple gravity hooks closing around a dark square rift."),
    ("second_wind", "Second Wind", "A golden bellows breathing a red heart back to life."),
    ("time_debt", "Time Debt", "A purple energy cell tethered to a gold pendulum weight."),
    ("heat_death", "Heat Death", "A split red star draining its final gold heat into a dark centre."),
]


def draw(name):
    p = pen("long")
    if name == "spare_parts":
        p.rect((10, 4, 15, 27), "s"); p.rect((2, 13, 24, 18), "s")
        p.poly([(5, 6), (9, 5), (21, 22), (18, 26)], "r")
        p.poly([(18, 5), (22, 9), (7, 25), (3, 21)], "r")
        p.ell((4, 7, 22, 25), "r"); p.ell((9, 12, 17, 20), None)
        p.arc((4, 7, 22, 25), 175, 280, "h"); p.arc((4, 7, 22, 25), 0, 95, "s", 2)
        p.line([(10, 4), (15, 4)], "h")
        p.poly([(21, 5), (25, 3), (29, 7), (27, 11), (25, 11), (21, 20), (17, 18), (22, 9)], "y")
        p.line([(21, 5), (25, 3), (28, 6)], "yh")
        p.line([(26, 10), (21, 20), (18, 18)], "ys")
        p.line([(20, 14), (23, 16)], "ys"); p.line([(19, 17), (21, 18)], "yh")
    elif name == "slow_burn":
        p.rect((3, 22, 28, 28), "r"); p.line([(3, 22), (28, 22)], "h")
        p.rect((3, 26, 28, 28), "s"); p.line([(17, 24), (20, 26)], "s")
        p.poly([(5, 21), (5, 17), (9, 12), (8, 17), (11, 18), (14, 14), (17, 8), (17, 14), (20, 17), (23, 12), (23, 17), (26, 19), (26, 22), (6, 22)], "y")
        p.line([(6, 17), (8, 14)], "yh"); p.line([(14, 14), (16, 10)], "yh")
        p.line([(7, 22), (25, 22)], "ys")
        p.poly([(11, 21), (14, 18), (16, 15), (17, 20), (20, 21)], "yh")
    elif name == "afterglow":
        p.poly([(3, 15), (17, 15), (17, 20), (10, 20), (8, 28), (3, 27), (5, 20), (3, 20)], "r")
        p.line([(3, 15), (16, 15)], "h"); p.line([(17, 16), (17, 20), (10, 20), (8, 28), (3, 27)], "s")
        p.line([(10, 21), (13, 23), (15, 21)], "s")
        p.line([(5, 23), (4, 26)], "h")
        p.poly([(20, 15), (22, 17), (26, 17), (23, 19), (21, 22), (21, 19), (19, 18)], "y")
        p.px([(21, 17), (22, 18)], "yh")
        p.poly([(18, 5), (20, 3), (22, 3), (24, 5), (26, 3), (28, 3), (29, 5), (29, 7), (24, 12), (18, 7)], "y")
        p.line([(18, 5), (20, 3), (22, 3)], "yh")
        p.line([(29, 7), (24, 12), (22, 10)], "ys")
    elif name == "lifeline":
        p.line([(23, 23), (27, 24), (28, 29)], "ys", 3)
        p.line([(23, 23), (27, 24), (28, 29)], "y")
        p.ell((3, 3, 27, 27), "r"); p.ell((9, 9, 21, 21), None)
        p.arc((3, 3, 27, 27), 180, 275, "h")
        p.arc((3, 3, 27, 27), 0, 95, "s", 2)
        p.arc((9, 9, 21, 21), 185, 280, "s")
        for pts in ([(7, 5), (10, 3), (14, 9), (10, 11)], [(21, 4), (25, 8), (21, 12), (18, 9)], [(23, 20), (26, 23), (22, 26), (18, 22)], [(5, 20), (9, 18), (12, 22), (8, 26)]):
            p.poly(pts, "y"); p.line(pts[:2], "yh"); p.line(pts[2:], "ys")
    elif name == "red_shift":
        for pts in ([(4, 14), (13, 8)], [(3, 22), (16, 13)], [(10, 27), (22, 19)]):
            p.line(pts, "y", 2); p.px([pts[0]], "yh")
        p.poly([(13, 15), (19, 8), (29, 3), (25, 15), (19, 21)], "r")
        p.poly([(29, 3), (25, 15), (19, 21), (18, 17)], "s")
        p.line([(13, 15), (19, 8), (28, 4)], "h")
        p.line([(13, 15), (18, 20)], "ys", 2)
        p.px([(13, 15), (14, 16)], "yh")
    else:
        return draw_later(name, p)
    return p.finish()


def draw_later(name, p):
    if name == "cinder_trail":
        p.poly([(18, 7), (23, 3), (29, 3), (28, 9), (23, 13)], "y")
        p.line([(18, 7), (23, 3), (28, 3)], "yh")
        p.line([(28, 9), (23, 13)], "ys", 2)
        p.line([(18, 7), (23, 12)], "ys")
        for pts in ([(14, 12), (18, 11), (18, 16), (14, 19), (12, 16)], [(10, 20), (13, 22), (11, 26), (7, 25), (7, 22)], [(4, 26), (6, 28), (3, 29), (2, 28)]):
            p.poly(pts, "r"); p.line(pts[:2], "h"); p.line(pts[2:4], "s")
        p.line([(21, 16), (22, 19)], "h")
    elif name == "event_horizon":
        # An angular, empty rift. No planet, orbital ring or spherical silhouette.
        p.rect((12, 12, 19, 19), "vs")
        p.rect((14, 14, 17, 17), "k")
        for pts in (
            [(4, 11), (4, 5), (15, 5), (15, 8), (10, 8), (10, 12), (13, 12), (8, 17), (3, 12), (6, 12), (6, 9)],
            [(20, 4), (26, 4), (26, 15), (23, 15), (23, 10), (19, 10), (19, 13), (14, 8), (19, 3), (19, 6), (22, 6)],
            [(27, 20), (27, 26), (16, 26), (16, 23), (21, 23), (21, 19), (18, 19), (23, 14), (28, 19), (25, 19), (25, 22)],
            [(11, 27), (5, 27), (5, 16), (8, 16), (8, 21), (12, 21), (12, 18), (17, 23), (12, 28), (12, 25), (9, 25)],
        ):
            p.poly(pts, "v"); p.line(pts[:3], "vh"); p.line(pts[3:6], "vs")
        for x, y in ((11, 14), (17, 11), (20, 17), (14, 20)):
            p.rect((x, y, x + 1, y + 1), "y"); p.px([(x, y)], "yh"); p.px([(x + 1, y + 1)], "ys")
    elif name == "second_wind":
        p.poly([(4, 17), (12, 16), (19, 23), (9, 28), (3, 24)], "ys")
        p.poly([(4, 17), (12, 18), (18, 23), (9, 26), (4, 23)], "y")
        p.line([(4, 17), (12, 18), (18, 23)], "yh")
        p.line([(5, 20), (10, 21), (15, 24)], "ys")
        p.line([(5, 23), (10, 24), (12, 25)], "ys")
        p.poly([(12, 17), (16, 12), (19, 15), (17, 21)], "y")
        p.line([(12, 17), (16, 12)], "yh"); p.line([(17, 20), (19, 15)], "ys")
        p.poly([(17, 5), (20, 3), (23, 5), (26, 3), (29, 5), (29, 9), (23, 15), (17, 9)], "r")
        p.line([(17, 5), (20, 3), (22, 5)], "h"); p.line([(29, 9), (23, 15), (20, 12)], "s")
        p.line([(23, 19), (25, 21)], "h")
    elif name == "time_debt":
        p.rect((7, 3, 13, 5), "v"); p.line([(7, 3), (12, 3)], "vh")
        p.rect((4, 6, 17, 23), "v"); p.line([(4, 22), (4, 6), (16, 6)], "vh")
        p.rect((7, 9, 14, 20), "vs"); p.line([(17, 7), (17, 23), (5, 23)], "vs")
        p.poly([(11, 10), (14, 10), (11, 14), (14, 14), (8, 20), (9, 16), (7, 16)], "y")
        p.px([(11, 10), (10, 12)], "yh")
        p.line([(18, 9), (23, 9), (25, 12), (25, 21)], "ys", 2)
        p.line([(19, 9), (23, 9), (24, 12), (24, 20)], "yh")
        p.poly([(22, 21), (27, 21), (29, 28), (20, 28)], "y")
        p.line([(22, 21), (26, 21)], "yh"); p.line([(28, 25), (29, 28), (20, 28)], "ys")
    elif name == "heat_death":
        p.ell((4, 4, 27, 27), "r")
        p.arc((4, 4, 27, 27), 180, 280, "h")
        p.arc((4, 4, 27, 27), 0, 110, "s", 3)
        p.poly([(15, 3), (17, 3), (15, 9), (18, 13), (16, 18), (18, 23), (16, 29), (14, 29), (15, 23), (12, 18), (14, 13), (12, 9)], None)
        p.poly([(3, 14), (9, 12), (13, 14), (12, 17), (8, 15), (3, 17)], None)
        p.poly([(19, 13), (25, 10), (29, 11), (25, 13), (20, 16)], None)
        p.poly([(10, 12), (13, 14), (11, 18), (8, 17)], "y")
        p.line([(8, 16), (10, 12)], "yh"); p.px([(11, 17)], "ys")
        p.poly([(19, 15), (23, 17), (20, 21), (18, 19)], "y")
        p.line([(19, 15), (22, 17)], "yh"); p.line([(19, 20), (21, 19)], "ys")
        p.rect((4, 5, 6, 7), None); p.rect((25, 23, 27, 25), None)
        p.px([(4, 4), (28, 26)], "s")
    else:
        raise ValueError(name)
    return p.finish()
