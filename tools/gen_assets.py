#!/usr/bin/env python3
"""Generate remaining makedam assets (corners, grass, sand, rock, checkpoint
flag, sfx) derived from road-straight.png + audi-red-top-detail.png so the
palette stays identical to hand-drawn art. Deterministic: fixed seed.

Usage: python3 tools/gen_assets.py   (run from repo root)
Skips start/finish — that one is hand-made.
"""
import math
import os
import random
import struct
import wave

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(ROOT, "assets")
SFX = os.path.join(ASSETS, "sfx")
TILE = 32  # road tiles are 32x32 (2x2 of the 16px grid)

random.seed(11)

# ---- palette (extracted from existing art) ----
GREEN_DARK = (75, 105, 47)
GREEN_LIGHT = (86, 105, 47)
GRAYS = [(110, 106, 106), (105, 106, 106), (97, 94, 94), (89, 86, 82), (84, 82, 82), (79, 77, 77)]
SAND_BASE = (150, 132, 94)
SAND_MID = (138, 120, 84)
SAND_DARK = (126, 108, 74)
ROCK_OUTLINE = (52, 50, 48)


def car_palette():
    im = Image.open(os.path.join(ASSETS, "audi-red-top-detail.png")).convert("RGBA")
    reds = {}
    for count, px in im.getcolors(maxcolors=10000):
        r, g, b, a = px
        if a > 0 and r > g + 30 and r > b + 30:
            reds[px[:3]] = reds.get(px[:3], 0) + count
    ordered = sorted(reds, key=lambda c: -reds[c])
    return ordered[0], ordered[-1]  # mid red, dark red


def speckled(base, alt, alt_chance, w=TILE, h=TILE):
    im = Image.new("RGB", (w, h), base)
    px = im.load()
    for y in range(h):
        for x in range(w):
            if random.random() < alt_chance:
                px[x, y] = alt
    return im


def save(im, name):
    path = os.path.join(ASSETS, name)
    im.save(path)
    print("wrote", os.path.relpath(path, ROOT))


# ---- grass / sand tiles ----
def gen_grass():
    save(speckled(GREEN_DARK, GREEN_LIGHT, 0.12), "grass-1.png")
    im2 = speckled(GREEN_DARK, GREEN_LIGHT, 0.10)
    px = im2.load()
    for _ in range(14):  # a few tiny grass tufts
        x, y = random.randrange(2, TILE - 2), random.randrange(2, TILE - 2)
        px[x, y] = GREEN_LIGHT
        px[x + 1, y] = GREEN_DARK
        px[x, y + 1] = GREEN_LIGHT
    save(im2, "grass-2.png")


def gen_sand():
    im = Image.new("RGB", (TILE, TILE), SAND_BASE)
    px = im.load()
    for y in range(TILE):
        for x in range(TILE):
            r = random.random()
            if r < 0.10:
                px[x, y] = SAND_MID
            elif r < 0.14:
                px[x, y] = SAND_DARK
    save(im, "sand.png")


