"""The showcase animations on a classic block noob (R15), authored as key tables.

Sign guide (see pose_helper): +X swings a limb forward, -X bends a knee / leans torso+head forward,
+Z twists toward the character's left, right arm out = -Y, left arm out = +Y.
Arm Y values are written as if the arm rested splayed 35deg out (the tables were first authored on a
splayed-arm avatar); arms() subtracts SPLAY so on the noob, whose arms hang straight, Y 35 = straight down.
Each key: frame -> (spec, feet). feet offsets are world offsets of the ankle from rest (+Y forward, +Z up).
"""
import bpy
import pose_helper as ph

R, L = "Right", "Left"
SPLAY = 35
STRIDE = 1.7  # leg-length ratio noob / original rig


# Block arms read badly when folded: a deep elbow bend stacks the forearm block on the upper arm and a wrist
# flick leaves a visible step at the hand. Every table value is scaled through these, so motion stays in the
# shoulders the way blocky Roblox animation does.
ELBOW = 0.6
WRIST = 0.35


def arms(r=(0, 0, 0), rf=0, l=(0, 0, 0), lf=0, rh=0, lh=0):
    """r/l = (X swing, Y in(+)/out(-) as seen for that arm, Z twist); rf/lf = elbow bend (forearm X)."""
    return {"RightUpperArm": {"rot": [("Y", r[1] - SPLAY), ("X", r[0]), ("Z", r[2])]}, "RightLowerArm": {"rot": [("X", rf * ELBOW)]},
            "LeftUpperArm": {"rot": [("Y", -(l[1] - SPLAY)), ("X", l[0]), ("Z", l[2])]}, "LeftLowerArm": {"rot": [("X", lf * ELBOW)]},
            "RightHand": {"rot": [("X", rh * WRIST)]}, "LeftHand": {"rot": [("X", lh * WRIST)]}}


def body(root=(0, 0, 0), root_rot=(), hips=(), chest=(), chest_loc=None, head=(), **arm_kw):
    # root motion lives on LowerTorso (the R15 Root Motor6D); Roblox never plays HumanoidRootPart keys
    s = {"LowerTorso": {"loc": root, "rot": list(root_rot) + list(hips)},
         "UpperTorso": {"rot": list(chest)}, "Head": {"rot": list(head)}}
    if chest_loc:
        s["UpperTorso"]["loc"] = chest_loc
    s.update(arms(**arm_kw))
    return s


def relaxed(**kw):
    kw.setdefault("r", (4, 31, 0)); kw.setdefault("l", (3, 31, 0)); kw.setdefault("rf", 6); kw.setdefault("lf", 6)
    kw.setdefault("rh", 6); kw.setdefault("lh", 5)
    return body(**kw)


# ---------------------------------------------------------------- Idle: 60-frame loop, weight on the right leg
def _idle(breath, sway, look):
    return (relaxed(root=(0.05, 0, -0.02), hips=[("Y", -4)], chest=[("Y", 3), ("X", 1.6 * breath), ("Z", look * 0.3)],
                    chest_loc=(0, 0, 0.03 * breath), head=[("X", 1.5 - 2 * breath), ("Z", look)],
                    r=(4 + sway, 31 - sway, 0), l=(3 + sway, 31 - sway, 0), rf=6 + 3 * sway, lf=6 + 2 * sway), None)


IDLE = {1: _idle(0, 0, 4), 16: _idle(0.6, 1.5, 1), 31: _idle(1, 3, -6), 46: _idle(0.5, 1.2, -2), 61: _idle(0, 0, 4)}

