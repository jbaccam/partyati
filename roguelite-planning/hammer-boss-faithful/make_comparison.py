"""Build the reference-vs-render comparison sheets. Run with system Python (needs Pillow).

Kept separate from build_boss.py because Blender's bundled Python has no Pillow.
The generator renders Reference_Match.png at the sheet's exact 1086x1448, so the
two images can be laid side by side without rescaling either one.
"""
from pathlib import Path
from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent
REF = OUT.parent / 'hammer-boss' / 'source' / 'boss-reference.png'
GAP, PAD, BAR = 16, 16, 44
BG, FG = (26, 28, 32), (232, 234, 238)


def label(img, text):
    strip = Image.new('RGB', (img.width, BAR), BG)
    ImageDraw.Draw(strip).text((10, 14), text, fill=FG)
    out = Image.new('RGB', (img.width, img.height + BAR), BG)
    out.paste(strip, (0, 0))
    out.paste(img, (0, BAR))
    return out


def sheet(pairs, path, scale=1.0):
    tiles = []
    for text, img in pairs:
        if scale != 1.0:
            img = img.resize((int(img.width * scale), int(img.height * scale)),
                             Image.LANCZOS)
        tiles.append(label(img.convert('RGB'), text))
    w = sum(t.width for t in tiles) + GAP * (len(tiles) - 1) + PAD * 2
    h = max(t.height for t in tiles) + PAD * 2
    canvas = Image.new('RGB', (w, h), BG)
    x = PAD
    for t in tiles:
        canvas.paste(t, (x, PAD))
        x += t.width + GAP
    canvas.save(path)
    print('wrote', path.name, canvas.size)


ref = Image.open(REF)
render = Image.open(OUT / 'previews/Reference_Match.png')
sheet([('REFERENCE', ref), ('REBUILD', render)],
      OUT / 'previews/Comparison_Full.png', scale=0.62)

# Matched detail crops. Fractions of each image, which line up because the
# render reproduces the reference's framing and aspect.
CROPS = {
    'Face': (0.38, 0.12, 0.66, 0.31),
    'Grip_and_hammer': (0.00, 0.54, 0.52, 0.92),
    'Torso': (0.20, 0.27, 0.80, 0.60),
    'Far_hand': (0.72, 0.53, 1.00, 0.72),
}
for name, (x0, y0, x1, y1) in CROPS.items():
    pair = []
    for text, img in (('REFERENCE', ref), ('REBUILD', render)):
        w, h = img.size
        pair.append((text, img.crop((int(x0 * w), int(y0 * h),
                                     int(x1 * w), int(y1 * h)))))
    target = 520 / pair[0][1].width
    sheet(pair, OUT / f'previews/Comparison_{name}.png', scale=target)
