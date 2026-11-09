# Background renders for the portfolio: blender -b portfolio_models.blend -P bg_render.py -- <job>
import bpy, os, sys, math
from mathutils import Vector

job = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else "stills"
scn = bpy.data.scenes["Portfolio Models"]
bpy.context.window_manager  # noqa
cam = bpy.data.objects["PM_Cam"]; scn.camera = cam
ROOT = os.path.expanduser("~/Documents/roblox-portfolio/assets/renders")
os.makedirs(ROOT, exist_ok=True)
scn.cycles.samples = 40
try:
    prefs = bpy.context.preferences.addons["cycles"].preferences
    prefs.compute_device_type = "METAL"; prefs.get_devices()
    for d in prefs.devices: d.use = True
    scn.cycles.device = "GPU"
except Exception as e:
    print("gpu fallback", e)

def objs_of(names, prefix=None):
    out = []
    for n in names:
        for o in bpy.data.collections[n].all_objects:
            if o.type in ("MESH", "FONT") and not o.hide_render and (prefix is None or o.name.startswith(prefix)):
                out.append(o)
    return out

def render(names, path, view="hero", res=(1000, 1000), fill=0.8, prefix=None, shadow=True, d_override=None):
    for c in scn.collection.children:
        if c.name[:2].isdigit():
            c.hide_render = c.name not in names
    obs = objs_of(names, prefix)
    if prefix:  # hide the rest of the collection
        keep = set(o.name for o in obs)
        for n in names:
            for o in bpy.data.collections[n].all_objects:
                o.hide_render = o.type in ("MESH", "FONT") and o.name not in keep
    pts = [o.matrix_world @ Vector(b) for o in obs for b in o.bound_box]
    lo = Vector([min(p[i] for p in pts) for i in range(3)]); hi = Vector([max(p[i] for p in pts) for i in range(3)])
    ctr = (lo + hi) / 2; ext = hi - lo
    dirs = {"hero": (0.497, -0.709, 0.5), "front_-y": (0, -1, 0.0001), "right_+x": (1, 0, 0.0001),
            "top": (0.0001, -0.0001, 1), "face": (0.25, -1, 0.12)}
    d = Vector(d_override or dirs[view]).normalized()
    scn.render.resolution_x, scn.render.resolution_y = res
    aspect = res[0] / res[1]
    q = (-d).to_track_quat("-Z", "Y"); right = q @ Vector((1, 0, 0)); up = q @ Vector((0, 1, 0))
    corners = [Vector((x, y, z)) for x in (lo.x, hi.x) for y in (lo.y, hi.y) for z in (lo.z, hi.z)]
    w = max(abs((p - ctr).dot(right)) for p in corners) * 2; h = max(abs((p - ctr).dot(up)) for p in corners) * 2
    span = max(w, h * aspect) / fill
    cam.rotation_euler = q.to_euler()
    if view in ("hero", "face") or d_override:
        cam.data.type = "PERSP"; cam.data.lens = 85; cam.data.sensor_fit = "HORIZONTAL"; cam.data.sensor_width = 36
        cam.location = ctr + d * (span * cam.data.lens / cam.data.sensor_width)
    else:
        cam.data.type = "ORTHO"; cam.data.ortho_scale = span; cam.location = ctr + d * ext.length * 3
    cam.data.clip_end = ext.length * 60
    bpy.data.objects["Shadow_Catcher"].hide_render = not shadow
    scn.render.filepath = path
    bpy.ops.render.render(write_still=True, scene=scn.name)
    if prefix:
        for n in names:
            for o in bpy.data.collections[n].all_objects: o.hide_render = False
    print("RENDERED", path, flush=True)

