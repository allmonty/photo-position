#!/usr/bin/env python3
"""Reads a raw `adb exec-out screencap` from stdin and checks that the shape
border is drawn at the middle of all four edges of the rectangle "l t r b"
(px, argv[1:5]) with border half-width argv[5] px inside the edge. The border
is the default gold unless argv[6] gives an opaque colour as RRGGBB hex.
Exits 1 with a message if any edge is not gold: this catches a shape that the
window has the right size for but that the Flutter view did not redraw."""
import struct
import sys

data = sys.stdin.buffer.read()
w, h, _fmt = struct.unpack("<III", data[:12])
pix = data[12:]
l, t, r, b = (int(v) for v in sys.argv[1:5])
inset = int(sys.argv[5])


def px(x, y):
    i = (y * w + x) * 4
    return pix[i], pix[i + 1], pix[i + 2]


want = None
if len(sys.argv) > 6:
    h = sys.argv[6]
    want = tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def gold(c):
    if want is not None:
        return all(abs(a - b) <= 40 for a, b in zip(c, want))
    # default border colour is E9C349 at ~78% alpha over the dark background
    return c[0] > 140 and c[1] > 110 and c[2] < 110 and c[0] > c[2] + 60


edges = {
    "left": (l + inset, (t + b) // 2),
    "right": (r - inset, (t + b) // 2),
    "top": ((l + r) // 2, t + inset),
    "bottom": ((l + r) // 2, b - inset),
}
bad = [f"{n}@{p}={px(*p)}" for n, p in edges.items() if not gold(px(*p))]
if bad:
    print("border not drawn at:", ", ".join(bad))
    sys.exit(1)
