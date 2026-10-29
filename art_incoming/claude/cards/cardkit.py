"""Shared helpers for Claude's card icons: 32px grid, flat shapes, at most six colours
plus a 1px dark outline, exported 4x with nearest-neighbour (Codex's method)."""
from pathlib import Path
import math
import numpy as np
from PIL import Image, ImageDraw

CLEAR = (0, 0, 0, 0)
OUTLINE = (20, 22, 31, 255)


class Pen:
    """Draws on a 32px RGBA canvas with colours named from a palette."""
    def __init__(self, pal):
        self.pal = pal
        self.im = Image.new('RGBA', (32, 32))
        self.d = ImageDraw.Draw(self.im)

    def c(self, name):
        return CLEAR if name is None else self.pal[name]
    def rect(self, b, c): self.d.rectangle(b, fill=self.c(c))
    def poly(self, pts, c): self.d.polygon(pts, fill=self.c(c))
    def line(self, pts, c, w=1): self.d.line(pts, fill=self.c(c), width=w)
    def ell(self, b, c): self.d.ellipse(b, fill=self.c(c))
    def arc(self, b, a0, a1, c, w=1): self.d.arc(b, a0, a1, fill=self.c(c), width=w)
    def chord(self, b, a0, a1, c): self.d.chord(b, a0, a1, fill=self.c(c))
    def pie(self, b, a0, a1, c): self.d.pieslice(b, a0, a1, fill=self.c(c))
    def px(self, pts, c):
        for p in pts:
            self.d.point(p, fill=self.c(c))

    def finish(self):
        """Adds the 1px dark outline around everything drawn."""
        a = np.array(self.im); mask = a[:, :, 3] > 0; out = np.zeros(mask.shape, bool)
        for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            sh = np.zeros_like(mask)
            sh[max(0, dy):min(32, 32 + dy), max(0, dx):min(32, 32 + dx)] = mask[max(0, -dy):min(32, 32 - dy), max(0, -dx):min(32, 32 - dx)]
            out |= sh
        a[out & ~mask] = OUTLINE
        return Image.fromarray(a)


def star_points(cx, cy, r_out, r_in, n=5, rot=-90):
    pts = []
    for i in range(n * 2):
        r = r_out if i % 2 == 0 else r_in
        a = math.radians(rot + i * 180 / n)
        pts.append((round(cx + r * math.cos(a)), round(cy + r * math.sin(a))))
    return pts


def build(out_dir: Path, names, draw, compare_with: Path | None = None, label='Claude'):
    """Draws every icon, checks the house rules, saves 32px sources + 128px exports,
    and writes a comparison sheet (the other version above, this one below)."""
    native = out_dir / 'source_32'; native.mkdir(parents=True, exist_ok=True); report = {}
    for n in names:
        im = draw(n); a = np.array(im)
        unique = np.unique(a[a[:, :, 3] > 0], axis=0)
        assert 5 <= len(unique) <= 7, (n, len(unique))
        assert set(np.unique(a[:, :, 3])) <= {0, 255}, n
        im.save(native / (n + '.png'))
        im.resize((128, 128), Image.Resampling.NEAREST).save(out_dir / (n + '.png'))
        report[n] = len(unique)
    rows = [(compare_with, 'Codex (current)')] if compare_with else []
    rows.append((native, label))
    sheet = Image.new('RGB', (len(names) * 104 + 20, len(rows) * 200 + 20), '#222832'); sd = ImageDraw.Draw(sheet)
    for r, (folder, lab) in enumerate(rows):
        y = r * 200 + 30; sd.text((12, y - 22), lab, fill='#ebedf0')
        for i, n in enumerate(names):
            x = 12 + i * 104
            im = Image.open(folder / (n + '.png')).convert('RGBA')
            big = im.resize((96, 96), Image.Resampling.NEAREST); sheet.paste(big, (x, y), big)
            sheet.paste(im, (x + 32, y + 102), im)
            sd.text((x + 48, y + 146), n[:12], fill='#9aa4b4', anchor='mm')
    sheet.save(out_dir / 'compare.png')
    return report
