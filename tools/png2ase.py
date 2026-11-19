#!/usr/bin/env python3
"""Convert PNG files to LibreSprite/Aseprite .ase (single frame, RGBA, raw cel).

Writes a valid minimal ASE: header + frame with old-palette, layer and cel
chunks — the same layout tools/ase2png.py parses. Existing .ase files are
never overwritten.

Usage: python3 tools/png2ase.py file1.png [file2.png ...]
"""
import os
import struct
import sys

from PIL import Image


def build_ase(im, name):
    w, h = im.size
    if im.mode != "RGBA":
        im = im.convert("RGBA")
    pixels = im.tobytes()

    # palette from the sprite's own colors (max 256)
    colors = []
    for count, (r, g, b, a) in sorted(im.getcolors(maxcolors=100000), reverse=True):
        if a > 0 and (r, g, b) not in colors:
            colors.append((r, g, b))
        if len(colors) >= 256:
            break

    palette = bytearray()
    palette += struct.pack("<H", 1)  # one packet
    n = len(colors)
    palette += struct.pack("<BB", 0, 0 if n == 256 else n)
    for (r, g, b) in colors:
        palette += bytes((r, g, b))

    layer_name = name.encode("utf-8")
    layer = struct.pack(
        "<6H", 1, 0, 0, w, h, 0
    ) + bytes((255, 0, 0, 0)) + struct.pack("<H", len(layer_name)) + layer_name

    cel = (
        struct.pack("<HhhBHH", 0, 0, 0, 255, 0, 0)  # layer, x, y, opacity, raw cel, z
        + bytes(5)                                  # reserved
        + struct.pack("<2H", w, h)
        + pixels
    )

    chunks = [
        (0x2019, bytes(palette)),
        (0x2004, layer),
        (0x2005, cel),
    ]

    body = b""
    for ctype, data in chunks:
        body += struct.pack("<IH", 6 + len(data), ctype) + data

    frame = struct.pack(
        "<IHHHBBI", 16 + len(body), 0xF1FA, 0xFFFF, 100, 0, 0, len(chunks)
    ) + body

    header = bytearray(128)
    struct.pack_into("<IHHHHHIHIB", header, 0,
                     128 + len(frame), 0xA5E0, 1, w, h, 32, 1, 100, 0, 0)
    header[28] = len(colors) or 0
    return bytes(header) + frame


def main():
    for path in sys.argv[1:]:
        dst = os.path.splitext(path)[0] + ".ase"
        if os.path.exists(dst):
            print("skip (exists):", dst)
            continue
        im = Image.open(path)
        name = os.path.splitext(os.path.basename(path))[0]
        with open(dst, "wb") as f:
            f.write(build_ase(im, name))
        print("wrote", dst, im.size)


if __name__ == "__main__":
    main()
