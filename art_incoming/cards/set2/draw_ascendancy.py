"""Ascendancy set 2: cyan instruments, silver housings, native pixel geometry."""
from build_set2 import pen

CARDS = [
    ("calibrate", "Calibrate", "An adjustable square gunsight with a cyan precision reticle and silver adjustment knob."),
    ("efficiency_pass", "Efficiency Pass", "A silver notched pass stamped with a cyan energy symbol."),
    ("pulse_mine", "Pulse Mine", "A low silver mine with a cyan pressure plate and pulse prongs."),
    ("holo_decoy", "Holo Decoy", "A segmented cyan holographic bust above a silver projector."),
    ("signal_jam", "Signal Jam", "A cyan broadcast antenna interrupted by a diagonal silver blocker."),
    ("mirror_shield", "Mirror Shield", "A diamond-shaped silver mirror reflecting a cyan bent arrow."),
    ("phase_shift", "Phase Shift", "A silver cube between two cyan teleport brackets and opposing arrows."),
    ("neural_link", "Neural Link", "A silver head profile with a connected cyan neural circuit."),
    ("quarantine", "Quarantine", "Four cyan cells sealed inside a square silver isolation frame."),
    ("perfect_model", "Perfect Model", "A faceted cyan prediction cube with a silver trajectory curving toward it."),
]


