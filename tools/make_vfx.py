"""Procedural Roblox VFX textures: 4x4 flipbook sheets (1024px, 256px cells), white + alpha so a
ParticleEmitter's Color tints them, plus coloured preview frames for GIFs.
Run with Blender's bundled Python (has numpy):  <blender python> make_vfx.py <out_dir>"""
import sys, os, zlib, struct, math
import numpy as np

OUT = sys.argv[1] if len(sys.argv) > 1 else "vfx"
CELL, GRID = 256, 4
N = GRID * GRID
os.makedirs(f"{OUT}/sheets", exist_ok=True); os.makedirs(f"{OUT}/textures", exist_ok=True); os.makedirs(f"{OUT}/_frames", exist_ok=True)

def write_png(path, rgba):
    a = (np.clip(rgba, 0, 1) * 255 + 0.5).astype(np.uint8)
    h, w, _ = a.shape
    raw = b"".join(b"\x00" + a[y].tobytes() for y in range(h))
    def chunk(t, d): return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))

ys, xs = np.mgrid[0:CELL, 0:CELL]
X = (xs - CELL / 2 + 0.5) / (CELL / 2); Y = -(ys - CELL / 2 + 0.5) / (CELL / 2)   # -1..1, y up
R = np.hypot(X, Y); A = np.arctan2(Y, X)
rng = np.random.default_rng(7)

def smooth(e0, e1, x):
    d = np.asarray(e1 - e0, dtype=float)
    d = np.where(np.abs(d) > 1e-6, d, np.where(d > 0, 1e-6, -1e-6))  # an effect shrunk to zero size
    t = np.clip((x - e0) / d, 0, 1); return t * t * (3 - 2 * t)
def ease_out(t): return 1 - (1 - t) ** 3

def periodic_noise(px, py, t, scale=4, seed=0):
    """Value noise, tileable in time: samples a 3D lattice where the time axis wraps."""
    r = np.random.default_rng(seed); G = r.random((scale, scale, 8))  # wraps in x, y and time
    u = (px * 0.5 + 0.5) * scale; v = (py * 0.5 + 0.5) * scale; w = (t % 1.0) * 8
    i, j, k = np.floor(u).astype(int) % scale, np.floor(v).astype(int) % scale, int(w) % 8
    fu, fv, fw = u - np.floor(u), v - np.floor(v), w - math.floor(w)
    fu, fv = fu * fu * (3 - 2 * fu), fv * fv * (3 - 2 * fv)
    def L(kk):
        i1, j1 = (i + 1) % scale, (j + 1) % scale
        a = G[i, j, kk] * (1 - fu) + G[i1, j, kk] * fu
        b = G[i, j1, kk] * (1 - fu) + G[i1, j1, kk] * fu
        return a * (1 - fv) + b * fv
    return L(k) * (1 - fw) + L((k + 1) % 8) * fw

def fbm(px, py, t, seed=0):
    return sum(periodic_noise(px * (2 ** o), py * (2 ** o), t, 4 * (2 ** o), seed + o) * (0.5 ** o) for o in range(3)) / 1.75

# ---- effects: each returns intensity I in 0..1 (alpha), white core where I is high ----
# Timing rule for one-shots: the action lives in frames 0-8 (t < 0.55); the rest dissipates fast.
def slash(t):
    # elliptical smear: a crescent tapered at both ends, thick and white at the leading edge
    p = ease_out(min(1, t / 0.5))                           # swing finishes by frame 8
    head = math.radians(165 - 250 * p)
    trail = math.radians(40 + 110 * min(1, t / 0.25)) * (1 - 0.6 * smooth(0.45, 1.0, t))
    Xe, Ye = X / 1.0, Y / 0.72                              # squash into an ellipse so it reads as a swing, not a clock
    Re, Ae = np.hypot(Xe, Ye), np.arctan2(Ye, Xe)
    d = (Ae - head) % (2 * math.pi)
    u = np.where(d < trail, d / np.maximum(trail, 1e-3), 1.0)   # 0 at the head, 1 at the tail end
    shape = np.sin(np.pi * np.clip(u, 0, 1) ** 0.55) * (d < trail)   # tapers at both ends, fattest near the head
    rad = 0.74 - 0.08 * u; thick = 0.02 + 0.17 * shape
    band = smooth(thick, thick * 0.3, np.abs(Re - rad)) * shape
    edge = smooth(thick * 0.5, 0.0, np.abs(Re - (rad + thick * 0.35))) * (1 - u) * (d < trail)   # bright leading rim
    I = np.clip(band * 0.8 + edge, 0, 1) * (1 - smooth(0.55, 0.9, t))
    rr = np.random.default_rng(3)
    for k in range(7):  # irregular flecks thrown off the outer edge
        ang = head + 0.15 + rr.random() * 1.2; dist = 0.82 + rr.random() * 0.15 + t * (0.2 + 0.3 * rr.random())
        sz = 0.012 + rr.random() * 0.03
        I = np.maximum(I, smooth(sz, 0.0, np.hypot(X - dist * math.cos(ang), Y - dist * 0.72 * math.sin(ang))) * (1 - smooth(0.3, 0.8, t)))
    return I

