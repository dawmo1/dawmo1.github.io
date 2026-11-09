"""Turn animation/export/*.rbxanim (zlib JSON of Motor6D CFrames) into compact Luau tables for Studio.

Row format: {t, {qx,qy,qz,qw[,x,y,z]} x 15 R15 parts}, consumed by ServerStorage.PortfolioAnimations.Build.
Keys that linear interpolation between their neighbours already reproduces (within TOL) are dropped,
since Studio plays Linear poses, so playback is unchanged but the data is much smaller.
Usage: python3 tools/rbxanim_to_luau.py
"""
import json, math, sys, zlib
from pathlib import Path

P = ["LowerTorso", "UpperTorso", "Head", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm",
     "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot"]
TOL = 0.0025  # ~0.3 deg; tighter loses the ease on slow clips like Idle
ROOT = Path(__file__).resolve().parent.parent / "animation"


def quat(m):
    r00, r01, r02, r10, r11, r12, r20, r21, r22 = m
    w = math.sqrt(max(0, 1 + r00 + r11 + r22)) / 2
    x = math.copysign(math.sqrt(max(0, 1 + r00 - r11 - r22)) / 2, r21 - r12)
    y = math.copysign(math.sqrt(max(0, 1 - r00 + r11 - r22)) / 2, r02 - r20)
    z = math.copysign(math.sqrt(max(0, 1 - r00 - r11 + r22)) / 2, r10 - r01)
    return x, y, z, w


def num(v):
    return "0" if abs(v) < 5e-4 else f"{v:.3f}".rstrip("0").rstrip(".")


def convert(path):
    d = json.loads(zlib.decompress(path.read_bytes()))
    last, keys = {}, []
    for kf in d["kfs"]:
        vec = []
        for p in P:
            if p in kf["kf"]:  # the exporter omits parts that did not change since the previous key
                last[p] = kf["kf"][p][0]
            c = last[p]
            vec += [*quat(c[3:]), *c[:3]]
        keys.append((kf["t"], vec))
    keep = reduce_keys(keys)
    rows = []
    for t, vec in (keys[i] for i in keep):
        parts = []
        for j in range(len(P)):
            q, pos = vec[j * 7:j * 7 + 4], vec[j * 7 + 4:j * 7 + 7]
            vals = q + (pos if any(abs(v) >= 5e-4 for v in pos) else [])
            parts.append("{" + ",".join(map(num, vals)) + "}")
        rows.append("{%s,%s}" % (num(t), ",".join(parts)))
    return "{" + ",".join(rows) + "}", len(keys), len(keep)


def reduce_keys(keys):
    """Indices of keys to keep: greedy, each kept span must be reproducible by linear interpolation."""
    keep, a = [0], 0
    while a < len(keys) - 1:
        b = a + 1
        while b + 1 < len(keys) and all(lerp_ok(keys, a, b + 1, m) for m in range(a + 1, b + 1)):
            b += 1
        keep.append(b); a = b
    return keep


def lerp_ok(keys, a, b, m):
    (ta, va), (tb, vb), (tm, vm) = keys[a], keys[b], keys[m]
    u = (tm - ta) / (tb - ta)
    return all(abs(x + (y - x) * u - z) <= TOL for x, y, z in zip(va, vb, vm))


# self-check: identity matrix -> identity quaternion
assert quat([1, 0, 0, 0, 1, 0, 0, 0, 1]) == (0, 0, 0, 1)
assert reduce_keys([(0, [0.0]), (1, [1.0]), (2, [2.0]), (3, [0.0])]) == [0, 2, 3]

if __name__ == "__main__":
    out = ROOT / "studio"; out.mkdir(exist_ok=True)
    for f in sorted((ROOT / "export").glob("*.rbxanim")):
        src, n, k = convert(f); (out / f"{f.stem}.luau").write_text(src)
        print(f.stem, f"{n} -> {k} keys", len(src), "bytes")
