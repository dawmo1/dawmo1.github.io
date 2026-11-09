"""Original game SFX, synthesized from scratch (no samples, no licensing questions).
WAV masters are peak-normalised to -1 dBFS; the game mix is applied when exporting .ogg (see sfx/mix.txt).
Sounds that repeat often get 3 round-robin variations (name_1, name_2, name_3).
Run with Blender's bundled Python (has numpy):  <blender python> make_sfx.py <out_dir>"""
import sys, os, wave, math
import numpy as np

SR = 44100
OUT = sys.argv[1] if len(sys.argv) > 1 else "sfx/wav"
os.makedirs(OUT, exist_ok=True)

def t_(dur): return np.arange(int(SR * dur)) / SR
def env(n, a=0.005, d=0.1, curve=4.0):
    x = np.arange(n) / SR
    return np.clip(x / max(a, 1e-4), 0, 1) * np.exp(-np.clip(x - a, 0, None) * curve / max(d, 1e-4))
def sweep(f0, f1, dur):
    tt = t_(dur); f = f0 * (f1 / f0) ** (tt / dur)
    return 2 * math.pi * np.cumsum(f) / SR
def biquad(x, kind, f, q=0.707):
    """RBJ biquad; f may be a per-sample array for swept filters."""
    f = np.broadcast_to(np.asarray(f, float), x.shape)
    y = np.zeros_like(x); x1 = x2 = y1 = y2 = 0.0
    for i in range(len(x)):
        w = 2 * math.pi * min(f[i], SR * 0.45) / SR; cw, sw = math.cos(w), math.sin(w); al = sw / (2 * q)
        if kind == "lp": b0, b1, b2 = (1 - cw) / 2, 1 - cw, (1 - cw) / 2
        elif kind == "hp": b0, b1, b2 = (1 + cw) / 2, -(1 + cw), (1 + cw) / 2
        else: b0, b1, b2 = al, 0.0, -al
        a0, a1, a2 = 1 + al, -2 * cw, 1 - al
        yi = (b0 * x[i] + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2) / a0
        x2, x1, y2, y1 = x1, x[i], y1, yi; y[i] = yi
    return y
def bell(freq, dur, decay=0.6, partials=((1, 1), (2.0, 0.4), (3.01, 0.2), (4.2, 0.1))):
    tt = t_(dur)
    s = sum(a * np.sin(2 * math.pi * freq * r * tt) * np.exp(-tt * (3 + 2 * r) / decay) for r, a in partials)
    s = s * np.clip(tt / 0.003, 0, 1)
    k = int(SR * 0.012); s[-k:] *= np.linspace(1, 0, k)  # no click when a note is cut off
    return s
def place(buf, snd, at):
    i = int(at * SR); n = min(len(snd), len(buf) - i)
    if n > 0: buf[i:i + n] += snd[:n]
    return buf
def fade_tail(x, ms=15):
    n = int(SR * ms / 1000); x = x.copy(); x[-n:] *= np.linspace(1, 0, n); return x
def finish(x, fade=0.004):
    x = x - np.mean(x); n = int(SR * fade)
    x[:n] *= np.linspace(0, 1, n); x[-n:] *= np.linspace(1, 0, n)
    return x / (np.max(np.abs(x)) or 1.0) * (10 ** (-1 / 20))