# stratified spark angles: one per sector with jitter, so there are no clumps or gaps
_r = np.random.default_rng(5)
ANG = (np.arange(12) + 0.5 + (_r.random(12) - 0.5) * 0.7) / 12 * 2 * math.pi
LEN = 0.55 + _r.random(12) * 0.4; WID = 0.05 + _r.random(12) * 0.03
def hit_spark(t):
    I = np.zeros_like(R)
    if t < 0.07:   # frame 0: hard white impact star
        star = np.abs(np.cos(2 * A)) ** 8
        return np.clip(smooth(0.55, 0.0, R) * (0.4 + 0.6 * star) + smooth(0.18, 0.0, R), 0, 1)
    flash = smooth(0.35, 0.0, R) * (1 - smooth(0.05, 0.25, t))
    for a, ln, wd in zip(ANG, LEN, WID):
        tip = ln * ease_out(min(1, t / 0.45)); tail = tip * smooth(0.1, 0.6, t)
        ca, sa = math.cos(a), math.sin(a); along = X * ca + Y * sa; perp = np.abs(-X * sa + Y * ca)
        seg = ((along > tail) & (along < tip)).astype(float)
        k = np.clip((along - tail) / max(1e-3, tip - tail), 0, 1)          # 1 at the leading tip
        w = wd * (0.35 + 0.65 * k) * (1 - 0.5 * t)
        I = np.maximum(I, seg * smooth(w, 0.0, perp) * (0.5 + 0.5 * k))
    return np.clip(np.maximum(I * (1 - smooth(0.45, 0.7, t)), flash), 0, 1)

def ember(t):
    ph = 2 * math.pi * t
    warp = (fbm(X * 0.8, Y * 0.8 - t * 1.5, t, seed=5) - 0.5) * 0.35 * smooth(-0.8, 0.8, Y)
    px = X + warp + 0.05 * math.sin(ph) * smooth(-0.6, 0.9, Y)
    h = np.clip((0.85 - Y) / 1.65, 0, 1)
    base = np.sqrt(np.clip(1 - ((h - 0.72) / 0.28).clip(0) ** 2, 0, 1))
    width = 0.42 * h ** 0.55 * base
    body = smooth(width, width * 0.25, np.abs(px)) * (Y > -0.85)
    n = fbm(X * 1.4, Y * 1.1 - t * 2.0, t, seed=3)
    tongues = smooth(0.25, 0.6, n + 0.55 * h)
    core = smooth(width * 0.55, 0.0, np.abs(px)) * smooth(0.25, 0.8, h)
    I = body * tongues * 0.72 + core * 0.22
    for k in range(3):   # tongues that detach, rise and shrink (phase-offset so the loop stays seamless)
        tt = (t + k / 3) % 1.0
        cy = 0.35 + tt * 0.75; cx = 0.08 * math.sin(2 * math.pi * (tt + k * 0.3))
        r = 0.09 * (1 - tt) ** 1.2
        blob = smooth(r, r * 0.2, np.hypot((X - cx) * 1.3, (Y - cy) * 0.75))
        I = np.maximum(I, blob * 0.75 * (1 - tt))
    return np.clip(I, 0, 1)

def hatch(t):
    # anticipation glow -> white blowout -> light rays + ring; the texture holds its scale (Size does the growing)
    if t < 0.14:
        k = t / 0.14
        return np.clip(smooth(0.25 + 0.35 * k, 0.0, R) * (0.4 + 0.6 * k), 0, 1)
    if t < 0.27:
        return np.clip(smooth(0.95, 0.2, R) + smooth(0.45, 0.0, R), 0, 1)
    k = (t - 0.27) / 0.73
    rays = np.abs(np.cos(4 * (A + 0.15 * k))) ** 14 * smooth(0.95, 0.15, R) * (1 - smooth(0.0, 0.7, k))
    ring = smooth(0.06, 0.0, np.abs(R - (0.55 + 0.3 * ease_out(k)))) * (1 - smooth(0.3, 1.0, k))
    core = smooth(0.35 * (1 - k), 0.0, R)
    return np.clip(rays * 0.8 + ring + core, 0, 1)