def draw(name):
    p = pen("ascendancy")
    if name == "calibrate":
        p.poly([(5, 5), (22, 5), (25, 8), (25, 23), (4, 23), (4, 8)], "g")
        p.rect((7, 8, 22, 20), None)
        p.line([(4, 8), (5, 5), (21, 5)], "w"); p.line([(25, 9), (25, 23), (5, 23)], "d")
        p.rect((10, 24, 20, 27), "g"); p.line([(10, 24), (20, 24)], "w")
        p.rect((25, 11, 29, 17), "g"); p.line([(25, 11), (28, 11)], "w")
        p.line([(27, 12), (27, 16)], "d")
        p.line([(14, 8), (14, 11)], "c"); p.line([(8, 14), (11, 14)], "c")
        p.line([(18, 14), (21, 14)], "s"); p.line([(14, 18), (14, 20)], "s")
        p.poly([(14, 12), (16, 14), (14, 16), (12, 14)], "c")
        p.px([(13, 13), (14, 12)], "h")
    elif name == "efficiency_pass":
        p.poly([(4, 7), (27, 7), (27, 12), (25, 14), (25, 17), (27, 19), (27, 24), (4, 24), (4, 19), (6, 17), (6, 14), (4, 12)], "g")
        p.line([(4, 7), (26, 7)], "w"); p.line([(5, 8), (5, 11)], "w")
        p.line([(5, 24), (27, 24), (27, 20)], "d")
        for y in (10, 14, 18, 21):
            p.px([(9, y)], "d")
        p.poly([(17, 9), (22, 9), (18, 14), (23, 14), (14, 22), (16, 17), (12, 17)], "c")
        p.line([(17, 9), (21, 9)], "h"); p.line([(13, 16), (16, 11)], "h")
        p.line([(20, 17), (15, 21)], "s")
    elif name == "pulse_mine":
        for x, y in ((5, 14), (15, 7), (25, 14)):
            p.rect((x, y, x + 1, y + 7), "g"); p.px([(x, y)], "w")
            p.rect((x - 1, y - 2, x + 2, y), "c"); p.px([(x - 1, y - 2)], "h")
        p.poly([(5, 20), (9, 15), (23, 15), (28, 20), (28, 25), (4, 25), (4, 21)], "g")
        p.line([(4, 25), (28, 25)], "d", 2); p.line([(5, 20), (9, 15), (22, 15)], "w")
        p.ell((10, 17, 23, 22), "s"); p.ell((10, 17, 21, 20), "c")
        p.line([(13, 17), (18, 17)], "h")
    elif name == "holo_decoy":
        p.ell((11, 3, 21, 13), "c"); p.arc((11, 3, 21, 13), 185, 280, "h")
        p.arc((11, 3, 21, 13), 0, 80, "s")
        p.poly([(13, 13), (19, 13), (19, 15), (24, 17), (25, 21), (7, 21), (8, 17), (13, 15)], "c")
        p.line([(8, 18), (13, 16)], "h"); p.line([(20, 17), (23, 18), (24, 21)], "s")
        p.rect((8, 10, 24, 10), None); p.rect((7, 19, 25, 19), None)
        p.rect((10, 25, 22, 28), "g"); p.line([(10, 25), (22, 25)], "w"); p.line([(10, 28), (22, 28)], "d")
        p.rect((14, 23, 18, 24), "s")
    elif name == "signal_jam":
        p.rect((14, 12, 16, 25), "s"); p.line([(14, 13), (14, 24)], "h")
        p.ell((12, 9, 18, 15), "c"); p.px([(14, 10)], "h")
        p.arc((3, 2, 27, 25), 190, 350, "c", 2); p.arc((7, 6, 23, 21), 190, 350, "c", 2)
        p.arc((3, 2, 27, 25), 210, 270, "h")
        p.poly([(10, 26), (20, 26), (22, 29), (8, 29)], "d")
        p.poly([(4, 25), (25, 4), (28, 7), (7, 28)], "g")
        p.line([(4, 25), (25, 4)], "w"); p.line([(7, 28), (28, 7)], "d")
    elif name == "mirror_shield":
        p.poly([(17, 3), (28, 15), (17, 28), (6, 15)], "g")
        p.line([(6, 15), (17, 3), (27, 14)], "w")
        p.line([(28, 15), (17, 28)], "d", 2)
        p.poly([(17, 7), (24, 15), (17, 23), (10, 15)], "s")
        p.poly([(17, 7), (20, 10), (12, 17), (10, 15)], "c")
        p.line([(16, 9), (12, 13)], "h")
        p.line([(3, 6), (12, 15), (3, 23)], "k", 4)
        p.line([(3, 6), (12, 15), (4, 22)], "c", 2)
        p.poly([(2, 19), (2, 25), (8, 25)], "c"); p.line([(2, 19), (2, 24)], "h")
    elif name == "phase_shift":
        p.poly([(3, 10), (7, 10), (7, 12), (5, 12), (5, 22), (7, 22), (7, 24), (3, 24)], "c")
        p.line([(3, 10), (7, 10)], "h"); p.line([(4, 24), (7, 24)], "s")
        p.poly([(25, 7), (29, 7), (29, 21), (25, 21), (25, 19), (27, 19), (27, 9), (25, 9)], "c")
        p.line([(25, 7), (29, 7)], "h"); p.line([(29, 8), (29, 21)], "s")
        p.poly([(16, 10), (22, 13), (22, 20), (16, 23), (10, 20), (10, 13)], "g")
        p.poly([(16, 10), (22, 13), (16, 16), (10, 13)], "w")
        p.poly([(16, 16), (22, 13), (22, 20), (16, 23)], "d")
        p.line([(9, 5), (20, 5)], "c", 2); p.poly([(19, 2), (23, 5), (19, 8)], "c")
        p.line([(22, 26), (11, 26)], "c", 2); p.poly([(12, 23), (8, 26), (12, 29)], "s")
    elif name == "neural_link":
        p.poly([(9, 4), (20, 4), (24, 8), (24, 13), (28, 17), (24, 18), (24, 23), (20, 24), (20, 29), (9, 29), (10, 23), (6, 19), (5, 10)], "g")
        p.line([(5, 10), (9, 4), (20, 4)], "w")
        p.poly([(20, 22), (24, 21), (24, 23), (20, 24), (20, 29), (9, 29), (10, 26), (18, 26)], "d")
        p.line([(10, 10), (17, 10), (17, 17), (12, 17), (12, 23)], "s", 3)
        p.line([(10, 10), (17, 10), (17, 17), (12, 17), (12, 23)], "c")
        for x, y in ((9, 9), (17, 9), (16, 16)):
            p.rect((x - 1, y - 1, x + 2, y + 2), "c"); p.px([(x - 1, y - 1)], "h")
        p.px([(22, 13)], "d")
    elif name == "quarantine":
        p.rect((4, 4, 27, 27), "g"); p.rect((7, 7, 24, 24), "k")
        p.line([(4, 26), (4, 4), (26, 4)], "w"); p.line([(27, 5), (27, 27), (5, 27)], "d")
        for x in (9, 17):
            for y in (9, 17):
                p.rect((x, y, x + 5, y + 5), "c"); p.line([(x, y), (x + 4, y)], "h")
                p.line([(x + 5, y + 1), (x + 5, y + 5), (x + 1, y + 5)], "s")
        for x, y in ((3, 3), (25, 3), (3, 25), (25, 25)):
            p.rect((x, y, x + 3, y + 3), "d"); p.line([(x, y), (x + 2, y)], "w")
    elif name == "perfect_model":
        p.arc((2, 2, 29, 28), 85, 320, "g", 2)
        p.arc((2, 2, 29, 28), 180, 275, "w")
        p.arc((2, 2, 29, 28), 85, 155, "d")
        p.poly([(17, 7), (25, 12), (25, 21), (17, 26), (9, 21), (9, 12)], "c")
        p.poly([(17, 7), (25, 12), (17, 17), (9, 12)], "h")
        p.poly([(17, 17), (25, 12), (25, 21), (17, 26)], "s")
        p.line([(10, 13), (16, 17), (16, 24)], "h")
        p.line([(27, 7), (28, 12), (21, 15)], "g", 2)
        p.poly([(21, 11), (18, 17), (25, 17)], "w")
    else:
        raise ValueError(name)
    return p.finish()
