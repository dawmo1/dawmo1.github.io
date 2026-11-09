"""VFX texture set v2: noise-driven flipbooks and beam textures for Roblox ParticleEmitters / Beams.

Every flipbook is a 1024px 4x4 sheet (256px cells, 16 frames) that Roblox plays with FlipbookLayout Grid4x4.
Greyscale sheets are white with the shape in alpha so the emitter's Color tints them; the explosion is baked in
full colour because its temperature changes inside a single frame. Looping sheets cross-fade two noise
fields so frame 16 flows back into frame 1 with no pop.

Run:  python3 tools/make_vfx2.py [out_dir]     (needs numpy + Pillow)
"""
import sys, os, math
import numpy as np
from PIL import Image

OUT = sys.argv[1] if len(sys.argv) > 1 else "vfx/v2"
CELL, GRID, N = 256, 4, 16
os.makedirs(OUT, exist_ok=True)
ys, xs = np.mgrid[0:CELL, 0:CELL]
X = (xs - CELL / 2 + 0.5) / (CELL / 2)
Y = -(ys - CELL / 2 + 0.5) / (CELL / 2)  # -1..1, y up
R = np.hypot(X, Y)
A = np.arctan2(Y, X)


def sstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


class Noise:
    """Tileable 2D value noise with smooth interpolation; fbm sums octaves."""

    def __init__(self, seed, size=64):
        self.g = np.random.default_rng(seed).random((size, size))
        self.s = size

    def v(self, x, y):
        s = self.s
        xi, yi = np.floor(x).astype(int), np.floor(y).astype(int)
        fx, fy = x - xi, y - yi
        fx, fy = fx * fx * fx * (fx * (fx * 6 - 15) + 10), fy * fy * fy * (fy * (fy * 6 - 15) + 10)
        x0, y0, x1, y1 = xi % s, yi % s, (xi + 1) % s, (yi + 1) % s
        g = self.g
        a = g[y0, x0] * (1 - fx) + g[y0, x1] * fx
        b = g[y1, x0] * (1 - fx) + g[y1, x1] * fx
        return a * (1 - fy) + b * fy

    def fbm(self, x, y, oct=5, lac=2.03, gain=0.5):
        t, amp, f, norm = 0.0, 1.0, 1.0, 0.0
        for o in range(oct):
            t = t + amp * self.v(x * f + o * 17.3, y * f + o * 9.1)
            norm += amp
            amp *= gain
            f *= lac
        return t / norm



def sheet(frames, rgb=False):
    out = np.zeros((CELL * GRID, CELL * GRID, 4), np.float32)
    for i, f in enumerate(frames):
        r, c = divmod(i, GRID)
        if rgb:
            out[r * CELL:(r + 1) * CELL, c * CELL:(c + 1) * CELL] = f
        else:
            out[r * CELL:(r + 1) * CELL, c * CELL:(c + 1) * CELL, :3] = 1
            out[r * CELL:(r + 1) * CELL, c * CELL:(c + 1) * CELL, 3] = f
    return out


def save(name, arr):
    Image.fromarray((np.clip(arr, 0, 1) * 255 + 0.5).astype(np.uint8), "RGBA").save(f"{OUT}/{name}.png", optimize=True)
    print("wrote", name, arr.shape)


nz = [Noise(s) for s in range(12)]

# 1. fire loop: rising domain-warped flame tongue, teardrop silhouette eaten by noise
def fire(t):
    def field(tt):
        wy = Y * 1.8 - tt * 2.4
        warp = nz[0].fbm(X * 1.7 + 3, wy * 0.9, 3) - 0.5
        return nz[1].fbm(X * 2.6 + warp * 1.4, wy * 1.4 + warp * 1.2, 5)
    n = (field(t) * (1 - t) + field(t - 1) * t - 0.5) * 2.4  # roughly -1..1
    h = np.clip((Y + 0.92) / 1.85, 0, 1)  # 0 at the base .. 1 at the tip
    width = 0.5 * (1 - h) ** 0.65 + 0.03
    d = np.abs(X + n * 0.12 * h) / width
    dens = (1 - d) * 1.2 - h * 0.55 + n * 0.55
    flame = sstep(0.0, 0.35, dens) * sstep(-0.95, -0.8, Y)
    core = sstep(0.45, 0.9, dens) * (1 - h) ** 0.8
    return np.clip(flame * 0.72 + core * 0.45, 0, 1)

