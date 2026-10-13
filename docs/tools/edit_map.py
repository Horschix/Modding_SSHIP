#!/usr/bin/env python3
"""Map edits for Modding_SSHIP #4 (13 Oct 2026) - rebuilds the changed map files from the originals.

    python3 docs/tools/edit_map.py backups/2026-10-13_before_map <OUT>

Reads <backup>/data/world/maps/... and writes the same paths under <OUT>:
  base/map_regions.tga       Nicaea's city pixel 291,137 -> 290,136; Sinop's port 335,146 (beside Bafra) -> 331,146
  base/map_ground_types.tga  passes to Karahisar (Afyon): tiles opened to hills
  base/map_heights.tga       heights along the passes smoothed (no cliffs)
  campaign/imperial_campaign/descr_strat.txt   Ioannis Axouchos (Nicaea's governor) 291,137 -> 290,136
  campaign/imperial_campaign/descr_events.txt  event position 291, 137 -> 290, 136
Each TGA is written in its original form (RLE / uncompressed, bit depth, row order, footer) and read back.
After installing, map.rwm must be deleted so the game rebuilds the map; a NEW campaign is needed.
Tile x,y (y from the bottom) = pixel x,y of map_regions; = pixels 2x..2x+2, 2y..2y+2 of the ground/height maps.
"""
import os
import struct
import sys

import numpy as np
from PIL import Image

NICAEA_OLD, NICAEA_NEW = (291, 137), (290, 136)
PORT_OLD, PORT_NEW = (335, 146), (331, 146)   # a port pixel must be a COASTAL LAND tile (all 119 SSHIP ports are)
SEA = (41, 140, 233)
SINOP_RGB = tuple(int(v) for v in '255 255 176'.split())
NICAEA_RGB = (33, 59, 131)
HILLS = (128, 128, 64)
# Kutahya 290,130 -> 291,130 -> 291,129 -> 292,129 -> hills 293,129 / 293,128 -> ... -> Afyon 296,125
# Nicaea -> plains 293,133 / 293,132 -> 293,131 -> 293,130 -> hills 293,129
PASS_TILES = [(291, 130), (291, 129), (292, 129), (293, 131), (293, 130)]


def read_tga(path):
    raw = open(path, "rb").read()
    h = raw[:18]
    idlen, itype = raw[0], raw[2]
    w, hgt = struct.unpack("<HH", raw[12:16])
    bpp, desc = raw[16], raw[17]
    footer = raw[-26:] if raw[-18:-2] == b"TRUEVISION-XFILE" else b""
    return dict(header=h, idlen=idlen, type=itype, w=w, h=hgt, bpp=bpp, desc=desc, footer=footer,
                img=np.array(Image.open(path)))


def rle_encode(rows_bytes, px):
    """TGA RLE per scanline: packets of max 128 pixels."""
    out = bytearray()
    for row in rows_bytes:
        n = len(row) // px
        pix = [row[i * px:(i + 1) * px] for i in range(n)]
        i = 0
        while i < n:
            j = i + 1
            while j < n and j - i < 128 and pix[j] == pix[i]:
                j += 1
            if j - i > 1:
                out.append(0x80 | (j - i - 1))
                out += pix[i]
                i = j
            else:
                j = i + 1
                while j < n and j - i < 128 and (j + 1 >= n or pix[j] != pix[j + 1]):
                    j += 1
                out.append(j - i - 1)
                for k in range(i, j):
                    out += pix[k]
                i = j
    return bytes(out)


def write_tga(meta, img, path):
    px = meta["bpp"] // 8
    top_first = bool(meta["desc"] & 0x20)
    rows = img if top_first else img[::-1]
    rows_bytes = []
    for r in rows:
        if px == 4:
            b = r[:, [2, 1, 0, 3]]
        else:
            b = r[:, [2, 1, 0]]
        rows_bytes.append(b.astype(np.uint8).tobytes())
    body = rle_encode(rows_bytes, px) if meta["type"] == 10 else b"".join(rows_bytes)
    with open(path, "wb") as f:
        f.write(meta["header"] + body + meta["footer"])
    back = np.array(Image.open(path))
    assert back.shape == img.shape and (back == img).all(), "read-back differs: " + path