def shockwave(t):
    # thick bright leading edge with a soft gradient trailing inside it, broken up by angular noise, plus dust
    r1 = 0.18 + 0.75 * ease_out(min(1, t / 0.6)); w = 0.22 * (1 - 0.5 * t)
    edge = smooth(0.035, 0.0, np.abs(R - r1))
    inside = np.clip(1 - (r1 - R) / w, 0, 1) * (R <= r1)
    breaks = 0.45 + 0.55 * smooth(0.25, 0.75, 0.5 + 0.5 * np.sin(A * 6 + 1.3) * np.cos(A * 3 - 0.4 + t * 2))
    I = (edge + 0.45 * inside ** 2) * breaks * (1 - smooth(0.5, 1.0, t))
    for k in range(9):
        a = k / 9 * 2 * math.pi + 0.3; rr = r1 + 0.05 + 0.04 * (k % 3)
        I = np.maximum(I, smooth(0.022, 0.0, np.hypot(X - rr * math.cos(a), Y - rr * math.sin(a))) * (1 - smooth(0.3, 0.8, t)))
    return np.clip(I, 0, 1)

_rl = np.array([1.0, 0.7, 0.9, 0.6])
def sparkle(t):
    # a quick twinkle: snaps on, holds, decays; never empty, uneven ray lengths
    s = 0.35 + 0.65 * (math.exp(-((t - 0.25) / 0.12) ** 2) + 0.55 * math.exp(-((t - 0.65) / 0.1) ** 2))
    rot = t * 0.6
    quad = ((A - rot) % (2 * math.pi) / (math.pi / 2)).astype(int) % 4
    rays = np.abs(np.cos(2 * (A - rot))) ** 70 * smooth(0.9 * s * _rl[quad], 0.0, R)
    diag = np.abs(np.cos(2 * (A - rot - math.pi / 4))) ** 70 * smooth(0.4 * s, 0.0, R) * 0.6
    return np.clip(rays + diag + smooth(0.2 * s, 0.0, R), 0, 1)

def smoke(t):
    # soft billowing puff: grows, lifts, thins out from the edges; no hard holes
    r0 = 0.32 + 0.48 * ease_out(t)
    n = fbm(X * 1.1 + 0.3, Y * 1.1 - t * 0.5, t * 0.5, seed=21)
    edge_n = (fbm(np.cos(A) * 0.6, np.sin(A) * 0.6, t * 0.3, seed=4) - 0.5) * 0.22
    puff = smooth(r0 + edge_n, (r0 + edge_n) * 0.15, np.hypot(X, Y + 0.12 - 0.18 * t))
    density = np.clip(0.65 + 0.8 * (n - 0.5) - 0.5 * t * (1 - n), 0, 1)
    I = puff * density * (1 - smooth(0.45, 1.0, t)) * 0.85
    return np.clip(I, 0, 1)

EFFECTS = {  # name: (fn, preview tint, loops)
    "slash_arc": (slash, (0.35, 0.92, 1.0), False),
    "hit_spark": (hit_spark, (1.0, 0.78, 0.25), False),
    "ember_fire": (ember, (1.0, 0.45, 0.1), True),
    "hatch_flash": (hatch, (0.75, 0.45, 1.0), False),
    "shockwave": (shockwave, (0.35, 0.92, 1.0), False),
    "sparkle": (sparkle, (1.0, 0.85, 0.3), True),
    "smoke_puff": (smoke, (0.75, 0.75, 0.8), False),
}

# ---------------- action set ----------------
def _jag(rr, n, x0, y0, x1, y1, amp):
    """Jagged polyline from (x0,y0) to (x1,y1) by midpoint displacement."""
    pts = [(x0, y0), (x1, y1)]
    for _ in range(n):
        new = [pts[0]]
        for (ax, ay), (bx, by) in zip(pts, pts[1:]):
            mx, my = (ax + bx) / 2, (ay + by) / 2; dx, dy = bx - ax, by - ay; L = math.hypot(dx, dy) or 1
            off = (rr.random() - 0.5) * amp * L
            new += [(mx - dy / L * off, my + dx / L * off), (bx, by)]
        pts = new; amp *= 0.62
    return pts
def _seg_dist(px, py, pts):
    d = np.full(px.shape, 9.0)
    for (ax, ay), (bx, by) in zip(pts, pts[1:]):
        vx, vy = bx - ax, by - ay; L2 = vx * vx + vy * vy or 1e-9
        t = np.clip(((px - ax) * vx + (py - ay) * vy) / L2, 0, 1)
        d = np.minimum(d, np.hypot(px - (ax + t * vx), py - (ay + t * vy)))
    return d

