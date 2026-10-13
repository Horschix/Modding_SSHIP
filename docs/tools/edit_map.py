#!/usr/bin/env python3
"""Map edits for Modding_SSHIP #4 (13 Oct 2026) - rebuilds the changed map files from the originals.

    python3 docs/tools/edit_map.py backups/2026-10-13_before_map <OUT>

Reads <backup>/data/world/maps/... and writes the same paths under <OUT>:
  base/map_regions.tga       Nicaea's city pixel 291,137 -> 290,136; Sinop's port 335,146 (beside Bafra) -> 331,146
  base/map_ground_types.tga  passes (Karahisar, Kastamonu, south coast, Konya - Alanya) opened to hills;
                             impassable tiles of the Kastamonu belt -> dense forest
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
DENSE_FOREST = (0, 64, 0)
IMPASSABLE = (64, 64, 64)
# tile -> new ground type. Heights of every tile listed here are smoothed.
PASS_TILES = {}
def _hills(*tiles):
    for t in tiles:
        PASS_TILES[t] = HILLS
# round 1 (13 Oct): Kutahya 290,130 -> 291,130 -> 291,129 -> 292,129 -> hills 293,129 -> ... -> Karahisar (Afyon) 296,125
#                   Nicaea -> plains 293,133 / 293,132 -> 293,131 -> 293,130 -> hills 293,129
_hills((291, 130), (291, 129), (292, 129), (293, 131), (293, 130))
# round 2 (13 Oct): Kastamonu 319,143 - valley 318-320 x 142-144, south to 319,140, east along row 143 to 326,143
_hills(*[(x, y) for x in range(318, 321) for y in range(142, 145)])
_hills((319, 141))
# south coast Attaleia -> Alanya 307,110 -> Tarsus: 303,111 (hills) -> 304,111 -> 305,110 -> 306,110 -> 307,110 ->
# 308,110 -> row 109 from 308 to 321 -> hills 322,109 ...
_hills((304, 111), (305, 110), (306, 110), (307, 110), (308, 110))
# (round 2 also had a row-109 coast corridor and the Konya tiles - replaced by the CORRIDORS of round 3)
# every remaining IMPASSABLE tile of the Kastamonu belt (x 312-327, y 141-147) -> dense forest (not smoothed)
FOREST_BOX = (312, 327, 141, 147)

# Round 3 (13 Oct, after the engine dump): what really blocks the engine - dense forest costs 999 in SSHIP (as
# impassable), rivers only open at crossings, no diagonal step between two blocked tiles, and big height steps
# (38 in tile.height/10 units passes, 60+ does not). tile.height/10 = 2.393 * grey value of the tile's centre pixel.
# So every route is a chain of hill tiles whose heights ramp evenly between the two ends.
# (name, ordered tiles, start height, end height) - heights in tile.height/10 units; the ends of the list are set too.
H10_PER_GREY = 2.393
CORRIDORS = [
    ("Kastamonu-Sinop", [(320, 143), (321, 143), (322, 143), (323, 143), (324, 143), (325, 143), (326, 143),
                         (327, 143), (327, 144), (327, 145), (327, 146), (327, 147)], 177, 14),
    ("Kastamonu-north coast", [(319, 144), (319, 145), (319, 146), (319, 147), (319, 148)], 177, 45),
    ("Kastamonu-Nikomedeia", [(x, 143) for x in range(318, 303, -1)], 177, 2),
    ("Konya-Alanya", [(310, 117), (310, 116), (310, 115), (310, 114), (310, 113), (310, 112), (309, 112),
                      (309, 111), (308, 111), (308, 110)], 177, 93),
    ("Alanya-Tarsus coast", [(308, 109), (309, 108), (310, 107), (311, 106), (312, 106), (313, 106), (314, 106),
                             (315, 106), (316, 107), (317, 107), (318, 107), (319, 107), (320, 107), (321, 108),
                             (322, 108)], 93, 2),
]
MAX_STEP = 12


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
    for t, ground in PASS_TILES.items():
        before = tuple(int(v) for v in ga[tile_block(ga, *t)][1, 1])
        ga[tile_block(ga, *t)] = ground
        print("ground", t, before, "->", ground)
    for name, tiles, _, _ in CORRIDORS:
        for t in tiles:
            ga[tile_block(ga, *t)] = HILLS
        print("ground corridor", name, len(tiles), "tiles -> hills")
    x0, x1, y0, y1 = FOREST_BOX
    for x in range(x0, x1 + 1):
        for y in range(y0, y1 + 1):
            if (x, y) not in PASS_TILES and tuple(int(v) for v in ga[tile_block(ga, x, y)][1, 1]) == IMPASSABLE:
                ga[tile_block(ga, x, y)] = DENSE_FOREST
                print("ground", (x, y), IMPASSABLE, "-> dense forest")
    write_tga(g, ga, os.path.join(base_out, "map_ground_types.tga"))

    # heights: each pass tile gets the mean of a 5x5 neighbourhood (land only), repeated (up to 4 rounds) while the
    # steepest step inside the tile is above MAX_STEP
    hm = read_tga(os.path.join(base_in, "map_heights.tga"))
    ha = hm["img"].copy()

    def steepest(t):
        rs, cs = tile_block(ha, *t)
        blk = ha[rs, cs, 0].astype(int)
        return int(max(np.abs(np.diff(blk, axis=0)).max(), np.abs(np.diff(blk, axis=1)).max()))
    for t in PASS_TILES:
        start = steepest(t)
        for _ in range(4):
            cur = ha[:, :, 0].astype(float)
            rs, cs = tile_block(ha, *t)
            for r in range(rs.start, rs.stop):
                for c in range(cs.start, cs.stop):
                    if not (ha[r, c, 0] == ha[r, c, 1] == ha[r, c, 2]):
                        continue    # water (blue) - leave alone
                    v = int(round(cur[max(r - 2, 0):r + 3, max(c - 2, 0):c + 3].mean()))
                    ha[r, c] = (v, v, v)
            if steepest(t) <= MAX_STEP:
                break
        print("heights", t, "steepest step", start, "->", steepest(t))
    # corridors: whole 3x3 block of each tile = its ramp height (flat tile, even steps between tiles)
    for name, tiles, h0, h1 in CORRIDORS:
        n = len(tiles)
        steps = []
        for i, tl in enumerate(tiles):
            h10 = h0 + (h1 - h0) * (i + 1) / (n + 1) if n > 1 else (h0 + h1) / 2
            grey = int(round(h10 / H10_PER_GREY))
            rs, cs = tile_block(ha, *tl)
            for r in range(rs.start, rs.stop):
                for c in range(cs.start, cs.stop):
                    if ha[r, c, 0] == ha[r, c, 1] == ha[r, c, 2]:      # leave water pixels alone
                        ha[r, c] = (grey, grey, grey)
            steps.append(grey)
        print("heights corridor", name, "grey", steps, "(step about", round(abs(h1 - h0) / (n + 1), 1), "h10)")
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