# ---- road corners: one elbow, derived via transforms ----
def gen_corners():
    road = Image.open(os.path.join(ASSETS, "road-straight.png")).convert("RGB")
    hroad = road.transpose(Image.ROTATE_90)  # streaks now horizontal

    # elbow connecting WEST edge + SOUTH edge; grass in top-right quadrant
    corner = hroad.copy()
    grass = speckled(GREEN_DARK, GREEN_LIGHT, 0.10)
    corner.paste(grass.crop((0, 0, TILE // 2, TILE // 2)), (TILE // 2, 0))

    px = corner.load()
    # speckle blend along the two inner edges (mirrors road-straight's edges)
    for i in range(1, 3):
        for _ in range(6):
            x = TILE // 2 + i
            y = random.randrange(TILE // 2)
            if random.random() < 0.5:
                px[x, y] = random.choice([GREEN_DARK, GREEN_LIGHT])
        for _ in range(6):
            x = random.randrange(TILE // 2, TILE)
            y = TILE // 2 - i
            if random.random() < 0.5:
                px[x, y] = random.choice([GREEN_DARK, GREEN_LIGHT])
        # road side of the boundary: grass speckles
        for _ in range(4):
            x = TILE // 2 - i
            y = random.randrange(TILE // 2)
            px[x, y] = random.choice([GREEN_DARK, GREEN_LIGHT])
        for _ in range(4):
            x = random.randrange(TILE // 2, TILE)
            y = TILE // 2 + i - 1
            px[x, y] = random.choice([GREEN_DARK, GREEN_LIGHT])

    variants = {
        "road-corner-es.png": corner.transpose(Image.FLIP_LEFT_RIGHT),   # East + South
        "road-corner-wn.png": corner.transpose(Image.FLIP_TOP_BOTTOM),   # West + North
        "road-corner-en.png": corner.transpose(Image.ROTATE_180),        # East + North
    }
    save(corner, "road-corner-ws.png")
    for name, im in variants.items():
        save(im, name)


# ---- rock (obstacle) ----
def gen_rock():
    w, h = 24, 20
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = im.load()
    cx, cy = w / 2, h / 2
    for y in range(h):
        for x in range(w):
            dx, dy = x - cx, (y - cy) * 1.25
            d = math.hypot(dx, dy) + random.random() * 1.2
            if d < 9.5:
                shade = random.choice(GRAYS[:5]) if d > 6.5 or x < cx else random.choice(GRAYS[:2])
                px[x, y] = shade + (255,)
    # outline pass
    solid = {(x, y) for y in range(h) for x in range(w) if px[x, y][3] > 0}
    for (x, y) in list(solid):
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if (nx, ny) not in solid and 0 <= nx < w and 0 <= ny < h:
                px[nx, ny] = ROCK_OUTLINE + (255,)
    save(im, "rock.png")


# ---- checkpoint flag ----
def gen_checkpoint():
    mid, dark = car_palette()
    w, h = 16, 24
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = im.load()
    pole_x = 4
    for y in range(2, h):  # pole
        px[pole_x, y] = GRAYS[5] + (255,)
        px[pole_x + 1, y] = GRAYS[1] + (255,)
    px[pole_x, 1] = GRAYS[1] + (255,)  # pole cap
    for fy in range(3, 11):  # flag
        for fx in range(pole_x + 2, pole_x + 12):
            edge = fy in (3, 10) or fx == pole_x + 11
            px[fx, fy] = (dark if edge else mid) + (255,)
    save(im, "checkpoint.png")


# ---- sfx ----
def write_wav(name, samples, rate=22050):
    path = os.path.join(SFX, name)
    os.makedirs(SFX, exist_ok=True)
    with wave.open(path, "w") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(rate)
        frames = b"".join(struct.pack("<h", max(-32767, min(32767, int(s * 32767)))) for s in samples)
        f.writeframes(frames)
    print("wrote", os.path.relpath(path, ROOT), f"{len(samples)/rate:.2f}s")


def gen_sfx():
    rate = 22050

    # engine loop: 1.0s, integer-cycle partials so the loop is seamless
    n = rate
    eng = []
    for i in range(n):
        t = i / rate
        vib = 1.0 + 0.03 * math.sin(2 * math.pi * 2 * t)
        v = 0.5 * math.sin(2 * math.pi * 88 * vib * t)
        v += 0.3 * math.sin(2 * math.pi * 132 * t)
        v += 0.15 * math.sin(2 * math.pi * 176 * t)
        v += 0.05 * (random.random() * 2 - 1)
        eng.append(v * 0.6)
    write_wav("engine.wav", eng)

    # checkpoint ping
    n = int(0.18 * rate)
    ping = [0.8 * math.exp(-i / (rate * 0.04)) * math.sin(2 * math.pi * 1318 * i / rate) for i in range(n)]
    write_wav("checkpoint.wav", ping)

    # lap done: little arpeggio
    notes = [(523, 0.0), (659, 0.12), (784, 0.24), (1047, 0.36)]
    n = int(0.6 * rate)
    lap = [0.0] * n
    for freq, start in notes:
        s0 = int(start * rate)
        for i in range(s0, min(n, s0 + int(0.22 * rate))):
            lap[i] += 0.5 * math.exp(-(i - s0) / (rate * 0.07)) * math.sin(2 * math.pi * freq * (i - s0) / rate)
    write_wav("lap_done.wav", lap)

    # crash: noise burst + low thump
    n = int(0.35 * rate)
    crash = []
    for i in range(n):
        env = math.exp(-i / (rate * 0.08))
        v = 0.6 * env * (random.random() * 2 - 1)
        v += 0.5 * env * math.sin(2 * math.pi * 70 * i / rate)
        crash.append(v)
    write_wav("crash.wav", crash)




def gen_horizontal_road():
    im = Image.open(os.path.join(ASSETS, "road-straight.png")).convert("RGB")
    save(im.transpose(Image.ROTATE_90), "road-straight-h.png")


if __name__ == "__main__":
    gen_grass()
    gen_sand()
    gen_corners()
    gen_rock()
    gen_checkpoint()
    gen_sfx()
    gen_horizontal_road()
    print("done — start/finish left for hand-drawing")