# ---------------------------------------------------------------- Run: 20-frame loop, in place
def _run(side, phase):
    """phase: contact / down / pass / up for the leg `side` that is forward-going."""
    o = L if side == R else R
    sgn = 1 if side == R else -1          # hips twist toward the forward leg's opposite side
    feet = {"contact": {side: {"at": (0, 0.30, 0.06), "rot": [("X", 14)]}, o: {"at": (0, -0.28, 0.28), "rot": [("X", -35)]}},
            "down":    {side: {"at": (0, 0.06, 0.0)}, o: {"at": (0, -0.12, 0.48), "rot": [("X", -45)]}},
            "pass":    {side: {"at": (0, -0.12, 0.02), "rot": [("X", -6)]}, o: {"at": (0, 0.06, 0.5), "rot": [("X", -15)]}},
            "up":      {side: {"at": (0, -0.30, 0.16), "rot": [("X", -38)]}, o: {"at": (0, 0.24, 0.36), "rot": [("X", 5)]}}}[phase]
    feet = {k: dict(v, at=tuple(c * STRIDE for c in v["at"])) for k, v in feet.items()}
    root_z = {"contact": -0.06, "down": -0.2, "pass": 0.0, "up": 0.14}[phase]
    swing = {"contact": 1, "down": 0.6, "pass": 0, "up": -0.6}[phase] * sgn   # +1 = left arm forward
    spec = body(root=(0, 0, root_z), hips=[("X", -4), ("Z", 10 * swing)], chest=[("X", -9), ("Z", -25 * swing)],
                head=[("X", 9), ("Z", 15 * swing)],
                r=(-62 * swing + 8, 32, 0), rf=30 + 25 * max(-swing, 0), l=(62 * swing + 8, 32, 0), lf=30 + 25 * max(swing, 0),
                rh=10, lh=10)
    return spec, feet


RUN = {1: _run(R, "contact"), 4: _run(R, "down"), 6: _run(R, "pass"), 8: _run(R, "up"),
       11: _run(L, "contact"), 14: _run(L, "down"), 16: _run(L, "pass"), 18: _run(L, "up"), 21: _run(R, "contact")}

# ---------------------------------------------------------------- Jump: 30 frames, one-shot
def _air(z, tuck, toe=-15):
    return {s: {"at": (0, 0.08 * tuck, z + 0.45 * tuck), "rot": [("X", toe)]} for s in (L, R)}


JUMP = {1: (relaxed(), None),
        6: (relaxed(root=(0, -0.06, -0.32), hips=[("X", -10)], chest=[("X", -20)], head=[("X", 18)],
                    r=(-55, 18, 0), l=(-55, 18, 0), rf=20, lf=20), None),
        9: (relaxed(root=(0, 0, 0.12), chest=[("X", 4)], head=[("X", -2)], r=(150, 20, 0), l=(150, 20, 0), rf=10, lf=10),
            {s: {"at": (0, 0, 0.14), "rot": [("X", -32)]} for s in (L, R)}),
        14: (relaxed(root=(0, 0, 1.55), hips=[("X", 4)], chest=[("X", -6)], head=[("X", 6)],
                     r=(115, -10, 0), l=(115, -10, 0), rf=30, lf=30), _air(1.55, 1, -10)),
        18: (relaxed(root=(0, 0, 0.85), chest=[("X", -4)], r=(60, -25, 0), l=(60, -25, 0), rf=25, lf=25), _air(0.85, 0.15, -22)),
        21: (relaxed(root=(0, 0.04, -0.36), hips=[("X", -12)], chest=[("X", -18)], head=[("X", 16)],
                     r=(35, -20, 0), l=(35, -20, 0), rf=40, lf=40), None),
        23: (relaxed(root=(0, 0.04, -0.39), hips=[("X", -13)], chest=[("X", -20)], head=[("X", 18)],
                     r=(30, -18, 0), l=(30, -18, 0), rf=42, lf=42), None),
        27: (relaxed(root=(0, 0.01, -0.06), chest=[("X", -3)], head=[("X", 3)]), None),
        31: (relaxed(), None)}

# ---------------------------------------------------------------- Revolver draw + fire: 36 frames
_AIM = dict(root=(0.02, -0.03, -0.05), hips=[("Z", 8)], chest=[("Z", 14)], head=[("Z", -20), ("X", -3)],
            r=(90, 31, -22), rf=0, rh=0, l=(80, 42, -18), lf=38, lh=8)


def _aim(**over):
    k = dict(_AIM); k.update(over)
    return (body(**k), None)