def tile_block(img, x, y):
    H = img.shape[0]
    return (slice(H - 1 - (2 * y + 2), H - (2 * y)), slice(2 * x, 2 * x + 3))


def main(src, out):
    base_in = os.path.join(src, "data/world/maps/base")
    camp_in = os.path.join(src, "data/world/maps/campaign/imperial_campaign")
    base_out = os.path.join(out, "data/world/maps/base")
    camp_out = os.path.join(out, "data/world/maps/campaign/imperial_campaign")
    os.makedirs(base_out, exist_ok=True)
    os.makedirs(camp_out, exist_ok=True)

    # regions
    m = read_tga(os.path.join(base_in, "map_regions.tga"))
    a = m["img"].copy()
    H = a.shape[0]

    def px(p):
        return H - 1 - p[1], p[0]
    assert tuple(a[px(NICAEA_OLD)][:3]) == (0, 0, 0) and tuple(a[px(NICAEA_NEW)][:3]) == NICAEA_RGB
    assert tuple(a[px(PORT_OLD)][:3]) == (255, 255, 255) and tuple(a[px(PORT_NEW)][:3]) == SINOP_RGB
    a[px(NICAEA_OLD)][:3] = NICAEA_RGB
    a[px(NICAEA_NEW)][:3] = (0, 0, 0)
    a[px(PORT_OLD)][:3] = SINOP_RGB      # the old port tile is land: it becomes part of the Sinop region
    a[px(PORT_NEW)][:3] = (255, 255, 255)
    write_tga(m, a, os.path.join(base_out, "map_regions.tga"))
    print("regions: Nicaea", NICAEA_OLD, "->", NICAEA_NEW, ", Sinop port", PORT_OLD, "->", PORT_NEW)

    # ground types
    g = read_tga(os.path.join(base_in, "map_ground_types.tga"))
    ga = g["img"].copy()
    for t in PASS_TILES:
        before = tuple(int(v) for v in ga[tile_block(ga, *t)][1, 1])
        ga[tile_block(ga, *t)] = HILLS
        print("ground", t, before, "-> hills")
    write_tga(g, ga, os.path.join(base_out, "map_ground_types.tga"))

    # heights: each pass tile and its border pixels get the mean of a 5x5 neighbourhood (land only)
    hm = read_tga(os.path.join(base_in, "map_heights.tga"))
    ha = hm["img"].copy()
    orig = hm["img"][:, :, 0].astype(float)
    HH = ha.shape[0]
    for t in PASS_TILES:
        rs, cs = tile_block(ha, *t)
        changed = []
        for r in range(rs.start, rs.stop):
            for c in range(cs.start, cs.stop):
                if tuple(ha[r, c]) != (ha[r, c, 0],) * 3:
                    continue    # water (blue) - leave alone
                v = int(round(orig[max(r - 2, 0):r + 3, max(c - 2, 0):c + 3].mean()))
                changed.append((int(ha[r, c, 0]), v))
                ha[r, c] = (v, v, v)
        print("heights", t, changed)
    write_tga(hm, ha, os.path.join(base_out, "map_heights.tga"))

    # descr_strat / descr_events (latin-1, line endings kept)
    for name, old, new in (("descr_strat.txt", b"x 291, y 137", b"x 290, y 136"),
                           ("descr_events.txt", b"position\t291, 137", b"position\t290, 136")):
        data = open(os.path.join(camp_in, name), "rb").read()
        assert data.count(old) == 1, (name, data.count(old))
        open(os.path.join(camp_out, name), "wb").write(data.replace(old, new))
        print(name, old.decode(), "->", new.decode())


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
