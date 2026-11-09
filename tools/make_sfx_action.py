"""Action/ability SFX to match vfx/roblox/ActionVFX.lua. Same synth helpers as make_sfx.py.
Run with Blender's bundled Python:  <blender python> make_sfx_action.py <out_dir>"""
import sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np
import make_sfx as S
from make_sfx import t_, env, sweep, biquad, bell, place, save, fade_tail

S.OUT = sys.argv[1] if len(sys.argv) > 1 else "sfx/wav"
os.makedirs(S.OUT, exist_ok=True)
SR = S.SR

def noise(rng, dur): return rng.standard_normal(int(SR * dur))

def fireball_cast(rng, v):
    # ignition whoosh: rising band-passed roar with crackle
    d = 0.55; n = t_(d); u = n / d
    roar = biquad(noise(rng, d), "bp", 300 + 1800 * u ** 1.5, 1.3) * np.sin(np.pi * u) ** 0.8
    pops = biquad((rng.random(len(n)) > 0.9985).astype(float) * rng.standard_normal(len(n)) * 6, "bp", 2500, 1.5)  # sparse pops, not static
    return roar + pops * np.sin(np.pi * u) * 0.5

def fire_explosion(rng, v):
    d = 1.3; n = t_(d)
    boom = np.tanh(3.5 * np.sin(sweep(95, 28, d))) * env(len(n), 0.002, 0.7, 3)
    body = biquad(noise(rng, d), "lp", 1400 * np.exp(-n * 2) + 150) * env(len(n), 0.002, 1.0, 3) * 1.5
    roar = biquad(noise(rng, d), "bp", 600 + 300 * np.exp(-n * 3), 0.7) * env(len(n), 0.05, 1.2, 3) * 0.8
    pops = biquad((rng.random(len(n)) > 0.998).astype(float) * rng.standard_normal(len(n)) * 8, "bp", 2200, 1.2) * env(len(n), 0.05, 1.2, 2.5) * (n < 0.8)
    # darken after the initial crack so the tail is a roll, not hiss
    return biquad(np.tanh(1.1 * (boom + body + roar)) + pops * 0.15, "lp", np.where(n < 0.3, 12000, 3000))

def lightning_charge(rng, v):
    d = 0.6; n = t_(d); u = n / d
    hum = np.sin(sweep(80, 320, d)) * (0.5 + 0.5 * np.sin(2 * math.pi * 55 * n)) * u ** 1.5
    fizz = biquad(noise(rng, d), "bp", 4000 + 3000 * u, 2) * u ** 2 * (rng.random(len(n)) > 0.6)
    return biquad(hum, "lp", 2500) * 0.7 + fizz * 0.8

def lightning_strike(rng, v):
    d = 2.4; n = t_(d)
    out = np.zeros(len(n))
    for at, g in ((0.0, 1.0), (0.09, 0.7), (0.18, 0.6)):   # a fresh noise burst per crack so they don't sound copy-pasted
        crack = np.tanh(6 * biquad(noise(rng, 0.12), "hp", 800)) * env(int(SR * 0.12), 0.0003, 0.05, 4)
        out = place(out, crack * g, at)
    rumble = biquad(noise(rng, d), "lp", 220 + 200 * np.exp(-n * 2)) * env(len(n), 0.06, 1.6, 2.5) * 3.0
    roll = rumble * (1 + 0.6 * np.sin(2 * math.pi * 3.2 * n) * np.exp(-n))
    sub = np.sin(sweep(55, 30, d)) * env(len(n), 0.01, 0.8, 3) * 0.8
    return np.tanh(1.3 * (out + roll + sub))

def dash_whoosh(rng, v):
    d = (0.26, 0.3, 0.24)[v]; n = t_(d); u = n / d
    shape = np.where(u < 0.4, (u / 0.4) ** 2, np.exp(-(u - 0.4) * 7))
    air = biquad(noise(rng, d), "bp", 900 + 3800 * shape, 1.6) * shape
    tone = np.sin(sweep(900, 300, d)) * shape * 0.15
    return air + tone

def slash_heavy(rng, v):
    d = 0.45; n = t_(d)
    p = (1.0, 0.94, 1.06)[v]; tc = (0.085, 0.07, 0.1)[v]   # each take: different pitch and swing timing
    sw = biquad(noise(rng, d), "bp", (1200 + 3500 * np.exp(-((n - tc) / 0.06) ** 2)) * p, 2.5) * np.exp(-((n - tc - 0.005) / 0.07) ** 2)
    ring = sum(np.sin(2 * math.pi * f * p * n) * a for f, a in ((2150, 0.4), (3420, 0.25), (5210, 0.12))) * env(len(n), tc + 0.005, 0.28, 4)
    ring[: int(SR * tc)] = 0
    hit = fade_tail(np.tanh(4 * biquad(noise(rng, d), "hp", 1500)) * env(len(n), 0.0005, 0.02, 6), 30)
    return fade_tail(sw * 1.2 + ring + place(np.zeros(len(n)), hit[: int(SR * 0.05)] * 0.8, tc), 30)

