"""Beach Cove texture sheets.

Derives the beach palette from the exact painted sheets the existing rounded cliff
kits already use, then authors the surfaces those kits never needed (sand, shallow
water). Every sheet is made seamlessly tileable, because the beach kit is modelled
at final Roblox stud size and therefore repeats each sheet many times per face
instead of roughly once.

Run with the system Python (needs numpy + Pillow):
    python author_textures.py
"""
import hashlib
import math
import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent
TEX = ROOT / "textures"
SRC = TEX / "source"
DOWNLOADS = Path("C:/Users/Jeremiah/Downloads")
SIZE = 1024

# Sheets already approved and in use by the sibling cliff kits. Copied unchanged
# into textures/source/ so this kit records its own provenance.
SOURCES = {
    "rock": "02862eb3-b09f-4d03-8bc3-ad7b57fd49a7.png",
    "transition": "62c4effc-a3a8-48f1-a138-776cdb1d9a8e.png",
    "grass": "ChatGPT Image Sep 16, 2026, 11_42_57 AM (2).png",
    "bark": "ChatGPT Image Sep 16, 2026, 06_07_54 PM.png",
    "foliage": "ChatGPT Image Sep 16, 2026, 06_10_48 PM.png",
    "logbark": "ChatGPT Image Sep 16, 2026, 11_42_59 AM (6).png",
}
REFERENCE = "ChatGPT Image Sep 22, 2026, 07_47_05 PM.png"

# Hand-painted sheets from the user's mountain set, supplied 2026-09-23 as the
# quality bar for this kit. They are recoloured here rather than reused as-is, so
# the beach rim does not read as the same cliffs in a different place. Procedural
# stone and grass were tried first and did not reach this standard: the earlier
# attempts came out either smeared (smooth noise has no hard edges) or as
# cobblestone and confetti (cells and stamps too small and too even).
MOUNTAIN = {
    "rock": "6.webp",        # large faceted grey blocks, warm highlights
    "transition": "8.webp",  # grass rolling over the same grey rock
    "grass": "13.webp",      # lush painted grass
    "frond": "17.webp",      # soft polygonal foliage
    "palm_bark": "18.webp",  # light faceted bark
    "water": "10.webp",      # caustic water
}
MOUNTAIN_DIR = Path(
    "C:/Users/Jeremiah/AppData/Local/Temp/claude/"
    "C--Users-Jeremiah-Documents-ChatGPT-Roblox/"
    "217e7a61-6e7c-4e51-99ab-379fa4b9678d/images"
)


# --------------------------------------------------------------------------
# colour helpers
# --------------------------------------------------------------------------
def to_hsv(rgb):
    """rgb float 0-1 (H,W,3) -> hsv float 0-1."""
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    mx = rgb.max(-1)
    mn = rgb.min(-1)
    diff = mx - mn
    h = np.zeros_like(mx)
    safe = diff > 1e-8
    idx = safe & (mx == r)
    h[idx] = ((g - b)[idx] / diff[idx]) % 6
    idx = safe & (mx == g)
    h[idx] = ((b - r)[idx] / diff[idx]) + 2
    idx = safe & (mx == b)
    h[idx] = ((r - g)[idx] / diff[idx]) + 4
    h /= 6.0
    s = np.where(mx > 1e-8, diff / np.maximum(mx, 1e-8), 0.0)
    return np.stack([h, s, mx], -1)


def to_rgb(hsv):
    h, s, v = hsv[..., 0] % 1.0, hsv[..., 1], hsv[..., 2]
    i = np.floor(h * 6.0)
    f = h * 6.0 - i
    p = v * (1 - s)
    q = v * (1 - f * s)
    t = v * (1 - (1 - f) * s)
    i = (i % 6).astype(int)
    out = np.zeros(hsv.shape, dtype=np.float32)
    for n, (rr, gg, bb) in enumerate([(v, t, p), (q, v, p), (p, v, t), (p, q, v), (t, p, v), (v, p, q)]):
        m = i == n
        out[m] = np.stack([rr, gg, bb], -1)[m]
    return out


def regrade(rgb, hue_target=None, hue_pull=0.0, sat=1.0, val=1.0, lift=0.0):
    """Shift a painted sheet toward a target hue while keeping its brushwork.

    hue_pull blends each pixel's hue toward hue_target, so painted variation
    survives instead of being flattened to a single colour.
    """
    hsv = to_hsv(np.clip(rgb, 0, 1))
    if hue_target is not None and hue_pull:
        h = hsv[..., 0]
        delta = (hue_target - h + 0.5) % 1.0 - 0.5  # shortest way round the wheel
        hsv[..., 0] = (h + delta * hue_pull) % 1.0
    hsv[..., 1] = np.clip(hsv[..., 1] * sat, 0, 1)
    hsv[..., 2] = np.clip(hsv[..., 2] * val + lift, 0, 1)
    return to_rgb(hsv)