save("fire_loop_4x4", sheet([fire(i / N) for i in range(N)]))

# 2. smoke billow: expanding lumpy puff with soft self-shadowing baked into alpha density
def smoke(i):
    t = i / (N - 1)
    rad = 0.28 + 0.6 * (1 - (1 - t) ** 2)
    n = nz[2].fbm(X * 2.4 + t * 0.6, Y * 2.4 - t * 0.8, 6)
    n2 = nz[3].fbm(X * 6 + 5, Y * 6 - t, 4)
    shape = 1 - sstep(rad * 0.55, rad, R + (n - 0.5) * 0.55 * rad + (n2 - 0.5) * 0.12)
    dens = shape * sstep(0.25, 0.75, n * 0.8 + 0.35)
    shade = 0.75 + 0.25 * sstep(-0.6, 0.6, (X * -0.5 + Y * 0.8))  # light from upper left
    fade = (1 - t) ** 1.4 * sstep(0, 0.12, t + 0.05)
    return np.clip(dens * shade * fade * 1.25, 0, 1)

save("smoke_billow_4x4", sheet([smoke(i) for i in range(N)]))

# 3. explosion (full colour): white-hot core blooming into fire then rolling black smoke
def explosion(i):
    t = i / (N - 1)
    rad = 0.25 + 0.68 * (1 - (1 - t) ** 3)
    n = (nz[4].fbm(X * 2.2 + t * 0.5, Y * 2.2 - t * 1.1, 6) - 0.5) * 2.4
    n2 = (nz[10].fbm(X * 5.5 + 2, Y * 5.5 - t * 1.5, 4) - 0.5) * 2.4
    edge = R / rad + n * 0.32 + n2 * 0.1
    shape = 1 - sstep(0.75, 1.0, edge)
    # billows: bright lumps where the fine noise peaks; heat drops as the cloud grows and cools
    heat = np.clip((1.05 - edge) * 1.6 - t * 1.45 + n2 * 0.45 + n * 0.25, 0, 1)
    stops = [(0.0, (0.09, 0.08, 0.075)), (0.22, (0.32, 0.06, 0.02)), (0.45, (0.95, 0.3, 0.04)), (0.7, (1.0, 0.68, 0.2)), (1.0, (1.0, 0.96, 0.84))]
    col = np.zeros(X.shape + (3,))
    for (a, ca), (b, cb) in zip(stops, stops[1:]):
        k = np.clip((heat - a) / (b - a), 0, 1)[..., None]
        m = ((heat >= a) & (heat <= b))[..., None]
        col = np.where(m, np.array(ca) * (1 - k) + np.array(cb) * k, col)
    smoke_shade = 0.8 + 0.4 * sstep(-0.5, 0.5, -X * 0.4 + Y * 0.8)  # lit from above on the cooled smoke
    col = col * np.where(heat[..., None] < 0.2, smoke_shade[..., None], 1)
    alpha = shape * np.clip(0.75 + heat, 0, 1) * (1 - sstep(0.72, 1.0, t))
    return np.dstack([np.clip(col, 0, 1), alpha])

save("explosion_rgb_4x4", sheet([explosion(i) for i in range(N)], rgb=True))

# 4. shockwave: thin ring that grows, breaks up with noise and thins out
def shock(i):
    t = i / (N - 1)
    rr = 0.12 + 0.82 * (1 - (1 - t) ** 2.2)
    n = nz[5].fbm(np.cos(A) * 3 + 10, np.sin(A) * 3 + t * 2, 4)
    w = 0.09 * (1 - t) + 0.015
    ring = np.exp(-((R - rr - (n - 0.5) * 0.06) / w) ** 2)
    inner = sstep(rr, rr * 0.2, R) * 0.18 * (1 - t)
    breakup = sstep(0.25, 0.6, nz[6].fbm(A * 2.5 + 40, R * 6 - t * 3, 3) + (1 - t) * 0.5)
    return np.clip((ring * breakup + inner) * (1 - t ** 3), 0, 1)