def ground_slam(rng, v):
    d = 1.6; n = t_(d)
    thud = np.tanh(4 * np.sin(sweep(120, 32, d))) * env(len(n), 0.001, 0.45, 3)
    crunch = biquad(noise(rng, d), "bp", 900, 0.8) * env(len(n), 0.001, 0.12, 4) * 1.2
    debris = np.zeros(len(n))
    for _ in range(18):   # rocks landing afterwards
        r = t_(0.05); at = 0.25 + rng.random() * 1.0
        debris = place(debris, biquad(rng.standard_normal(len(r)), "bp", 1200 + rng.random() * 1500, 1.5) * env(len(r), 0.0005, 0.02, 6) * (0.3 + rng.random() * 0.4), at)
    rumble = biquad(rng.standard_normal(len(n)), "lp", 140) * env(len(n), 0.05, 1.1, 2.5) * 2.5
    return np.tanh(1.3 * (thud + crunch + biquad(debris, "lp", 3000) + rumble))

def charge_up(rng, v):
    d = 1.15; n = t_(d); u = n / d
    tone = sum(np.sin(sweep(180 * k, 720 * k, d) + 0.6 * np.sin(2 * math.pi * 7 * n)) / k for k in (1, 2, 3)) * u ** 1.4
    shimmer = biquad(noise(rng, d), "bp", 3000 + 5000 * u, 3) * u ** 2.5 * 0.6
    return tone * 0.6 + shimmer

def charge_release(rng, v):
    d = 1.1; n = t_(d)
    burst = np.tanh(3 * np.sin(sweep(160, 40, d))) * env(len(n), 0.001, 0.35, 3)
    whoosh = biquad(noise(rng, d), "bp", 2500 * np.exp(-n * 3) + 400, 1.0) * env(len(n), 0.002, 0.5, 3)
    sparkle = np.zeros(len(n))
    for k, f in enumerate((1568, 2093, 2637, 3136)):
        sparkle = place(sparkle, bell(f, 0.6, 0.5) * 0.25, 0.02 + k * 0.035)
    return np.tanh(1.2 * (burst + whoosh + sparkle))

def portal_open(rng, v):
    d = 1.6; n = t_(d); u = n / d
    swirl = sum(np.sin(sweep(110 * k, 330 * k, d) + 2 * np.sin(2 * math.pi * 4 * n * (1 + u))) / k for k in (1, 1.5, 2)) * np.sin(np.pi * np.clip(u * 1.4, 0, 1)) ** 0.7
    air = biquad(noise(rng, d), "bp", 500 + 1500 * (0.5 + 0.5 * np.sin(2 * math.pi * 2 * n)), 2) * 0.5 * np.sin(np.pi * u)
    chime = place(np.zeros(len(n)), bell(1318.5, 0.9, 0.9) * 0.4, 0.55)
    return swirl * 0.5 + air + chime

def impact_heavy(rng, v):
    d = 0.7; n = t_(d)
    punch = np.tanh(5 * np.sin(sweep(180 - 15 * v, 45, d))) * env(len(n), 0.0008, 0.18, 4)
    smack = np.tanh(3 * biquad(noise(rng, d), "bp", 1800 + 400 * v, 0.9)) * env(len(n), 0.0005, 0.03, 6) * 1.2
    tail = biquad(noise(rng, d), "lp", 500) * env(len(n), 0.01, 0.3, 3) * 0.6
    return np.tanh(1.3 * (punch + smack + tail))

def verb(x, tail=0.35, mix=0.18, seed=7):
    """Short room reverb: convolve with decaying, darkened noise so hits sit in a space instead of a void."""
    r = np.random.default_rng(seed); m = int(SR * tail)
    ir = biquad(r.standard_normal(m), "lp", 5000) * np.exp(-np.arange(m) / SR * 12)
    ir /= np.sqrt(np.sum(ir ** 2))
    L = len(x) + m; F = 1 << (L - 1).bit_length()
    wet = np.fft.irfft(np.fft.rfft(x, F) * np.fft.rfft(ir, F), F)[:L]
    out = np.concatenate([x, np.zeros(m)]) + wet * mix
    return fade_tail(out, 40)

if __name__ == "__main__":
    for name, fn, nvar in (
        ("fireball_cast", fireball_cast, 1), ("fire_explosion", fire_explosion, 1),
        ("lightning_charge", lightning_charge, 1), ("lightning_strike", lightning_strike, 1),
        ("dash_whoosh", dash_whoosh, 3), ("slash_heavy", slash_heavy, 3), ("ground_slam", ground_slam, 1),
        ("charge_up", charge_up, 1), ("charge_release", charge_release, 1), ("portal_open", portal_open, 1),
        ("impact_heavy", impact_heavy, 3)):
        save(name, lambda rng, v, fn=fn: verb(fn(rng, v)), nvar)
    print("done")
