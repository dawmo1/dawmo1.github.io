"""Chunky outlined game icons (coin, gem, cash, heart, skull, star, lock, plus, wave, gift) as 256px PNGs.
Run with Blender's bundled Python (has numpy):  <blender python> make_icons.py <out_dir>"""
import sys, os, math, zlib, struct
import numpy as np
OUT = sys.argv[1] if len(sys.argv) > 1 else "assets/icons"; os.makedirs(OUT, exist_ok=True)
S = 256; ys, xs = np.mgrid[0:S, 0:S]; X = (xs - S / 2 + 0.5) / (S / 2); Y = -(ys - S / 2 + 0.5) / (S / 2)
R = np.hypot(X, Y); A = np.arctan2(Y, X)
def write_png(path, rgba):
    a = (np.clip(rgba, 0, 1) * 255 + 0.5).astype(np.uint8); h, w, _ = a.shape
    raw = b"".join(b"\x00" + a[y].tobytes() for y in range(h))
    def ch(t, d): return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
    open(path, "wb").write(b"\x89PNG\r\n\x1a\n" + ch(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)) + ch(b"IDAT", zlib.compress(raw, 9)) + ch(b"IEND", b""))
def hexc(h): h = h.lstrip('#'); return np.array([int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)])
def aa(sd, w=0.012): return np.clip(0.5 - sd / w, 0, 1)   # signed distance -> coverage
def compose(layers):
    """layers: list of (signed_distance, color, extra_shade). Draws a dark outline around the union, then fills in order."""
    out = np.zeros((S, S, 4)); ink = hexc("#1A1018")
    union = np.min([l[0] for l in layers], axis=0)
    o = aa(union - 0.075)                                  # thick outline
    out[..., :3] = ink; out[..., 3] = o
    for sd, col, shade in layers:
        c = aa(sd); rgb = np.clip(col * (1 + shade[..., None] if shade is not None else col), 0, 1) if shade is not None else col
        out[..., :3] = out[..., :3] * (1 - c[..., None]) + rgb * c[..., None]; out[..., 3] = np.maximum(out[..., 3], c)
    return out
def box(cx, cy, hw, hh, r=0.0):
    q = np.stack([np.abs(X - cx) - hw + r, np.abs(Y - cy) - hh + r]); return np.hypot(np.maximum(q[0], 0), np.maximum(q[1], 0)) + np.minimum(np.maximum(q[0], q[1]), 0) - r
def circ(cx, cy, r): return np.hypot(X - cx, Y - cy) - r
def poly(pts):
    d = np.full(X.shape, 9.0); inside = np.zeros(X.shape, bool); n = len(pts)
    for i in range(n):
        (ax, ay), (bx, by) = pts[i], pts[(i + 1) % n]; vx, vy = bx - ax, by - ay
        t = np.clip(((X - ax) * vx + (Y - ay) * vy) / (vx * vx + vy * vy), 0, 1)
        d = np.minimum(d, np.hypot(X - ax - t * vx, Y - ay - t * vy))
        cond = ((ay > Y) != (by > Y)) & (X < (bx - ax) * (Y - ay) / (by - ay + 1e-9) + ax); inside ^= cond
    return np.where(inside, -d, d)
top_light = np.clip(Y * 0.35, -0.25, 0.3)   # simple top-lit shading

icons = {}
icons["coin"] = compose([(circ(0, 0, 0.72), hexc("#FFC21A"), top_light), (circ(0, 0, 0.5), hexc("#FFE066"), top_light),
                          (box(0, 0, 0.08, 0.3, 0.04), hexc("#E09A00"), None)])
icons["gem"] = compose([(poly([(0, -0.8), (0.72, 0.1), (0.42, 0.55), (-0.42, 0.55), (-0.72, 0.1)]), hexc("#33C6FF"), top_light),
                         (poly([(0, -0.8), (0.3, 0.1), (-0.3, 0.1)]), hexc("#8DEBFF"), None), (poly([(-0.42, 0.55), (0.42, 0.55), (0.3, 0.1), (-0.3, 0.1)]), hexc("#B8F4FF"), None)])