M = {"sword": "01_Emberbrand_Greatsword", "chest": "02_Loot_Chest", "blaster": "03_Volt_Blaster", "kart": "04_Rally_Kart"}
if job == "stills":
    for k, n in M.items():
        render([n], f"{ROOT}/{k}_hero.png", res=(1400, 1400))
        for v in ("front_-y", "right_+x", "top"):
            render([n], f"{ROOT}/{k}_{v.split('_')[0]}.png", view=v, res=(1000, 1000), fill=0.85, shadow=False)
    pets = ["06_Pet_Mochi_Slime", "06_Pet_Blockpup", "06_Pet_Emberfox"]
    for p in pets:
        render([p], f"{ROOT}/pet_{p.split('_')[-1].lower()}.png", res=(800, 800), d_override=(0.35, -1, 0.4))
    render(pets, f"{ROOT}/pets_group.png", res=(1600, 900), d_override=(0.15, -1, 0.35))
    for e in ("Grass", "Frost", "Inferno", "Void"):
        render([f"07_Egg_{e}"], f"{ROOT}/egg_{e.lower()}.png", res=(700, 800), d_override=(0.2, -1, 0.25), fill=0.85)
    render([f"07_Egg_{e}" for e in ("Grass", "Frost", "Inferno", "Void")], f"{ROOT}/eggs_group.png", res=(1600, 700), d_override=(0, -1, 0.25))
    render(["05_Avatar_Kaiyo"], f"{ROOT}/avatar_kaiyo.png", res=(1100, 1400), d_override=(0.35, -1, 0.15), fill=0.92, shadow=False)
    render(["05_Avatar_Red"], f"{ROOT}/avatar_red.png", res=(700, 1000), d_override=(-0.3, -1, 0.1), fill=0.9, shadow=False)
    render(["05_Avatar_Wren"], f"{ROOT}/avatar_wren.png", res=(800, 1100), d_override=(0, -1, 0.05), fill=0.9, shadow=False)
    for a in ("Kaiyo", "Red", "Wren"):
        # head close-up: frame head + hair only
        obs_prefix = [f"{a}_Head", f"{a}_Hair", f"{a}_Spike", f"{a}_Cap", f"{a}_Eye", f"{a}_Mouth"]
        for o in bpy.data.collections[f"05_Avatar_{a}"].all_objects:
            o.hide_render = not any(o.name.startswith(p) for p in obs_prefix)
        render([f"05_Avatar_{a}"], f"{ROOT}/head_{a.lower()}.png", res=(400, 400), prefix=None, d_override=(0.3, -1, 0.12), fill=0.95, shadow=False)
        for o in bpy.data.collections[f"05_Avatar_{a}"].all_objects: o.hide_render = False

if job == "v3":
    scn.cycles.samples = 40
    for k, n in M.items():
        render([n], f"{ROOT}/{k}_hero.png", res=(1400, 1400), fill=0.78)
        for v in ("front_-y", "right_+x", "top"):
            render([n], f"{ROOT}/{k}_{v.split('_')[0]}.png", view=v, res=(1000, 1000), fill=0.85, shadow=False)
    render(["02_Loot_Chest_Open"], f"{ROOT}/chest_open_hero.png", res=(1400, 1400), d_override=(0.55, -1, 0.75), fill=0.78)
    # UI cutouts, no shadow
    render(["01_Emberbrand_Greatsword"], f"{ROOT}/sword_ui.png", res=(700, 900), d_override=(0.4, -1, 0.3), fill=0.92, shadow=False)
    render(["03_Volt_Blaster"], f"{ROOT}/blaster_ui.png", res=(900, 520), d_override=(0.25, -1, 0.2), fill=0.95, shadow=False)
    render(["04_Rally_Kart"], f"{ROOT}/kart_ui.png", res=(1200, 800), d_override=(0.6, -1, 0.42), fill=0.9, shadow=False)
    for p in ["06_Pet_Mochi_Slime", "06_Pet_Blockpup", "06_Pet_Emberfox"]:
        render([p], f"{ROOT}/pet_{p.split('_')[-1].lower()}.png", res=(700, 700), d_override=(0.35, -1, 0.4), fill=0.85, shadow=False)
    for e in ("Grass", "Frost", "Inferno", "Void"):
        render([f"07_Egg_{e}"], f"{ROOT}/egg_{e.lower()}.png", res=(700, 800), d_override=(0.2, -1, 0.25), fill=0.88, shadow=False)
    render(["06_Pet_Mochi_Slime", "06_Pet_Blockpup", "06_Pet_Emberfox"], f"{ROOT}/pets_group.png", res=(1600, 800), d_override=(0.15, -1, 0.35), fill=0.88)
    render([f"07_Egg_{e}" for e in ("Grass", "Frost", "Inferno", "Void")], f"{ROOT}/eggs_group.png", res=(1600, 700), d_override=(0, -1, 0.25), fill=0.9)
    # scale shots with the R15 rig
    render(["08_Rig_Sword", "09_Scale_Sword"], f"{ROOT}/scale_sword.png", res=(900, 1100), d_override=(0.75, -1, 0.25), fill=0.85)
    render(["08_Rig_Blaster", "09_Scale_Blaster"], f"{ROOT}/scale_blaster.png", res=(1100, 900), d_override=(-0.55, -1, 0.15), fill=0.85)
    render(["04_Rally_Kart", "08_Rig_Driver"], f"{ROOT}/scale_kart.png", res=(1400, 900), d_override=(0.55, -1, 0.35), fill=0.88)
    render(["08_Rig_Ref", "09_Scale_Chest", "09_Scale_Pup", "09_Scale_Fox", "09_Scale_Egg", "09_Scale_Mochi"], f"{ROOT}/scale_lineup.png", res=(1600, 800), d_override=(0.1, -1, 0.2), fill=0.9)