REVOLVER = {1: (relaxed(), None),
            5: (relaxed(root=(0, 0, -0.05), chest=[("Z", -4)], head=[("X", -6)], r=(-18, 22, 0), rf=55, rh=-20), None),
            9: (body(root=(0.01, -0.02, -0.04), hips=[("Z", 4)], chest=[("Z", 8)], head=[("Z", -10)],
                     r=(50, 26, -10), rf=50, rh=-10, l=(35, 30, 0), lf=55), None),
            13: _aim(), 16: _aim(),
            18: _aim(chest=[("Z", 14), ("X", 4)], head=[("Z", -20), ("X", 2)], r=(115, 31, -22), rf=14, rh=22, l=(98, 42, -18), lf=44),
            21: _aim(r=(100, 31, -22), rf=6, rh=8, l=(88, 42, -18)),
            24: _aim(r=(88, 31, -22)), 26: _aim(r=(91, 31, -22)), 37: _aim()}

# ---------------------------------------------------------------- Grenade throw: 32 frames
GRENADE = {1: (relaxed(), None),
           5: (relaxed(chest=[("X", -4)], head=[("X", -10)], r=(55, 32, 0), rf=85, l=(55, 42, 0), lf=95), None),
           8: (relaxed(chest=[("X", -2), ("Z", 5)], head=[("X", -4)], r=(50, 30, 0), rf=80, l=(40, -15, 0), lf=40, lh=-15), None),
           12: (body(root=(0, -0.12, -0.1), hips=[("Z", -15)], chest=[("Z", -22), ("X", 8)], head=[("Z", 35), ("X", -4)],
                     r=(-20, -55, 0), rf=0, l=(82, 30, 35), lf=8) | {"RightLowerArm": {"rot": [("Y", -85)]}}, None),
           16: (body(root=(0, 0.10, -0.12), hips=[("Z", 14), ("X", -6)], chest=[("Z", 18), ("X", -12)], head=[("Z", -22), ("X", 8)],
                     r=(135, 22, 0), rf=12, rh=35, l=(25, 15, 0), lf=100),
                {R: {"at": (0, 0, 0.05), "rot": [("X", -15)]}}),
           19: (body(root=(0, 0.14, -0.16), hips=[("Z", 20), ("X", -8)], chest=[("Z", 22), ("X", -16)], head=[("Z", -28), ("X", 12)],
                     r=(65, 55, 0), rf=40, rh=20, l=(-10, 20, 0), lf=90),
                {R: {"at": (0, 0, 0.12), "rot": [("X", -30)]}}),
           25: (relaxed(root=(0, 0.04, -0.05), hips=[("Z", 6)], chest=[("Z", 6), ("X", -6)], head=[("Z", -6), ("X", 5)]), None),
           33: (relaxed(), None)}

# ---------------------------------------------------------------- Victory: 40 frames
def _flex(k, nod, z):
    return (body(root=(0, 0, z), chest=[("X", 6)], head=[("X", -nod)],
                 r=(0, -55, 0), rf=0, l=(0, -55, 0), lf=0, rh=0, lh=0) | {
                "RightLowerArm": {"rot": [("Y", -k)]}, "LeftLowerArm": {"rot": [("Y", k)]}}, None)


VICTORY = {1: (relaxed(), None),
           6: (relaxed(root=(0, -0.05, -0.28), hips=[("X", -8)], chest=[("X", -16)], head=[("X", 12)], r=(-35, 15, 0), l=(-35, 15, 0)), None),
           8: (relaxed(root=(0, 0, 0.1), chest=[("X", 4)], head=[("X", 4)], r=(120, 25, 0), rf=20, l=(20, 20, 0), lf=90),
               {s: {"at": (0, 0, 0.12), "rot": [("X", -30)]} for s in (L, R)}),
           10: (body(root=(0, 0, 0.9), chest=[("X", 6)], head=[("X", 14), ("Z", 6)], r=(172, 30, 0), rf=8, l=(30, 25, 0), lf=110, rh=0),
                _air(0.9, 0.7, -12)),
           14: (body(root=(0, 0.03, -0.3), hips=[("X", -10)], chest=[("X", -12)], head=[("X", 8)], r=(150, 25, 0), rf=40, l=(20, 20, 0), lf=90), None),
           17: (body(root=(0, 0, -0.06), chest=[("X", 2)], r=(130, 25, 0), rf=60, l=(10, 15, 0), lf=60), None),
           21: _flex(95, 10, -0.08), 25: _flex(75, 0, -0.02), 29: _flex(108, 12, -0.1),
           34: (relaxed(chest=[("X", 4)], head=[("X", -3)]), None), 41: (relaxed(chest=[("X", 4)], head=[("X", -3)]), None)}