# --------------------------------------------------------------------------
# seamless tiling
# --------------------------------------------------------------------------
def make_seamless(rgb, feather=0.18, axes="both"):
    """Offset-and-heal.

    `axes` selects which wrap seams to fix. The grass-to-rock transition sheet is
    a vertical gradient band, not a repeating surface: it is mapped once up the
    cliff rim and repeated only around the perimeter, so it must be healed
    horizontally only. Healing it vertically folds the grass band into the middle
    and produces a visible repeating grid.

    Rolling by half is a cyclic permutation, so the sheet's discontinuity moves
    from the borders to the centre cross while the new borders become genuinely
    continuous. The centre cross is then healed by cross-fading toward the
    unrolled original, whose centre is clean interior paint. Each source is
    weighted only where it is clean; the cross-dissolve between them is confined
    to the feather band.
    """
    h, w = rgb.shape[:2]
    rolled = rgb
    if axes in ("both", "x"):
        rolled = np.roll(rolled, w // 2, axis=1)
    if axes in ("both", "y"):
        rolled = np.roll(rolled, h // 2, axis=0)

    def centre_weight(n):
        """0 at the borders, 1 across the middle, cosine ramp between."""
        band = max(2, int(n * feather))
        m = np.zeros(n, dtype=np.float32)
        ramp = 0.5 - 0.5 * np.cos(np.linspace(0, np.pi, band))
        m[:band] = ramp          # rises away from the left border
        m[band:-band] = 1.0
        m[-band:] = ramp[::-1]   # falls back toward the right border
        return m

    # 1 across the interior (take the original's clean centre), 0 at the borders
    # (keep the rolled copy's continuous edges). Only the healed axes ramp.
    mx = centre_weight(w)[None, :] if axes in ("both", "x") else np.ones((1, w), dtype=np.float32)
    my = centre_weight(h)[:, None] if axes in ("both", "y") else np.ones((h, 1), dtype=np.float32)
    mask = (my * mx)[..., None]
    return rolled * (1 - mask) + rgb * mask


def tile_error(rgb, axes="both"):
    """Mean absolute difference across the wrap seams being claimed; lower is better."""
    parts = []
    if axes in ("both", "y"):
        parts.append(np.abs(rgb[0, :, :] - rgb[-1, :, :]).mean())
    if axes in ("both", "x"):
        parts.append(np.abs(rgb[:, 0, :] - rgb[:, -1, :]).mean())
    return float(np.mean(parts))


# --------------------------------------------------------------------------
# procedural noise (periodic by construction, so it tiles exactly)
# --------------------------------------------------------------------------
def periodic_noise(size, freq, seed, octaves=4, persistence=0.55):
    """Band-limited noise built in the frequency domain, so it wraps exactly."""
    rng = np.random.default_rng(seed)
    out = np.zeros((size, size), dtype=np.float32)
    amp = 1.0
    total = 0.0
    for o in range(octaves):
        f = freq * (2 ** o)
        grid = rng.random((f, f)).astype(np.float32)
        # Periodic bilinear upsample: wrap the source grid, not clamp it.
        ys = np.linspace(0, f, size, endpoint=False)
        xs = np.linspace(0, f, size, endpoint=False)
        y0 = np.floor(ys).astype(int) % f
        x0 = np.floor(xs).astype(int) % f
        y1 = (y0 + 1) % f
        x1 = (x0 + 1) % f
        fy = (ys - np.floor(ys))[:, None].astype(np.float32)
        fx = (xs - np.floor(xs))[None, :].astype(np.float32)
        fy = fy * fy * (3 - 2 * fy)
        fx = fx * fx * (3 - 2 * fx)
        top = grid[np.ix_(y0, x0)] * (1 - fx) + grid[np.ix_(y0, x1)] * fx
        bot = grid[np.ix_(y1, x0)] * (1 - fx) + grid[np.ix_(y1, x1)] * fx
        out += amp * (top * (1 - fy) + bot * fy)
        total += amp
        amp *= persistence
    out /= total
    return (out - out.min()) / max(1e-6, float(np.ptp(out)))


def author_sand(size=SIZE):
    """Warm pale sand: broad drift shading, fine grain, a few scattered shell flecks."""
    drift = periodic_noise(size, 3, seed=11, octaves=4)
    grain = periodic_noise(size, 64, seed=12, octaves=2, persistence=0.4)
    ripple = np.sin(periodic_noise(size, 4, seed=13, octaves=2) * np.pi * 6.0) * 0.5 + 0.5

    base = np.array([0.93, 0.85, 0.66], dtype=np.float32)
    dark = np.array([0.82, 0.72, 0.52], dtype=np.float32)
    t = (0.55 * drift + 0.25 * ripple + 0.20 * grain)[..., None]
    rgb = dark + (base - dark) * t
    rgb += (grain[..., None] - 0.5) * 0.045

    flecks = periodic_noise(size, 96, seed=14, octaves=1)
    spot = (flecks > 0.955)[..., None]
    rgb = np.where(spot, np.clip(rgb + 0.10, 0, 1), rgb)
    return np.clip(rgb, 0, 1)


def cell_noise(size, grid_n, seed, jitter=0.9):
    """Periodic jittered-grid Voronoi.

    Returns (cell_id, f1, f2, seed_y, seed_x) in pixel units. One seed per grid
    cell and only the 3x3 neighbourhood is searched, which is both fast and
    exactly periodic because the neighbour lookup wraps.

    This is the structure smooth value noise cannot give: cells have hard
    boundaries, so a texture built from them has crisp facet edges instead of
    gradients. That difference is why the earlier authored sheets read as smeared.
    """
    rng = np.random.default_rng(seed)
    pts = (rng.random((grid_n, grid_n, 2)).astype(np.float32) * jitter
           + (1.0 - jitter) * 0.5)

    coord = (np.arange(size, dtype=np.float32) + 0.5) / size * grid_n
    py = coord[:, None]
    px = coord[None, :]
    gy = np.floor(py).astype(np.int32)
    gx = np.floor(px).astype(np.int32)

    f1 = np.full((size, size), 1e9, np.float32)
    f2 = np.full((size, size), 1e9, np.float32)
    cid = np.zeros((size, size), np.int32)
    sy_win = np.zeros((size, size), np.float32)
    sx_win = np.zeros((size, size), np.float32)

    for oy in (-1, 0, 1):
        for ox in (-1, 0, 1):
            ay, ax = gy + oy, gx + ox           # absolute cell, may run outside
            wy, wx = ay % grid_n, ax % grid_n   # wrapped, for the seed lookup
            sy = pts[wy, wx, 0] + ay
            sx = pts[wy, wx, 1] + ax
            d = np.hypot(py - sy, px - sx)
            better = d < f1
            f2 = np.where(better, f1, np.minimum(f2, d))
            cid = np.where(better, wy * grid_n + wx, cid)
            sy_win = np.where(better, sy, sy_win)
            sx_win = np.where(better, sx, sx_win)
            f1 = np.where(better, d, f1)

    scale = size / grid_n
    return cid, f1 * scale, f2 * scale, sy_win * scale, sx_win * scale, py * scale


def ramp(t, stops):
    """Piecewise-linear colour ramp through a list of RGB stops."""
    t = np.clip(t, 0, 1) * (len(stops) - 1)
    i = np.clip(np.floor(t).astype(int), 0, len(stops) - 2)
    f = (t - i)[..., None]
    a = np.array(stops, dtype=np.float32)[i]
    b = np.array(stops, dtype=np.float32)[i + 1]
    return a * (1 - f) + b * f


def author_rock_faceted(size=SIZE, palette=None, seed=101):
    """Hand-painted faceted cliff stone.

    Large irregular blocks, each split into a few angular planar facets by
    directional cleavage rather than a second blobby Voronoi -- a nested Voronoi
    gives rounded pebbles and the whole sheet reads as a dry-stone wall. Crevices
    are thin dark lines; the rim light is a narrow crisp line on upper edges only,
    with a matching shadow under lower edges. Wrapping the highlight all the way
    round a cell is what makes stone look like cobbles.
    """
    if palette is None:
        palette = [(0.315, 0.340, 0.400), (0.470, 0.492, 0.540),
                   (0.620, 0.632, 0.655), (0.755, 0.752, 0.740),
                   (0.865, 0.850, 0.812)]

    bid, b1, b2, bsy, bsx, pyp = cell_noise(size, 5, seed=seed, jitter=0.80)
    cell_px = size / 5.0

    rng = np.random.default_rng(seed + 50)
    nb = 5 * 5
    block_tone = rng.uniform(0.06, 0.94, nb).astype(np.float32)
    ang1 = rng.uniform(0, math.pi, nb).astype(np.float32)
    ang2 = (ang1 + rng.uniform(0.6, 1.4, nb)).astype(np.float32)
    w1 = rng.uniform(0.22, 0.42, nb).astype(np.float32) * cell_px
    w2 = rng.uniform(0.28, 0.55, nb).astype(np.float32) * cell_px

    pxp = (np.arange(size, dtype=np.float32)[None, :] + 0.5)
    lx = pxp - bsx
    ly = pyp - bsy

    # Angular cleavage planes: two quantised directional bands per block.
    u1 = (lx * np.cos(ang1[bid]) + ly * np.sin(ang1[bid])) / w1[bid]
    u2 = (lx * np.cos(ang2[bid]) + ly * np.sin(ang2[bid])) / w2[bid]
    facet = (np.floor(u1).astype(np.int64) * 7
             + np.floor(u2).astype(np.int64) * 23
             + bid.astype(np.int64) * 101)
    # int64 throughout: the mixing constant overflows int32 on its own.
    fac_jit = ((facet * np.int64(2654435761)) % 1000).astype(np.float32) / 1000.0 - 0.5

    value = np.clip(block_tone[bid] + 0.17 * fac_jit, 0, 1)
    # Painterly drift inside each facet so faces are not flat vector fills.
    value = np.clip(value + (periodic_noise(size, 24, seed=seed + 5, octaves=2) - 0.5) * 0.075, 0, 1)
    rgb = ramp(value, palette)

    # Thin dark crevices between blocks.
    crev = np.clip(1.0 - (b2 - b1) / (size * 0.0055), 0, 1) ** 1.3
    rgb *= (1.0 - 0.50 * crev)[..., None]

    # Hairline seams between cleavage facets.
    seam = np.clip(1.0 - np.abs(u1 - np.round(u1)) / 0.035, 0, 1) * 0.5
    seam += np.clip(1.0 - np.abs(u2 - np.round(u2)) / 0.030, 0, 1) * 0.5
    rgb *= (1.0 - 0.10 * np.clip(seam, 0, 1))[..., None]

    # Rim light on upper edges only, and shadow under lower edges.
    near_edge = np.clip(1.0 - (b2 - b1) / (size * 0.012), 0, 1)
    upness = np.clip(-ly / (cell_px * 0.42), 0, 1) ** 1.5
    downness = np.clip(ly / (cell_px * 0.45), 0, 1) ** 1.5
    rim = np.clip(upness * near_edge * 1.4, 0, 1)[..., None]
    rgb = rgb * (1 - rim * 0.80) + np.array([0.94, 0.925, 0.885], np.float32) * (rim * 0.80)
    rgb *= (1.0 - 0.30 * np.clip(downness * near_edge * 1.2, 0, 1))[..., None]

    # A little moss caught in the deepest cracks.
    moss_mask = crev * np.clip((periodic_noise(size, 6, seed=seed + 9, octaves=2) - 0.60) / 0.40, 0, 1)
    rgb = rgb * (1 - (moss_mask * 0.50)[..., None]) + np.array([0.40, 0.52, 0.26], np.float32) * (moss_mask * 0.50)[..., None]
    return np.clip(rgb, 0, 1)


def _blade_stamps(px=88, variants=16, seed=7):
    """Pointed grass blades at assorted angles, as soft alpha stamps."""
    rng = np.random.default_rng(seed)
    yy, xx = np.mgrid[0:px, 0:px].astype(np.float32)
    yy -= px / 2
    xx -= px / 2
    out = []
    for _ in range(variants):
        ang = rng.uniform(0, math.tau)
        length = rng.uniform(px * 0.38, px * 0.50)
        width = rng.uniform(px * 0.14, px * 0.21)
        bend = rng.uniform(-0.35, 0.35)
        ca, sa = math.cos(ang), math.sin(ang)
        u = xx * ca + yy * sa              # along the blade
        v = -xx * sa + yy * ca             # across it
        t = np.clip(u / length, 0, 1)
        v = v - bend * length * t * t      # curve the blade over
        half = width * (1 - t) ** 0.55
        d = np.abs(v) - half
        alpha = np.clip(1.0 - d / 1.6, 0, 1)
        alpha = np.where((u < 0) | (u > length), 0.0, alpha)
        out.append(alpha.astype(np.float32))
    return out


def _stamp(canvas, stamps, palette, count, rng, size, centres=None, spread=None):
    """Composite alpha stamps onto a wrapping canvas."""
    n = len(stamps)
    for i in range(count):
        st = stamps[rng.integers(n)]
        h, w = st.shape
        if centres is None:
            y0, x0 = rng.integers(0, size), rng.integers(0, size)
        else:
            cy, cx = centres[i % len(centres)]
            y0 = int(cy + rng.normal(0, spread)) % size
            x0 = int(cx + rng.normal(0, spread)) % size
        col = np.array(palette[rng.integers(len(palette))], np.float32)
        ys = (np.arange(h) + y0) % size
        xs = (np.arange(w) + x0) % size
        sl = np.ix_(ys, xs)
        a = st[..., None]
        canvas[sl] = canvas[sl] * (1 - a) + col * a
    return canvas


GRASS_GREENS = [
    (0.168, 0.392, 0.271),   # deep shadow green
    (0.231, 0.514, 0.286),
    (0.318, 0.612, 0.318),
    (0.447, 0.714, 0.341),
    (0.600, 0.808, 0.376),   # bright highlight
    (0.722, 0.855, 0.420),
]


def author_grass_painted(size=SIZE, greens=None, seed=201, blades=2600):
    """Painterly grass: broad tonal patches, then thousands of painted blades.

    The brief rules out "realistic grass blades across the whole surface", which
    is about photographic detail, not about having any blade shapes at all -- the
    approved sheets are clearly built from painted blades in several greens. A
    flat green gradient reads as low quality at any tuning.
    """
    greens = greens or GRASS_GREENS
    rng = np.random.default_rng(seed)

    # Broad tonal patches underneath, so the field is not uniform.
    pid, p1, p2, *_ = cell_noise(size, 5, seed=seed + 1, jitter=0.95)
    patch = rng.uniform(0.15, 0.75, 5 * 5).astype(np.float32)[pid]
    patch = 0.65 * patch + 0.35 * periodic_noise(size, 4, seed=seed + 2, octaves=3)
    canvas = ramp(patch, greens[:4])

    stamps = _blade_stamps(px=max(32, size // 11), variants=18, seed=seed + 3)

    # Clustered into tufts rather than evenly scattered: an even scatter of small
    # blades reads as confetti, which is what the first attempt looked like.
    tufts = [(rng.integers(0, size), rng.integers(0, size)) for _ in range(180)]
    canvas = _stamp(canvas, stamps, greens[1:4], int(blades * 0.34), rng, size,
                    centres=tufts, spread=size * 0.022)
    canvas = _stamp(canvas, stamps, greens[2:5], int(blades * 0.34), rng, size)
    canvas = _stamp(canvas, stamps, greens[3:], int(blades * 0.22), rng, size,
                    centres=tufts, spread=size * 0.018)
    canvas = _stamp(canvas, stamps, greens[:2], int(blades * 0.10), rng, size)
    return np.clip(canvas, 0, 1)


def author_transition_painted(size=SIZE, seed=301):
    """Grass rolling over a faceted stone rim, with tufts hanging into the rock."""
    rng = np.random.default_rng(seed)
    rock = author_rock_faceted(size, seed=seed + 11)
    grass = author_grass_painted(size, seed=seed + 12, blades=2000)

    v = (np.arange(size, dtype=np.float32)[:, None] / (size - 1))   # 0 top -> 1 bottom
    wob = periodic_noise(size, 4, seed=seed + 2, octaves=3)[0:1, :]
    drip = periodic_noise(size, 11, seed=seed + 3, octaves=2)[0:1, :]
    edge = 0.30 + 0.085 * wob + 0.075 * np.clip(drip - 0.55, 0, 1) / 0.45
    edge = np.repeat(edge, size, axis=0)

    blend = np.clip((edge - v) / 0.012 + 0.5, 0, 1)[..., None]
    rgb = rock * (1 - blend) + grass * blend

    # Tufts and trailing strands below the boundary, thinning downward.
    stamps = _blade_stamps(px=max(28, size // 13), variants=14, seed=seed + 4)
    centres = []
    for _ in range(260):
        x = int(rng.integers(0, size))
        e = float(edge[0, x]) * size
        centres.append((e + abs(rng.normal(0, size * 0.055)), x))
    rgb = _stamp(rgb, stamps, GRASS_GREENS[1:5], len(centres), rng, size,
                 centres=centres, spread=size * 0.012)
    return np.clip(rgb, 0, 1)


def author_rock(size=SIZE):
    """Broad painted cliff stone: a few large value patches, almost no detail.

    The supplied stone sheet is a cobble of dozens of small blocks. Tiled ~6x
    across a 55-stud cliff that reads as hundreds of little rocks, which is not
    what the reference cliffs look like and not what the brief asks for: "2-4
    main value ranges", "broad patches", "low contrast", "subtle grunge", and
    explicitly avoid "high-frequency noise" and "sharp photoreal cracks". So the
    motif is authored flat rather than regraded.
    """
    broad = periodic_noise(size, 2, seed=41, octaves=3, persistence=0.45)
    mid = periodic_noise(size, 4, seed=42, octaves=2, persistence=0.4)
    field = np.clip(0.70 * broad + 0.30 * mid, 0, 1)

    # Quantise to four value ranges, then soften the steps so the sheet reads as
    # painted planes rather than posterised bands.
    levels = 4
    stepped = np.floor(field * levels) / (levels - 1)
    stepped = np.clip(stepped, 0, 1)
    soft = 0.45 * stepped + 0.55 * field

    light = np.array([0.76, 0.745, 0.715], dtype=np.float32)
    dark = np.array([0.585, 0.575, 0.560], dtype=np.float32)
    rgb = dark + (light - dark) * soft[..., None]

    # A handful of long soft crevices, not a network of cracks.
    ridge = periodic_noise(size, 3, seed=43, octaves=2, persistence=0.5)
    crev = 1.0 - np.abs(2.0 * ridge - 1.0)
    crev = np.clip((crev - 0.93) / 0.07, 0, 1) ** 2.0
    rgb -= crev[..., None] * 0.032

    # Occasional broad highlight where a plane catches the sun.
    hi = np.clip((periodic_noise(size, 3, seed=44, octaves=2) - 0.74) / 0.26, 0, 1)
    rgb += hi[..., None] * 0.055

    rgb += (periodic_noise(size, 48, seed=45, octaves=1)[..., None] - 0.5) * 0.012
    return np.clip(rgb, 0, 1)


def author_grass(size=SIZE):
    """Soft spring green with broad patches; no blade detail.

    The brief wants "bright spring green, soft painterly variation, subtle
    patches" and rules out "realistic grass blades across the whole surface" and
    "obvious repeating motifs" on large surfaces.
    """
    broad = periodic_noise(size, 2, seed=51, octaves=3, persistence=0.5)
    patch = periodic_noise(size, 5, seed=52, octaves=2, persistence=0.42)
    field = np.clip(0.68 * broad + 0.32 * patch, 0, 1)

    light = np.array([0.62, 0.82, 0.40], dtype=np.float32)
    dark = np.array([0.40, 0.64, 0.28], dtype=np.float32)
    rgb = dark + (light - dark) * field[..., None]

    # Sparse slightly yellower clumps, kept low contrast.
    clump = np.clip((periodic_noise(size, 7, seed=53, octaves=2) - 0.70) / 0.30, 0, 1)
    warm = np.array([0.70, 0.84, 0.44], dtype=np.float32)
    rgb = rgb * (1 - clump[..., None] * 0.55) + warm * (clump[..., None] * 0.55)
    rgb += (periodic_noise(size, 32, seed=54, octaves=1)[..., None] - 0.5) * 0.020
    return np.clip(rgb, 0, 1)


def author_transition(size=SIZE):
    """Grass-over-stone band: green top, irregular drips, flat stone below.

    Mapped once up the cliff rim, so it is a vertical gradient and tiles only
    horizontally. Built from the same flat stone and soft grass as the other two
    sheets so the three meet without a motif change.
    """
    rock = author_rock(size)
    grass = author_grass(size)

    v = np.arange(size, dtype=np.float32)[:, None] / (size - 1)   # 0 top row -> 1 bottom row
    x = np.arange(size, dtype=np.float32)[None, :] / size

    # Boundary measured from the top of the sheet, wobbling around and dripping.
    wob = periodic_noise(size, 3, seed=61, octaves=3)[0:1, :]
    drip = periodic_noise(size, 9, seed=62, octaves=2)[0:1, :]
    edge = 0.26 + 0.10 * wob + 0.075 * np.clip(drip - 0.55, 0, 1) / 0.45
    edge = np.repeat(edge, size, axis=0)

    # Soft blend across the boundary, wider where the grass is drooping.
    blend = np.clip((edge - v) / 0.030 + 0.5, 0, 1)[..., None]
    rgb = rock * (1 - blend) + grass * blend

    # Sparse mossy speckle just under the boundary, fading downward.
    near = np.clip(1.0 - (v - edge) / 0.20, 0, 1) * (v > edge)
    speck = np.clip((periodic_noise(size, 16, seed=63, octaves=2) - 0.66) / 0.34, 0, 1)
    moss = np.array([0.44, 0.62, 0.30], dtype=np.float32)
    m = (near * speck * 0.75)[..., None]
    rgb = rgb * (1 - m) + moss * m
    return np.clip(rgb, 0, 1)


def author_planks(size=SIZE, planks=5):
    """Weathered boat planking: lengthwise boards with seams and grain.

    Derived sheets carry the source bark's vertical grain, which on a hull reads
    as rough stone streaks. Boards need banding along the run of the plank, so
    this one is authored rather than regraded.
    """
    y = np.arange(size, dtype=np.float32)[:, None] / size
    x = np.arange(size, dtype=np.float32)[None, :] / size

    board = np.floor(y * planks)
    within = y * planks - board
    # Each board gets its own tone, repeating with the tile so it stays seamless.
    rng = np.random.default_rng(77)
    tone = rng.uniform(-0.055, 0.055, planks).astype(np.float32)
    tone_map = tone[board.astype(int) % planks]

    grain = periodic_noise(size, 6, seed=31, octaves=4)
    fine = periodic_noise(size, 40, seed=32, octaves=2, persistence=0.4)
    # Stretch the grain along the board run.
    grain = np.roll(grain, 0, axis=0) * 0.6 + fine * 0.4
    streak = np.sin((x * 9.0 + grain * 2.4) * np.pi * 2.0) * 0.5 + 0.5

    light = np.array([0.79, 0.67, 0.52], dtype=np.float32)
    dark = np.array([0.55, 0.44, 0.33], dtype=np.float32)
    t = np.clip(0.55 * grain + 0.30 * streak + 0.15 * fine, 0, 1)[..., None]
    rgb = dark + (light - dark) * t
    rgb += tone_map[..., None]

    # Dark seams between boards, and a soft highlight along each board's crown.
    seam = np.clip(1.0 - np.minimum(within, 1 - within) * planks * 2.4, 0, 1)
    rgb -= seam[..., None] * 0.20
    rgb += (np.sin(within * np.pi) ** 2)[..., None] * 0.035
    return np.clip(rgb, 0, 1)


def author_water(size=SIZE):
    """Shallow tide pool: mostly flat pale turquoise, a hint of caustic drift.

    The pools in the reference read as calm colour with sand showing through, so
    contrast is kept deliberately low. A busy caustic pattern looks like
    scribbles once it repeats across a small puddle mesh.
    """
    depth = periodic_noise(size, 2, seed=21, octaves=3)
    caustic = periodic_noise(size, 5, seed=22, octaves=2, persistence=0.45)
    band = np.sin(caustic * np.pi * 3.0) * 0.5 + 0.5

    shallow = np.array([0.66, 0.88, 0.85], dtype=np.float32)
    deep = np.array([0.42, 0.76, 0.78], dtype=np.float32)
    t = np.clip(0.75 * depth + 0.25 * band, 0, 1)[..., None]
    rgb = deep + (shallow - deep) * t
    rgb += (band[..., None] - 0.5) * 0.022
    return np.clip(rgb, 0, 1)


# --------------------------------------------------------------------------
def load(name):
    im = Image.open(DOWNLOADS / SOURCES[name]).convert("RGB")
    return np.asarray(im, dtype=np.float32) / 255.0


def save(rgb, path, size=SIZE):
    im = Image.fromarray((np.clip(rgb, 0, 1) * 255).astype(np.uint8))
    if im.size != (size, size):
        im = im.resize((size, size), Image.LANCZOS)
    im.save(path)
    return path


def main():
    TEX.mkdir(parents=True, exist_ok=True)
    SRC.mkdir(parents=True, exist_ok=True)
    provenance = {"note": "Beach palette derived from the painted sheets already used by the sibling rounded cliff kits. Originals copied unchanged into textures/source/.", "sources": {}, "outputs": {}}

    # Keep the untouched originals alongside the kit.
    for role, filename in SOURCES.items():
        src = DOWNLOADS / filename
        dest = SRC / f"{role}_original.png"
        dest.write_bytes(src.read_bytes())
        provenance["sources"][role] = {
            "original_filename": filename,
            "stored_as": f"textures/source/{role}_original.png",
            "sha256": hashlib.sha256(src.read_bytes()).hexdigest(),
        }
    ref = DOWNLOADS / REFERENCE
    if ref.exists():
        (SRC / "beach-cove-reference.png").write_bytes(ref.read_bytes())
        provenance["sources"]["reference"] = {
            "original_filename": REFERENCE,
            "stored_as": "textures/source/beach-cove-reference.png",
            "sha256": hashlib.sha256(ref.read_bytes()).hexdigest(),
        }

    # ---- beach sheets, recoloured from the supplied mountain set ----------
    def load_mountain(role):
        src = MOUNTAIN_DIR / MOUNTAIN[role]
        im = Image.open(src).convert("RGB")
        dest = SRC / f"mountain_{role}.png"
        im.save(dest)
        provenance["sources"][f"mountain_{role}"] = {
            "original_filename": MOUNTAIN[role],
            "stored_as": f"textures/source/mountain_{role}.png",
            "sha256": hashlib.sha256(src.read_bytes()).hexdigest(),
            "note": "user's mountain sheet, supplied 2026-09-23; recoloured here, not reused as-is",
        }
        return np.asarray(im, dtype=np.float32) / 255.0

    STONE = dict(hue_target=0.090, hue_pull=0.60, sat=0.40, val=1.07, lift=0.022)
    GRASS = dict(hue_target=0.215, hue_pull=0.48, sat=0.70, val=1.13, lift=0.028)

    # Sun-bleached warm grey rather than the mountains' cooler stone.
    rock = regrade(load_mountain("rock"), **STONE)

    # Lighter, yellower grass than the mountain set, as asked for.
    grass = regrade(load_mountain("grass"), **GRASS)

    # The transition sheet has two zones; each gets the matching shift so its
    # grass and rock still meet the standalone sheets.
    tr = load_mountain("transition")
    greenness = np.clip((tr[..., 1] - tr[..., 0]) * 4.0, 0, 1)[..., None]
    transition = regrade(tr, **GRASS) * greenness + regrade(tr, **STONE) * (1 - greenness)

    frond = regrade(load_mountain("frond"), hue_target=0.265, hue_pull=0.40, sat=1.00, val=1.06, lift=0.015)
    palm_bark = regrade(load_mountain("palm_bark"), hue_target=0.095, hue_pull=0.30, sat=0.70, val=1.02, lift=0.020)
    # Shallow tide pool, not open ocean: lift it and pull the saturation back.
    water = regrade(load_mountain("water"), hue_target=0.495, hue_pull=0.35, sat=0.62, val=1.22, lift=0.060)

    driftwood = regrade(load("logbark"), hue_target=0.095, hue_pull=0.38, sat=0.58, val=1.14, lift=0.060)

    # axes: which wrap seams each sheet has to hide in use.
    derived = {
        "rock": (rock, "both"),
        "grass": (grass, "both"),
        "transition": (transition, "x"),   # vertical gradient band; U repeats only
        "frond": (frond, "both"),
        "palm_bark": (palm_bark, "both"),
        "water": (water, "both"),
        "driftwood": (driftwood, "both"),
    }
    authored = {"sand": author_sand(), "boat_wood": author_planks()}
    authored_x = {}

    for name, (rgb, axes) in derived.items():
        before = tile_error(rgb, axes)
        # These sheets are already tileable. Offset-healing one that does not need
        # it smears a band of crisp painted detail across the middle, so only heal
        # when there is a real seam to fix.
        healed = make_seamless(rgb, axes=axes) if before > 0.020 else rgb
        path = save(healed, TEX / f"{name}.png")
        after = tile_error(np.asarray(Image.open(path), dtype=np.float32) / 255.0, axes)
        provenance["outputs"][name] = {
            "file": f"textures/{name}.png",
            "origin": "hue/value regrade of a supplied painted sheet",
            "size": SIZE,
            "tiles": axes,
            "healed": bool(before > 0.020),
            "seam_error_before": round(before, 5),
            "seam_error_after": round(after, 5),
        }
        print(f"{name:11s} tiles {axes:4s} seam {before:.4f} -> {after:.4f}"
              f"{'  (healed)' if before > 0.020 else ''}")

    for name, rgb in list(authored.items()) + list(authored_x.items()):
        axes = "x" if name in authored_x else "both"
        path = save(rgb, TEX / f"{name}.png")
        after = tile_error(np.asarray(Image.open(path), dtype=np.float32) / 255.0, axes)
        provenance["outputs"][name] = {
            "file": f"textures/{name}.png",
            "origin": "authored procedurally in this script; periodic, exactly tiling",
            "size": SIZE,
            "tiles": axes,
            "seam_error_after": round(after, 5),
        }
        print(f"{name:11s} authored, seam {after:.4f}")

    (TEX / "texture-provenance.json").write_text(json.dumps(provenance, indent=2))

    # 3x3 tile proof sheet so the seams can actually be inspected.
    names = list(derived) + list(authored)
    cell = 150
    proof = Image.new("RGB", (cell * 3 * len(names), cell * 3))
    for i, name in enumerate(names):
        im = Image.open(TEX / f"{name}.png").resize((cell, cell), Image.LANCZOS)
        for r in range(3):
            for c in range(3):
                proof.paste(im, (i * cell * 3 + c * cell, r * cell))
    proof.save(ROOT / "previews" / "texture-tiling-proof.png")
    print("wrote", TEX / "texture-provenance.json")


if __name__ == "__main__":
    main()