save("shockwave_4x4", sheet([shock(i) for i in range(N)]))

# 5. impact flare: hot core, 4-point star, anamorphic streak, fades fast
def flare(i):
    t = i / (N - 1)
    s = 1 - (1 - t) ** 0.5
    core = np.exp(-(R / (0.10 + 0.25 * s)) ** 2)
    star = (np.exp(-np.abs(X) / 0.025) * np.exp(-np.abs(Y) / (0.25 + 0.5 * s)) + np.exp(-np.abs(Y) / 0.025) * np.exp(-np.abs(X) / (0.25 + 0.5 * s)))
    streak = np.exp(-np.abs(Y) / 0.012) * np.exp(-np.abs(X) / (0.6 + 0.4 * s)) * 0.8
    spikes = np.clip(np.cos(A * 7 + 1.3) * 0.5 + 0.5, 0, 1) ** 18 * np.exp(-R / (0.2 + 0.6 * s)) * 0.6
    return np.clip((core + star * 0.9 + streak + spikes) * (1 - t) ** 1.6, 0, 1)

save("impact_flare_4x4", sheet([flare(i) for i in range(N)]))

# 6. slash arc: crescent swept counter-clockwise, bright leading edge, noise-eroded trail
def slash(i):
    t = i / (N - 1)
    ease = 1 - (1 - min(1, t / 0.5)) ** 3
    head = -2.3 + 4.2 * ease  # angle of the leading edge
    span = 0.15 + 2.5 * min(1, t / 0.3)
    d = (head - A) % (2 * math.pi)  # angle behind the head
    inside = d <= span
    u = np.where(inside, 1 - d / span, 0)  # 1 at the head .. 0 at the tail
    tip = sstep(0.0, 0.45, d)  # round the head off instead of a straight cut
    band = np.exp(-((R - 0.7) / (0.02 + 0.11 * u * tip)) ** 2) * u ** 1.4 * (0.35 + 0.65 * tip)
    ero = sstep(-0.1 + t * 0.9, 0.2 + t * 0.9, nz[7].fbm(A * 3 + 9, R * 7 - t * 3, 4) + u * 0.7)
    lead = np.exp(-(d / 0.12) ** 2) * np.exp(-((R - 0.7) / 0.035) ** 2) * inside * 0.9
    fade = 1 - sstep(0.55, 1.0, t)
    return np.clip((band * ero + lead) * fade, 0, 1)

save("slash_arc_4x4", sheet([slash(i) for i in range(N)]))

# 7. portal swirl loop: log-spiral arms, rotating, warped by noise, soft bright rim
def portal(t):
    def field(tt):
        warp = nz[8].fbm(X * 2 + 7, Y * 2 + tt * 1.5, 3) - 0.5
        th = A + np.log(R + 0.05) * 3.2 - tt * 2 * math.pi + warp * 1.2
        arms = (np.cos(th * 3) * 0.5 + 0.5) ** 3
        return arms * sstep(0.95, 0.55, R) * sstep(0.08, 0.35, R)
    f = field(t) * (1 - t) + field(t - 1) * t
    rim = np.exp(-((R - 0.86) / 0.06) ** 2) * (0.6 + 0.4 * nz[9].fbm(A * 4 + 3, t * 4, 3))
    return np.clip(f * 0.9 + rim, 0, 1)

save("portal_swirl_4x4", sheet([portal(i / N) for i in range(N)]))