# ---------------------------------------------------------------- combat set (noob only)
# Fighting stance: left foot forward, right foot back, hips dropped. Feet stay planted unless a key moves them.
def stance(lf=(0, 0.35, 0), rf=(0, -0.35, 0), rrot=(), lrot=()):
    return {L: {"at": lf, "rot": list(lrot)}, R: {"at": rf, "rot": list(rrot)}}


def guard(**kw):
    """Boxing guard: fists up by the chin, chest turned so the left shoulder leads."""
    k = dict(root=(0, 0, -0.18), hips=[("Z", -12)], chest=[("Z", -10), ("X", -6)], head=[("Z", 18), ("X", 6)],
             r=(78, 60, 0), rf=125, l=(86, 58, 0), lf=120, rh=0, lh=0)
    k.update(kw)
    return body(**k)


# Sword combo: diagonal cut, backhand sweep, overhead smash. 40 frames, sword in the right hand.
def _sw(**kw):
    k = dict(root=(0, 0, -0.2), hips=[("Z", 10)], chest=[("Z", 8)], head=[("Z", -12)],
             r=(45, 35, 0), rf=45, rh=-15, l=(20, 25, 0), lf=40)
    k.update(kw)
    return body(**k)


SWORD = {1: (_sw(), stance()),
         6: (_sw(root=(0, -0.1, -0.22), hips=[("Z", -20)], chest=[("Z", -28), ("X", 6)], head=[("Z", 30)],
                 r=(-15, -60, 0), rf=0, rh=-35, l=(60, 40, 0), lf=60) | {"RightLowerArm": {"rot": [("Y", -70)]}}, stance()),
         10: (_sw(root=(0, 0.18, -0.38), hips=[("Z", 25), ("X", -8)], chest=[("Z", 30), ("X", -14)], head=[("Z", -26), ("X", 10)],
                  r=(75, 85, 0), rf=10, rh=20, l=(-10, 15, 0), lf=30), stance()),
         13: (_sw(root=(0, 0.2, -0.4), hips=[("Z", 30), ("X", -9)], chest=[("Z", 40), ("X", -16)], head=[("Z", -32), ("X", 10)],
                  r=(35, 95, 0), rf=20, rh=25, l=(-15, 12, 0), lf=30), stance()),
         17: (_sw(root=(0, 0.05, -0.25), hips=[("Z", 30)], chest=[("Z", 42), ("X", -4)], head=[("Z", -36)],
                  r=(100, 95, 0), rf=75, rh=-20, l=(10, 20, 0), lf=50), stance()),
         21: (_sw(root=(0, 0.12, -0.3), hips=[("Z", -22)], chest=[("Z", -32), ("X", -6)], head=[("Z", 22)],
                  r=(90, -5, 0), rf=0, rh=10, l=(55, 60, 0), lf=90), stance()),
         24: (_sw(root=(0, 0.1, -0.3), hips=[("Z", -30)], chest=[("Z", -45), ("X", -6)], head=[("Z", 30)],
                  r=(70, -40, 0), rf=5, rh=15, l=(55, 60, 0), lf=95), stance()),
         28: (_sw(root=(0, -0.05, -0.1), hips=[("Z", 0)], chest=[("Z", 0), ("X", 10)], head=[("X", -12)],
                  r=(170, 30, 0), rf=35, rh=-30, l=(150, 40, 0), lf=40), stance()),
         30: (_sw(root=(0, 0.15, -0.3), hips=[("X", -4)], chest=[("X", -4)], head=[("X", 2)],
                  r=(150, 30, 0), rf=25, rh=-20, l=(135, 45, 0), lf=30), stance(lf=(0, 0.58, 0.28), lrot=[("X", 10)])),
         32: (_sw(root=(0, 0.3, -0.62), hips=[("X", -12)], chest=[("X", -22)], head=[("X", 18)],
                  r=(105, 30, 0), rf=0, rh=35, l=(100, 52, 0), lf=15), stance(lf=(0, 0.75, 0))),
         35: (_sw(root=(0, 0.32, -0.65), hips=[("X", -13)], chest=[("X", -23)], head=[("X", 19)],
                  r=(100, 30, 0), rf=0, rh=38, l=(96, 52, 0), lf=15), stance(lf=(0, 0.75, 0))),
         39: (_sw(root=(0, 0.15, -0.3)), stance(lf=(0, 0.55, 0.2))),
         45: (_sw(), stance())}