def write(name, x):
    with wave.open(f"{OUT}/{name}.wav", "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((np.clip(x, -1, 1) * 32767).astype("<i2").tobytes())
    print("sfx", name, f"{len(x)/SR:.2f}s")
def save(name, fn, variants=1):
    for v in range(variants):
        rng = np.random.default_rng(1000 + 37 * v + sum(map(ord, name)))
        write(name if variants == 1 else f"{name}_{v + 1}", finish(fn(rng, v)))

# ---------------- UI ----------------
def ui_click(rng, v):
    n = t_(0.06)
    s = np.sin(sweep(2200, 900, 0.06)) * env(len(n), 0.001, 0.03, 5)
    return s + biquad(rng.standard_normal(len(n)), "hp", 3000) * env(len(n), 0.0005, 0.008, 6) * 0.4
def ui_hover(rng, v):
    n = t_(0.09); return np.sin(2 * math.pi * 1250 * n) * env(len(n), 0.008, 0.05, 4)
def ui_denied(rng, v):
    out = np.zeros(int(SR * 0.3))
    for k, f in enumerate((240, 180)):   # soft two-note "nope": filtered triangle, no square-wave buzz
        seg = t_(0.12); tri = 2 / math.pi * np.arcsin(np.sin(2 * math.pi * f * seg))
        out = place(out, fade_tail(biquad(tri, "lp", 1000) * env(len(seg), 0.004, 0.09, 2.5), 25), k * 0.14)
    return out
def notification_pop(rng, v):
    n = t_(0.18)
    return np.sin(sweep(420, 1300, 0.18)) * env(len(n), 0.002, 0.06, 4) + bell(1760, 0.18, 0.15) * 0.35

# ---------------- economy ----------------
def coin_pickup(rng, v):
    base = (1976, 2093, 1865)[v]
    out = np.zeros(int(SR * 0.5)); out = place(out, bell(base, 0.25, 0.25), 0.0)
    return place(out, bell(base * 1.335, 0.45, 0.5), 0.06)
def reward_jingle(rng, v):
    out = np.zeros(int(SR * 1.3))
    for k, f in enumerate((523.25, 659.25, 783.99, 1046.5)):
        out = place(out, bell(f, 0.9 if k == 3 else 0.35, 0.9 if k == 3 else 0.3) * (1.0 if k == 3 else 0.8), k * 0.09)
    return place(out, bell(1567.98, 0.8, 0.8) * 0.35, 0.27)

# ---------------- pets ----------------
def egg_crack(rng, v):
    out = np.zeros(int(SR * 0.55))
    for k, at in enumerate((0.0, 0.14 + rng.random() * 0.05, 0.26 + rng.random() * 0.05)):
        seg = t_(0.09)
        snap = biquad(rng.standard_normal(len(seg)), "bp", 2200 + rng.random() * 900, 1.2) * env(len(seg), 0.0005, 0.025, 6)
        shell = np.sin(sweep(420 + rng.random() * 80, 180, 0.09)) * env(len(seg), 0.001, 0.05, 4) * 0.6   # hollow shell body
        out = place(out, (snap + shell) * (1 - k * 0.12), at)
        for _ in range(6):   # micro-crackles after each break
            c = t_(0.012)
            out = place(out, biquad(rng.standard_normal(len(c)), "hp", 4000) * env(len(c), 0.0003, 0.004, 6) * 0.25, at + 0.01 + rng.random() * 0.07)
    return out
def egg_hatch(rng, v):
    out = np.zeros(int(SR * 1.6)); rise = t_(0.7)
    out = place(out, np.sin(sweep(400, 2400, 0.7) + 3 * np.sin(2 * math.pi * 23 * rise)) * np.clip(rise / 0.7, 0, 1) ** 2 * 0.4, 0.0)
    pop = t_(0.12); out = place(out, np.sin(sweep(320, 90, 0.12)) * env(len(pop), 0.001, 0.08, 4), 0.7)
    out = place(out, biquad(rng.standard_normal(int(SR * 0.15)), "hp", 2500) * env(int(SR * 0.15), 0.001, 0.1, 5) * 0.5, 0.7)
    for k, f in enumerate((1046.5, 1318.5, 1568.0, 2093.0)):
        out = place(out, bell(f, 0.8, 0.7) * 0.5, 0.72 + k * 0.05)
    return out

# ---------------- combat ----------------
def blaster_shot(rng, v):
    z = t_(0.24); start = (2600, 2900, 2350)[v]
    zap = np.sin(sweep(start, 220, 0.24)) * env(len(z), 0.001, 0.16, 3)                     # clean laser sweep, no toy wobble
    zap += np.sin(sweep(start * 1.5, 330, 0.24)) * env(len(z), 0.001, 0.08, 3) * 0.3
    zap += biquad(rng.standard_normal(len(z)), "bp", 3500, 0.8) * env(len(z), 0.0005, 0.03, 5) * 0.5
    zap += np.tanh(3 * np.sin(sweep(110, 45, 0.24))) * env(len(z), 0.001, 0.07, 4) * 0.8      # low punch
    return zap
def sword_swing(rng, v):
    dur = (0.32, 0.36, 0.3)[v]; w = t_(dur); u = w / dur
    shape = np.where(u < 0.65, (u / 0.65) ** 1.6, np.exp(-(u - 0.65) * 9))                     # builds, then drops fast
    fc = 450 + 2800 * shape + 600 * u                                                          # pitch tilts up through the swing
    return biquad(rng.standard_normal(len(w)), "bp", fc, 2.2) * shape
def sword_hit(rng, v):
    h = t_(0.3)
    thump = np.tanh(2.5 * np.sin(sweep(160, 48, 0.3))) * env(len(h), 0.001, 0.12, 4)
    clang = sum(np.sin(2 * math.pi * f * (1 + 0.02 * v) * h) * a for f, a in ((1180, 0.3), (1767, 0.2), (2523, 0.14))) * env(len(h), 0.001, 0.12, 4)
    crack = np.tanh(4 * biquad(rng.standard_normal(len(h)), "hp", 1200)) * env(len(h), 0.0005, 0.025, 6) * 0.9
    return thump + clang + crack
def explosion(rng, v):
    n = t_(1.6)
    boom = np.tanh(3 * np.sin(sweep(90, 30, 1.6))) * env(len(n), 0.002, 0.6, 3)
    body = biquad(rng.standard_normal(len(n)), "lp", 900 * np.exp(-n * 1.8) + 120) * env(len(n), 0.002, 0.9, 3) * 1.4
    crackle = biquad(rng.standard_normal(len(n)), "hp", 2500) * env(len(n), 0.001, 0.15, 4) * 0.5
    return np.tanh(1.5 * (boom + body + crackle))

# ---------------- movement ----------------
def footstep_stone(rng, v):
    n = t_(0.14)
    tap = biquad(rng.standard_normal(len(n)), "bp", 1700 + rng.random() * 500, 1.1) * env(len(n), 0.0005, 0.03, 6)
    heel = np.sin(sweep(190 + rng.random() * 30, 90, 0.14)) * env(len(n), 0.001, 0.04, 5) * 0.6
    return tap + heel
def footstep_grass(rng, v):
    n = t_(0.2)
    rustle = biquad(rng.standard_normal(len(n)), "bp", 3200 + rng.random() * 800, 0.6) * env(len(n), 0.004, 0.09, 4)
    soft = biquad(rng.standard_normal(len(n)), "lp", 400) * env(len(n), 0.002, 0.05, 5) * 0.8
    return rustle * 0.8 + soft
def jump(rng, v):
    n = t_(0.22)
    return np.sin(sweep(260, 620, 0.22)) * env(len(n), 0.003, 0.12, 3) * 0.7 + biquad(rng.standard_normal(len(n)), "bp", 1800, 0.7) * env(len(n), 0.002, 0.05, 5) * 0.4

# ---------------- horror ----------------
def door_knock(rng, v):
    out = np.zeros(int(SR * 1.4))
    for k, at in enumerate((0.0, 0.32, 0.64)):
        s = t_(0.25)
        th = np.sin(sweep(140, 70, 0.25)) * env(len(s), 0.001, 0.12, 4)
        th += biquad(rng.standard_normal(len(s)), "lp", 700) * env(len(s), 0.0005, 0.05, 5) * 0.8
        out = place(out, th * (1 - 0.08 * k), at)
    return biquad(out, "lp", 1400)   # heard through a door

if __name__ == "__main__":
    for name, fn, nvar in (
        ("ui_click", ui_click, 1), ("ui_hover", ui_hover, 1), ("ui_denied", ui_denied, 1), ("notification_pop", notification_pop, 1),
        ("coin_pickup", coin_pickup, 3), ("reward_jingle", reward_jingle, 1), ("egg_crack", egg_crack, 3), ("egg_hatch", egg_hatch, 1),
        ("blaster_shot", blaster_shot, 3), ("sword_swing", sword_swing, 3), ("sword_hit", sword_hit, 3), ("explosion", explosion, 1),
        ("footstep_stone", footstep_stone, 3), ("footstep_grass", footstep_grass, 3), ("jump", jump, 1), ("door_knock", door_knock, 1)):
        save(name, fn, nvar)

    # ---------------- vehicle: seamless 2 s loop ----------------
    # Built in ONE pass 0.15 s longer than the loop, then the overhang is crossfaded into the head.
    # Every periodic part (55 Hz base, 27.5 Hz wobble, 7.5 Hz chug) completes whole cycles in 2 s,
    # and the filter state is continuous, so the wrap point has no click.
    base, dur, xf_s = 55.0, 2.0, 0.15
    n = t_(dur + xf_s); ph = 2 * math.pi * base * n
    eng = sum(np.sin(k * ph + 0.3 * np.sin(ph / 2)) / k for k in range(1, 9))
    eng *= 1 + 0.25 * np.sin(2 * math.pi * 7.5 * n)
    eng += 0.35 * np.tanh(2 * np.sin(ph * 0.5)) * (0.5 + 0.5 * np.sin(2 * math.pi * 7.5 * n))   # exhaust layer
    eng = biquad(eng + 0.15 * np.random.default_rng(5).standard_normal(len(n)), "lp", 900)
    N, XF = int(SR * dur), int(SR * xf_s)
    loop = eng[:N].copy(); fi = np.linspace(0, 1, XF)
    loop[:XF] = loop[:XF] * fi + eng[N:N + XF] * (1 - fi)
    loop = loop / (np.max(np.abs(loop)) or 1) * (10 ** (-1 / 20))
    write("kart_engine_loop", loop)
    print("done")