icons["cash"] = compose([(box(0, 0, 0.78, 0.46, 0.08), hexc("#3BD16F"), top_light), (circ(0, 0, 0.22), hexc("#1E9E4A"), None),
                          (box(-0.58, 0.28, 0.08, 0.08, 0.04), hexc("#1E9E4A"), None), (box(0.58, -0.28, 0.08, 0.08, 0.04), hexc("#1E9E4A"), None)])
hx, hy = X / 0.78, (Y + 0.12) / 0.78
heart = (hx ** 2 + (hy - np.sqrt(np.abs(hx)) * 0.62) ** 2) - 0.7
icons["heart"] = compose([(heart * 0.6, hexc("#FF3B5C"), top_light), (circ(-0.28, 0.2, 0.12), hexc("#FF9DB0"), None)])
icons["skull"] = compose([(np.minimum(circ(0, 0.12, 0.62), box(0, -0.45, 0.36, 0.22, 0.08)), hexc("#F2EDE4"), top_light),
                           (circ(-0.24, 0.08, 0.16), hexc("#2A1F2A"), None), (circ(0.24, 0.08, 0.16), hexc("#2A1F2A"), None),
                           (poly([(0, -0.12), (0.08, -0.26), (-0.08, -0.26)]), hexc("#2A1F2A"), None)])
star_pts = [((0.8 if i % 2 == 0 else 0.36) * math.cos(math.pi / 2 + i * math.pi / 5), (0.8 if i % 2 == 0 else 0.36) * math.sin(math.pi / 2 + i * math.pi / 5) - 0.04) for i in range(10)]
icons["star"] = compose([(poly(star_pts), hexc("#FFD23F"), top_light)])
icons["lock"] = compose([(np.abs(circ(0, 0.18, 0.36)) - 0.09 + np.where(Y < 0.18, 1, 0), hexc("#C9CED8"), None), (box(0, -0.25, 0.55, 0.42, 0.1), hexc("#FFC21A"), top_light),
                          (circ(0, -0.18, 0.1), hexc("#5A3A00"), None)])
icons["plus"] = compose([(np.minimum(box(0, 0, 0.62, 0.2, 0.08), box(0, 0, 0.2, 0.62, 0.08)), hexc("#5BE36B"), top_light)])
icons["gift"] = compose([(box(0, -0.18, 0.62, 0.5, 0.06), hexc("#FF5A8A"), top_light), (box(0, 0.38, 0.72, 0.16, 0.05), hexc("#FF7AA0"), None),
                          (box(0, -0.05, 0.12, 0.62, 0.02), hexc("#FFD23F"), None), (circ(-0.22, 0.62, 0.17), hexc("#FFD23F"), None), (circ(0.22, 0.62, 0.17), hexc("#FFD23F"), None)])
icons["sword"] = compose([(poly([(-0.62, -0.62), (0.5, 0.5), (0.72, 0.72), (0.5, 0.72), (-0.72, -0.5)]), hexc("#DDE6F0"), top_light),
                           (poly([(-0.42, -0.2), (-0.2, -0.42), (-0.06, -0.3), (-0.3, -0.06)]), hexc("#FFC21A"), None)])
icons["shield"] = compose([(poly([(0, 0.78), (0.64, 0.5), (0.58, -0.15), (0, -0.8), (-0.58, -0.15), (-0.64, 0.5)]), hexc("#4AA3FF"), top_light),
                            (poly([(0, 0.5), (0.36, 0.34), (0.32, -0.08), (0, -0.48)]), hexc("#9AD0FF"), None)])
icons["wave"] = compose([(np.minimum(np.minimum(box(-0.42, -0.2, 0.14, 0.4, 0.06), box(0, 0, 0.14, 0.6, 0.06)), box(0.42, 0.15, 0.14, 0.45, 0.06)), hexc("#FF7A1A"), top_light)])
for k, v in icons.items(): write_png(f"{OUT}/{k}.png", v); print("icon", k)