# Punch combo: jab, cross, uppercut. 34 frames.
PUNCH = {1: (guard(), stance()),
         4: (guard(chest=[("Z", -24), ("X", -6)], head=[("Z", 24), ("X", 6)], l=(88, 38, 0), lf=0, lh=0), stance()),
         7: (guard(), stance()),
         10: (guard(root=(0, -0.05, -0.2), chest=[("Z", -18), ("X", -4)]), stance()),
         13: (guard(root=(0, 0.12, -0.22), hips=[("Z", 18)], chest=[("Z", 30), ("X", -8)], head=[("Z", -20), ("X", 6)],
                    r=(90, 42, 0), rf=0, l=(60, 48, 0), lf=125),
              stance(rf=(0, -0.35, 0.08), rrot=[("X", -25)])),
         17: (guard(), stance()),
         20: (guard(root=(0, 0, -0.42), hips=[("Z", 5)], chest=[("Z", 12), ("X", -12), ("Y", -8)], head=[("X", 10)],
                    r=(25, 40, 0), rf=110), stance()),
         24: (guard(root=(0, 0.06, -0.12), hips=[("Z", 20)], chest=[("Z", 28), ("X", 10)], head=[("Z", -16), ("X", -10)],
                    r=(115, 40, 0), rf=95, l=(60, 46, 0), lf=125),
              stance(rf=(0, -0.35, 0.1), rrot=[("X", -30)])),
         28: (guard(), stance()),
         34: (guard(), stance())}

# Block: snap into a high guard, absorb a hit, hold. 24 frames, ends holding the block.
def _blk(**kw):
    k = dict(root=(0, 0, -0.3), hips=[("X", -6)], chest=[("X", -10)], head=[("X", 12)],
             r=(92, 76, 0), rf=140, rh=0, l=(92, 72, 0), lf=140, lh=0)
    k.update(kw)
    return body(**k)


BLOCK = {1: (relaxed(), stance(lf=(0, 0.2, 0), rf=(0, -0.2, 0))),
         4: (_blk(root=(0, 0, -0.33)), stance()),
         6: (_blk(root=(0, -0.16, -0.36), chest=[("X", -2)], head=[("X", 6)], r=(80, 74, 0), l=(80, 70, 0)), stance()),
         10: (_blk(root=(0, -0.06, -0.32)), stance()),
         17: (_blk(root=(0, -0.05, -0.3), chest=[("X", -11)]), stance()),
         25: (_blk(), stance())}

# Front kick: chamber, snap out, rechamber, plant. 36 frames.
KICK = {1: (guard(), stance()),
        5: (guard(root=(0, -0.05, -0.12), chest=[("Z", -6), ("X", 4)]), stance()),
        9: (guard(root=(0, -0.08, -0.18), hips=[("X", 6)], chest=[("Z", -4), ("X", 10)], head=[("X", -4)]),
            stance(rf=(0, 0.45, 1.1), rrot=[("X", -20)])),
        12: (guard(root=(0, -0.14, -0.2), hips=[("X", 12)], chest=[("Z", -4), ("X", 16)], head=[("X", -10)],
                   r=(20, 0, 0), rf=60, l=(70, 20, 0), lf=90),
             stance(rf=(0, 2.1, 1.75), rrot=[("X", 35)])),
        15: (guard(root=(0, -0.14, -0.2), hips=[("X", 12)], chest=[("Z", -4), ("X", 16)], head=[("X", -10)],
                   r=(18, 0, 0), rf=60, l=(68, 20, 0), lf=90),
             stance(rf=(0, 2.05, 1.7), rrot=[("X", 33)])),
        19: (guard(root=(0, -0.08, -0.18), hips=[("X", 6)], chest=[("X", 8)]), stance(rf=(0, 0.45, 1.05), rrot=[("X", -15)])),
        24: (guard(root=(0, 0.02, -0.24)), stance()),
        27: (guard(root=(0, 0, -0.2)), stance()),
        37: (guard(), stance())}