# 8. electric arcs: horizontal, tile along a Beam; four variants for flicker
def bolt(seed, w=1024, h=128):
    rng = np.random.default_rng(seed)
    img = np.zeros((h, w), np.float32)
    def line(x0, y0, x1, y1, amp, depth, strength):
        pts = [(x0, y0), (x1, y1)]
        for d in range(depth):
            nxt = []
            for (ax, ay), (bx, by) in zip(pts, pts[1:]):
                mx, my = (ax + bx) / 2, (ay + by) / 2 + rng.normal(0, amp / (1.7 ** d))
                nxt += [(ax, ay), (mx, my)]
            nxt.append(pts[-1])
            pts = nxt
        yy, xx = np.mgrid[0:h, 0:w]
        px = np.array([p[0] for p in pts]); py = np.array([p[1] for p in pts])
        ycurve = np.interp(np.arange(w), px, py)
        mask = (xx >= min(x0, x1)) & (xx <= max(x0, x1))
        dist = np.abs(yy - ycurve[None, :])
        return (np.exp(-(dist / 1.4) ** 2) + 0.35 * np.exp(-(dist / 7) ** 2)) * mask * strength, ycurve
    main, yc = line(0, h / 2, w, h / 2, 26, 9, 1.0)
    img += main
    for _ in range(5):  # branches peel off the main bolt and die out
        x0 = rng.integers(40, w - 260)
        x1 = x0 + rng.integers(90, 240)
        y1 = yc[x0] + rng.choice([-1, 1]) * rng.integers(18, 44)
        b, _ = line(x0, yc[x0], x1, y1, 10, 6, 0.55)
        img += b
    edge = np.minimum(np.linspace(0, 1, w) * 30, 1) * np.minimum(np.linspace(1, 0, w) * 30, 1)
    a = np.clip(img * edge[None, :], 0, 1)
    out = np.ones((h, w, 4), np.float32); out[..., 3] = a
    return out

for k in range(4):
    save(f"arc_beam_{k + 1}", bolt(100 + k))

# 9. spark streak (single): long soft-ended line for velocity-aligned sparks
sy, sx = np.mgrid[0:512, 0:64]
u, v = (sx - 31.5) / 32, (sy - 255.5) / 256
spark = np.exp(-(u / 0.18) ** 2) * (1 - np.abs(v)) ** 1.5 * (0.6 + 0.4 * (v < 0))
o = np.ones((512, 64, 4), np.float32); o[..., 3] = np.clip(spark * 1.3, 0, 1)
save("spark_streak", o)
# VelocityParallel particles stretch along the texture's horizontal axis, so the sparks ship rotated
save("spark_streak_h", np.ascontiguousarray(np.rot90(o)))

# 10. ground scorch decal: burnt radial stain with cracks
gy, gx = np.mgrid[0:1024, 0:1024]
GX, GY = (gx - 511.5) / 512, (gy - 511.5) / 512
GR, GA = np.hypot(GX, GY), np.arctan2(GY, GX)
big = Noise(20, 128)
n = big.fbm(GX * 4 + 2, GY * 4 + 2, 6)
stain = (1 - sstep(0.35, 0.92, GR + (n - 0.5) * 0.45)) * (0.55 + 0.45 * n)
cr = Noise(21, 128).fbm(GA * 6 + 30, GR * 3, 5)
cracks = np.exp(-((cr - 0.5) / 0.012) ** 2) * sstep(0.95, 0.15, GR)
alpha = np.clip(stain * 0.85 + cracks * 0.9, 0, 1)
col = np.dstack([np.full_like(alpha, 0.05), np.full_like(alpha, 0.045), np.full_like(alpha, 0.04)])
ember = np.exp(-((cr - 0.5) / 0.006) ** 2) * sstep(0.5, 0.05, GR)
col = col + ember[..., None] * np.array([1.0, 0.45, 0.1])
save("ground_scorch", np.dstack([np.clip(col, 0, 1), alpha]))
print("done")

# 11. beam glow (single): soft line, constant along the beam, gaussian across it; the glow pass under bolts
# Roblox maps a beam texture's horizontal axis across the beam, so the falloff runs left-right
bx = (np.arange(128) - 63.5) / 64
bg = np.ones((64, 128, 4), np.float32); bg[..., 3] = np.exp(-(bx / 0.38) ** 2)[None, :]
save("beam_glow_v", bg)