def lightning(t):
    # a new bolt shape every 4 frames (re-strike), branches, hot core and glow, flickering out
    f = int(t * 15); rr = np.random.default_rng(100 + f // 4)
    main = _jag(rr, 6, (rr.random() - 0.5) * 0.3, 0.98, (rr.random() - 0.5) * 0.4, -0.98, 0.5)
    d = _seg_dist(X, Y, main)
    I = smooth(0.035, 0.0, d) + 0.5 * smooth(0.22, 0.0, d) ** 2
    for b in range(3):
        k = rr.integers(len(main) // 5, len(main) * 3 // 4); sx, sy = main[k]
        br = _jag(rr, 4, sx, sy, sx + (rr.random() - 0.5) * 0.9, sy - 0.25 - rr.random() * 0.4, 0.5)
        db = _seg_dist(X, Y, br); I = np.maximum(I, (smooth(0.02, 0.0, db) + 0.3 * smooth(0.12, 0.0, db) ** 2) * 0.8)
    flick = [1, 0.55, 0.9, 0.35][f % 4] * (1 - smooth(0.6, 1.0, t))
    return np.clip(I * flick, 0, 1)

def fire_burst(t):
    # explosive fireball: hot core blooms, billows outward, breaks into licks, cools to smoke edge
    r0 = 0.2 + 0.7 * ease_out(min(1, t / 0.55))
    n = fbm(X * 1.3, Y * 1.3 - t * 0.8, t * 0.7, seed=31)
    edge = r0 * (0.75 + 0.5 * n)
    body = smooth(edge, edge * 0.45, R)
    holes = smooth(0.3 + 0.6 * t, 0.75 + 0.2 * t, n + 0.15)
    core = smooth(0.5 * (1 - t), 0.0, R) * (1 - smooth(0.0, 0.5, t))
    return np.clip((body * holes * 0.85 + core) * (1 - smooth(0.6, 1.0, t)), 0, 1)

_sl = np.random.default_rng(41)
SL_ANG = _sl.random(46) * 2 * math.pi; SL_W = 0.004 + _sl.random(46) * 0.012; SL_IN = 0.35 + _sl.random(46) * 0.3
def speed_lines(t):
    # anime radial speed lines rushing inward; loops by re-rolling with a time offset
    I = np.zeros_like(R)
    for a, w, inner in zip(SL_ANG, SL_W, SL_IN):
        aa = a + 0.02 * math.sin(2 * math.pi * t)
        da = np.abs(((A - aa) + math.pi) % (2 * math.pi) - math.pi)
        width = w * (R + 0.2)
        line = smooth(width, 0.0, da * R) * smooth(inner + 0.08 * math.sin(2 * math.pi * (t + a)), inner + 0.25, R)
        I = np.maximum(I, line)
    return np.clip(I * smooth(1.05, 0.8, R) + 0 * R, 0, 1)

_cg = np.random.default_rng(51)
CG_A = _cg.random(24) * 2 * math.pi; CG_P = _cg.random(24)
def charge_gather(t):
    # energy motes spiralling inward into a swelling core (loops)
    I = smooth(0.12 + 0.08 * math.sin(2 * math.pi * t), 0.0, R) + 0.4 * smooth(0.35, 0.0, R) ** 2
    for a, p in zip(CG_A, CG_P):
        u = (t + p) % 1.0; rr = 0.95 * (1 - u) ** 1.3; ang = a + 2.2 * u
        px, py = rr * math.cos(ang), rr * math.sin(ang)
        tx, ty = (rr + 0.12) * math.cos(ang - 0.25), (rr + 0.12) * math.sin(ang - 0.25)
        d = _seg_dist(X, Y, [(tx, ty), (px, py)])
        I = np.maximum(I, smooth(0.02 + 0.015 * u, 0.0, d) * smooth(0.0, 0.25, u))
    return np.clip(I, 0, 1)

def portal_swirl(t):
    # spiral arms rotating around a dark centre with a bright rim (loops)
    sw = A + 3.2 * np.log(R + 0.05) - 2 * math.pi * t
    arms = (0.5 + 0.5 * np.cos(3 * sw)) ** 3
    ring = smooth(0.08, 0.0, np.abs(R - 0.78))
    I = arms * smooth(0.95, 0.75, R) * smooth(0.12, 0.35, R) * 0.9 + ring
    return np.clip(I, 0, 1)

def impact_star(t):
    # anime impact frame: spiky starburst that snaps out, holds, then shatters
    k = 12 + 0 * t
    spikes = 0.45 + 0.5 * (np.abs(np.cos(k / 2 * A + 0.3)) ** 6) * (0.7 + 0.3 * np.cos(5 * A))
    scale = ease_out(min(1, t / 0.18)) * (1 + 0.15 * t)
    inside = R < spikes * scale
    rim = smooth(0.05, 0.0, np.abs(R - spikes * scale))
    I = inside * (1.0 - 0.75 * smooth(0.25, 0.6, t)) + rim
    crack = np.abs(np.sin(7 * A + 4 * R)) ** 40 * smooth(0.3, 0.6, t) * inside
    return np.clip((I - crack) * (1 - smooth(0.6, 1.0, t)), 0, 1)

EFFECTS.update({
    "lightning_bolt": (lightning, (0.55, 0.85, 1.0), False),
    "fire_burst": (fire_burst, (1.0, 0.5, 0.12), False),
    "speed_lines": (speed_lines, (0.95, 0.95, 1.0), True),
    "charge_gather": (charge_gather, (0.4, 0.95, 1.0), True),
    "portal_swirl": (portal_swirl, (0.7, 0.4, 1.0), True),
    "impact_star": (impact_star, (1.0, 0.95, 0.75), False),
})

def tinted(I, tint):
    tint = np.array(tint)
    hot = smooth(0.78, 1.0, I)[..., None]
    rgb = tint * (1 - hot) + np.ones(3) * hot
    return np.dstack([rgb, I])

for name, (fn, tint, loops) in EFFECTS.items():
    sheet = np.zeros((CELL * GRID, CELL * GRID, 4))
    os.makedirs(f"{OUT}/_frames/{name}", exist_ok=True)
    for f in range(N):
        t = f / N if loops else f / (N - 1)
        I = np.clip(fn(t), 0, 1)
        r, c = divmod(f, GRID)
        sheet[r * CELL:(r + 1) * CELL, c * CELL:(c + 1) * CELL] = np.dstack([np.ones_like(I)] * 3 + [I])
        write_png(f"{OUT}/_frames/{name}/f{f:02d}.png", tinted(I, tint))
    write_png(f"{OUT}/sheets/{name}_4x4.png", sheet)
    print("sheet", name)

# static textures: soft glow and a horizontally tileable energy beam
glow = smooth(1.0, 0.0, R) ** 2.2
write_png(f"{OUT}/textures/glow_soft.png", np.dstack([np.ones_like(glow)] * 3 + [glow]))
bw, bh = 512, 128
by, bx = np.mgrid[0:bh, 0:bw]
u = bx / bw * 2 * math.pi; v = (by - bh / 2) / (bh / 2)
beam = np.zeros((bh, bw))
for k, (amp, fr, ph, wd) in enumerate(((0.35, 2, 0.0, 0.07), (0.25, 3, 1.7, 0.05), (0.15, 5, 3.1, 0.035))):
    beam = np.maximum(beam, smooth(wd, 0.0, np.abs(v - amp * np.sin(fr * u + ph))))
beam = np.clip(beam + 0.5 * smooth(0.25, 0.0, np.abs(v)), 0, 1)
write_png(f"{OUT}/textures/beam_energy_tile.png", np.dstack([np.ones_like(beam)] * 3 + [beam]))
# ground crack decal: jagged cracks radiating from the centre
cr = np.random.default_rng(77); C = np.zeros((512, 512)); gy, gx = np.mgrid[0:512, 0:512]; GX = (gx - 255.5) / 256; GY = -(gy - 255.5) / 256
for k in range(9):
    a = k / 9 * 2 * math.pi + cr.random() * 0.4
    pts = _jag(cr, 5, 0, 0, 0.95 * math.cos(a), 0.95 * math.sin(a), 0.35)
    d = _seg_dist(GX, GY, pts); C = np.maximum(C, smooth(0.018, 0.0, d) * smooth(1.0, 0.4, np.hypot(GX, GY)))
C = np.maximum(C, smooth(0.16, 0.0, np.hypot(GX, GY)) * 0.9)
write_png(f"{OUT}/textures/ground_crack.png", np.dstack([np.zeros_like(C)] * 3 + [C]))
# weapon trail: bright leading edge fading to nothing (Trail textures run along their length)
tw, th = 256, 64; ty_, tx_ = np.mgrid[0:th, 0:tw]; u = tx_ / (tw - 1); v = np.abs(ty_ - th / 2 + 0.5) / (th / 2)
trail = (1 - u) ** 1.6 * smooth(1.0, 0.2, v)
write_png(f"{OUT}/textures/trail_gradient.png", np.dstack([np.ones_like(trail)] * 3 + [trail]))
print("done")