# name: (keys, loop, contact intervals or None)
ANIMS = {
    "Idle": (IDLE, True, {"LeftFoot": [[1, 61]], "RightFoot": [[1, 61]]}),
    "Run": (RUN, True, None),  # in-place treadmill run: feet are never world-planted
    "Jump": (JUMP, False, {"LeftFoot": [[1, 7], [21, 31]], "RightFoot": [[1, 7], [21, 31]]}),
    "Revolver": (REVOLVER, False, {"LeftFoot": [[1, 37]], "RightFoot": [[1, 37]]}),
    "Grenade": (GRENADE, False, {"LeftFoot": [[1, 33]], "RightFoot": [[1, 13], [25, 33]]}),
    "Victory": (VICTORY, False, {"LeftFoot": [[1, 6], [14, 41]], "RightFoot": [[1, 6], [14, 41]]}),
    "Sword": (SWORD, False, {"LeftFoot": [[1, 28], [32, 35]], "RightFoot": [[1, 45]]}),
    "Punch": (PUNCH, False, {"LeftFoot": [[1, 34]], "RightFoot": [[1, 10], [17, 21], [28, 34]]}),
    "Block": (BLOCK, False, {"LeftFoot": [[4, 25]], "RightFoot": [[4, 25]]}),
    "Kick": (KICK, False, {"LeftFoot": [[1, 37]], "RightFoot": [[1, 5], [24, 37]]}),
}


def bake_contacts(arm, contacts):
    """Re-solve the legs every frame of a contact so the ankle stays exactly where it landed."""
    sc = bpy.context.scene
    for bone, intervals in (contacts or {}).items():
        side = bone.replace("Foot", "")
        names = ph.LEGS[side]
        for s, e in intervals:
            sc.frame_set(s)
            pb = arm.pose.bones[bone]
            target, frot = pb.head.copy(), pb.matrix.to_quaternion()
            for f in range(s, e + 1):
                sc.frame_set(f)
                ph.solve_leg(arm, side, ankle_world=target, foot_world=frot)
                for n in names:
                    arm.pose.bones[n].keyframe_insert("rotation_quaternion", frame=f, group=n)


def build(name, animation_tools, review_dir=None):
    keys, loop, contacts = ANIMS[name]
    arm = bpy.data.objects[ph.ARM]
    arm.animation_data_create()
    old = bpy.data.actions.get(name)
    if old:
        arm.animation_data.action = None
        bpy.data.actions.remove(old)
    act = bpy.data.actions.new(name); act.use_fake_user = True
    arm.animation_data.action = act
    sc = bpy.context.scene
    last = max(keys)
    sc.frame_start, sc.frame_end = 1, last
    errs = []
    for f, (spec, feet) in sorted(keys.items()):
        r = animation_tools.apply_pose(ph.payload_ik(f, spec, name.lower(), feet, review_dir))
        errs += r.get("errors", [])
    pol = animation_tools.polish_curves(ph.ARM, name)
    bake_contacts(arm, contacts)
    pol2 = animation_tools.polish_curves(ph.ARM, name)
    kw = dict(loop_start=1, loop_end=last) if loop else {}
    audit = animation_tools.audit_action(ph.ARM, name, contact_intervals=contacts, scene_units_per_stud=1.0,
                                         loop_required=loop, contacts_required=bool(contacts), **kw)
    return {"key_errors": errs, "polish_ok": pol.get("ok") and pol2.get("ok"), "audit_ok": audit.get("ok"),
            "audit_errors": audit.get("errors"), "audit_warnings": audit.get("warnings")}