if job == "chars":
    scn.cycles.samples = 40
    render(["08_Rig_Kaiyo"], f"{ROOT}/avatar_kaiyo.png", res=(1100, 1400), d_override=(0.35, -1, 0.15), fill=0.92, shadow=False)
    render(["08_Rig_Red"], f"{ROOT}/avatar_red.png", res=(700, 1000), d_override=(-0.3, -1, 0.1), fill=0.9, shadow=False)
    render(["08_Rig_Wren"], f"{ROOT}/avatar_wren.png", res=(800, 1100), d_override=(0, -1, 0.05), fill=0.9, shadow=False)
    for a in ("Kaiyo", "Red", "Wren"):
        col = bpy.data.collections[f"08_Rig_{a}"]
        keep = ("Head", "Eye", "Smile", "Hair", "Spike", "Cap")
        for o in col.all_objects:
            o.hide_render = o.type in ("MESH", "FONT") and not any(o.name.startswith(f"{a}_{k}") for k in keep)
        render([f"08_Rig_{a}"], f"{ROOT}/head_{a.lower()}.png", res=(400, 400), d_override=(0.3, -1, 0.12), fill=0.92, shadow=False)
        for o in col.all_objects: o.hide_render = False
    render(["08_Rig_Sword", "09_Scale_Sword"], f"{ROOT}/scale_sword.png", res=(900, 1100), d_override=(0.75, -1, 0.25), fill=0.85)
    render(["08_Rig_Blaster", "09_Scale_Blaster"], f"{ROOT}/scale_blaster.png", res=(1100, 900), d_override=(-0.55, -1, 0.15), fill=0.85)
    render(["04_Rally_Kart", "08_Rig_Driver"], f"{ROOT}/scale_kart.png", res=(1400, 900), d_override=(0.55, -1, 0.35), fill=0.88)
    render(["08_Rig_Ref", "09_Scale_Chest", "09_Scale_Pup", "09_Scale_Fox", "09_Scale_Egg", "09_Scale_Mochi"], f"{ROOT}/scale_lineup.png", res=(1600, 800), d_override=(0.1, -1, 0.2), fill=0.9)

if job == "eggs":
    scn.cycles.samples = 32
    for e in ("Grass", "Frost", "Inferno", "Void"):
        render([f"07_Egg_{e}"], f"{ROOT}/egg_{e.lower()}.png", res=(700, 800), d_override=(0.2, -1, 0.25), fill=0.88, shadow=False)
    eg = [f"07_Egg_{e}" for e in ("Grass", "Frost", "Inferno", "Void")]
    render(eg, f"{ROOT}/eggs_group.png", res=(1600, 700), d_override=(0, -1, 0.25), fill=0.9)
    pets = ["06_Pet_Mochi_Slime", "06_Pet_Blockpup", "06_Pet_Emberfox"]
    render(pets, f"{ROOT}/pets_group.png", res=(1600, 900), d_override=(0.15, -1, 0.35), fill=0.85)

if job == "turntables":
    import shutil
    scn.cycles.samples = 20
    for k, n in M.items():
        d0 = Vector((0.497, -0.709, 0.5))
        tmp = f"{ROOT}/_tt_{k}"; os.makedirs(tmp, exist_ok=True)
        for i in range(36):
            a = 2 * math.pi * i / 36
            d = Vector((d0.x * math.cos(a) - d0.y * math.sin(a), d0.x * math.sin(a) + d0.y * math.cos(a), d0.z))
            render([n], f"{tmp}/f{i:03d}.png", res=(600, 600), d_override=tuple(d), fill=0.78)
        print("TURNTABLE_DONE", k, flush=True)
