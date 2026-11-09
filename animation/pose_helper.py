"""World-axis posing for the imported R15 rig.

The rig's joints are quaternion bones with arbitrary rest rolls, so authoring local quaternions by hand is
error-prone. A pose here is written as rotations around WORLD axes of the rest pose (character faces +Y,
+Z is up, the character's left is -X) and converted to each bone's local rotation, then handed to the
animate-roblox-characters skill's apply_pose() so its validation, keying and review renders still run.

Sign guide (right-hand rule, rest pose):
  +X on a limb swings it forward (arms, legs); +X on a lower leg bends the knee forward (use - to bend back)
  -X on torso/head leans forward; Z twists (positive turns the chest toward the character's left)
  right arm out to the side = -Y, left arm out = +Y
"""
import math
import bpy
from mathutils import Quaternion, Vector

ARM = "__Noob_Armature"


def local_quat(arm, bone_name, rotations):
    """rotations: list of (axis_letter_or_vector, degrees) applied in order, in world rest space."""
    rest = (arm.matrix_world @ arm.data.bones[bone_name].matrix_local).to_3x3()
    inv = rest.inverted()
    q = Quaternion()
    for axis, deg in rotations:
        if isinstance(axis, str):
            axis = {"X": Vector((1, 0, 0)), "Y": Vector((0, 1, 0)), "Z": Vector((0, 0, 1))}[axis]
        q = Quaternion((inv @ Vector(axis)).normalized(), math.radians(deg)) @ q
    q.normalize()
    return [q.w, q.x, q.y, q.z]


def local_offset(arm, bone_name, world_offset):
    rest = (arm.matrix_world @ arm.data.bones[bone_name].matrix_local).to_3x3()
    return list(rest.inverted() @ Vector(world_offset))


ALL = ["HumanoidRootPart", "LowerTorso", "UpperTorso", "Head", "LeftUpperArm", "LeftLowerArm", "LeftHand",
       "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
       "RightUpperLeg", "RightLowerLeg", "RightFoot"]


def payload(frame, spec, label, render_dir=None, interpolation="CONSTANT", key_all=True):
    """spec: {bone: {"rot": [(axis, deg), ...], "loc": (x, y, z) world offset}}. Unlisted bones are keyed at rest
    when key_all, so every pose is complete and blocking never inherits a stray rotation."""
    arm = bpy.data.objects[ARM]
    bones = {}
    for name in (ALL if key_all else spec.keys()):
        s = spec.get(name, {})
        b = {"rotation_quaternion": local_quat(arm, name, s.get("rot", []))}
        if key_all or "loc" in s:  # key location on every bone so no offset leaks in from another action
            b["location"] = local_offset(arm, name, s.get("loc", (0, 0, 0)))
        bones[name] = b
    p = {"armature": ARM, "frame": frame, "interpolation": interpolation, "bones": bones, "pose_label": label,
         "review_front_direction": [0, 1, 0]}
    if render_dir:
        p["render_directory"] = render_dir
    return p


# --- planted-foot legs -------------------------------------------------------------------------------
# The armature's matrix_world is identity, so armature space == world space here.
LEGS = {"Left": ("LeftUpperLeg", "LeftLowerLeg", "LeftFoot"), "Right": ("RightUpperLeg", "RightLowerLeg", "RightFoot")}


def _set_world_rot(arm, name, delta):
    """Pose bone so its world rotation is delta @ rest rotation (location stays 0)."""
    pb = arm.pose.bones[name]
    rest = arm.data.bones[name].matrix_local
    m = delta.to_matrix().to_4x4() @ rest.to_3x3().to_4x4()
    m.translation = pb.head
    pb.matrix = m
    pb.location = (0, 0, 0)
    bpy.context.view_layer.update()


def solve_leg(arm, side, ankle_offset=(0, 0, 0), foot_rot=(), knee_dir=(0, 1, 0), ankle_world=None, foot_world=None):
    """Two-bone IK: put the ankle at rest ankle + ankle_offset (world), knee toward knee_dir, foot at
    rest orientation rotated by foot_rot (world-axis list). Returns local quats for the three bones."""
    up, low, foot = LEGS[side]
    B = arm.data.bones
    hip = arm.pose.bones[up].head.copy()
    target = Vector(ankle_world) if ankle_world is not None else B[foot].head_local + Vector(ankle_offset)
    l1 = (B[low].head_local - B[up].head_local).length
    l2 = (B[foot].head_local - B[low].head_local).length
    d = target - hip
    dist = min(max(d.length, abs(l1 - l2) + 1e-4), l1 + l2 - 1e-4)
    dirn = d.normalized()
    a = math.acos(max(-1, min(1, (l1 * l1 + dist * dist - l2 * l2) / (2 * l1 * dist))))
    pole = Vector(knee_dir) - dirn * dirn.dot(Vector(knee_dir))
    pole.normalize()
    knee = hip + (dirn * math.cos(a) + pole * math.sin(a)) * l1
    ankle = hip + dirn * dist
    _set_world_rot(arm, up, (B[low].head_local - B[up].head_local).rotation_difference(knee - hip))
    _set_world_rot(arm, low, (B[foot].head_local - B[low].head_local).rotation_difference(ankle - knee))
    q = Quaternion()
    for axis, deg in foot_rot:
        axis = {"X": Vector((1, 0, 0)), "Y": Vector((0, 1, 0)), "Z": Vector((0, 0, 1))}[axis] if isinstance(axis, str) else Vector(axis)
        q = Quaternion(axis, math.radians(deg)) @ q
    if foot_world is not None:  # absolute world rotation of the foot (used when baking contacts)
        q = foot_world @ B[foot].matrix_local.to_quaternion().inverted()
    _set_world_rot(arm, foot, q)
    return {n: list(arm.pose.bones[n].rotation_quaternion) for n in (up, low, foot)}


def payload_ik(frame, spec, label, feet=None, render_dir=None):
    """Like payload(), but legs are solved so ankles land where `feet` says.
    feet: {"Left": {"at": (dx,dy,dz), "rot": [...], "knee": (x,y,z)}, "Right": {...}}; missing side = planted at rest."""
    arm = bpy.data.objects[ARM]
    p = payload(frame, spec, label, render_dir)
    # apply the non-leg part so hip positions are current before solving
    for name, b in p["bones"].items():
        pb = arm.pose.bones[name]
        pb.rotation_quaternion = b["rotation_quaternion"]
        pb.location = b.get("location", (0, 0, 0))
    bpy.context.view_layer.update()
    for side in ("Left", "Right"):
        f = (feet or {}).get(side, {})
        quats = solve_leg(arm, side, f.get("at", (0, 0, 0)), f.get("rot", ()), f.get("knee", (0, 1, 0)))
        for n, q in quats.items():
            p["bones"][n]["rotation_quaternion"] = q
    return p
