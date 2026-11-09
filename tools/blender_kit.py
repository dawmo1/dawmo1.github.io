"""Blender helper library for the realistic models. Run inside Blender (Text editor or MCP):
    exec(open("<repo>/tools/blender_kit.py").read())
Registers in bpy.app.driver_namespace: lib (pbr, lin), pipe (build_game, bake, bake_base, export), kit, smooth, frame_cam."""
import bpy, bmesh, math, os, time
from mathutils import Vector

def lin(h):
    h = h.lstrip('#'); c = [int(h[i:i+2], 16) / 255 for i in (0, 2, 4)]
    return tuple(((x + 0.055) / 1.055) ** 2.4 if x > 0.04045 else x / 12.92 for x in c) + (1,)

class B:
    """Tiny node-graph helper so presets read like a recipe."""
    def __init__(s, name):
        m = bpy.data.materials.get(name) or bpy.data.materials.new(name); m.use_nodes = True
        s.m = m; s.nt = m.node_tree; s.nt.nodes.clear(); s.N = s.nt.nodes; s.x = -1600
        s.out = s.N.new('ShaderNodeOutputMaterial'); s.out.location = (900, 0)
        s.bsdf = s.N.new('ShaderNodeBsdfPrincipled'); s.bsdf.location = (600, 0); s.link(s.bsdf.outputs[0], s.out.inputs[0])
        s.tc = s.n('ShaderNodeTexCoord')
    def n(s, t, **kw):
        node = s.N.new(t); node.location = (s.x, -len(s.N) * 25); s.x = min(s.x + 60, 400)
        for k, v in kw.items():
            if k in node.inputs: node.inputs[k].default_value = v
            else: setattr(node, k, v)
        return node
    def link(s, a, b): s.nt.links.new(a, b)
    def math(s, op, a, b=None, clamp=False):
        node = s.n('ShaderNodeMath', operation=op, use_clamp=clamp)
        for i, v in enumerate((a, b)):
            if v is None: continue
            if isinstance(v, (int, float)): node.inputs[i].default_value = v
            else: s.link(v, node.inputs[i])
        return node.outputs[0]
    def mixc(s, fac, a, b, blend='MIX'):
        node = s.n('ShaderNodeMix', data_type='RGBA', blend_type=blend)
        for sock, v in (('Factor', fac), ('A', a), ('B', b)):
            if isinstance(v, (int, float)): node.inputs[sock].default_value = v
            elif isinstance(v, tuple): node.inputs[sock].default_value = v
            else: s.link(v, node.inputs[sock])
        return node.outputs['Result']
    def mixf(s, fac, a, b):
        node = s.n('ShaderNodeMix', data_type='FLOAT')
        for sock, v in (('Factor', fac), ('A', a), ('B', b)):
            if isinstance(v, (int, float)): node.inputs[sock].default_value = v
            else: s.link(v, node.inputs[sock])
        return node.outputs['Result']
    def noise(s, scale, detail=6, rough=0.55, stretch=(1, 1, 1), vec=None, dist=0.0):
        mp = s.n('ShaderNodeMapping'); mp.inputs['Scale'].default_value = stretch
        s.link(vec or s.tc.outputs['Object'], mp.inputs['Vector'])
        nz = s.n('ShaderNodeTexNoise', **{'Scale': scale, 'Detail': detail, 'Roughness': rough, 'Distortion': dist})
        s.link(mp.outputs[0], nz.inputs['Vector']); return nz.outputs['Fac']
    def ramp(s, v, p0, p1, c0=None, c1=None):
        r = s.n('ShaderNodeValToRGB'); e = r.color_ramp.elements; e[0].position, e[1].position = p0, p1
        if c0: e[0].color = c0
        if c1: e[1].color = c1
        s.link(v, r.inputs[0]); return r.outputs[0]
    def edge(s, radius):
        bev = s.n('ShaderNodeBevel', samples=8); bev.inputs['Radius'].default_value = radius
        geo = s.n('ShaderNodeNewGeometry')
        d = s.n('ShaderNodeVectorMath', operation='DOT_PRODUCT'); s.link(bev.outputs[0], d.inputs[0]); s.link(geo.outputs['Normal'], d.inputs[1])
        return s.math('MULTIPLY', s.math('SUBTRACT', 1.0, d.outputs['Value']), 25.0, clamp=True)
    def cavity(s, dist):
        ao = s.n('ShaderNodeAmbientOcclusion', only_local=True, samples=12); ao.inputs['Distance'].default_value = dist
        return ao.outputs['AO']

def pbr(name, base, metal, rough, *, s=1.0, wear=None, wear_metal=1.0, wear_rough=0.25, wear_amt=1.0,
        aniso=0.0, streak=0.0, dust=0.25, grain=None, stipple=0.0, bump=0.0, heat=None, emit=None, emit_str=0.0,
        coat=0.0, sss=0.0, var=0.12, edge_r=0.0025):
    """s = metres per Blender unit for this model (1 for metres, 0.28 for studs). All texture scales are in metres."""
    b = B(name); f = 1.0 / s                     # convert metre-based frequencies into object space
    # ---- masks ----------------------------------------------------------
    e = b.edge(edge_r / s * 0.5)                                         # 0..1 near edges
    chips = b.ramp(b.noise(90 * s ** -1 * 0.4, 8, 0.6, stretch=(1, 1, 3)), 0.48, 0.58)   # streaky chips
    chipm = b.math('MULTIPLY', e, b.n('ShaderNodeSeparateColor').outputs[0] if False else chips, clamp=True)
    worn = b.math('MULTIPLY', chipm, wear_amt, clamp=True)
    rub = b.math('MULTIPLY', e, 0.35 * wear_amt, clamp=True)               # softer polished band around every edge
    cav = b.ramp(b.cavity(0.015 / s), 0.2, 0.9)                            # 0 in cavities
    geo = b.n('ShaderNodeNewGeometry')
    sepn = b.n('ShaderNodeSeparateXYZ'); b.link(geo.outputs['Normal'], sepn.inputs[0])
    up = b.ramp(sepn.outputs['Z'], 0.55, 0.95)                              # top-facing surfaces collect dust
    dustn = b.ramp(b.noise(40 * f * 0.3, 5), 0.4, 0.75)
    dustm = b.math('MULTIPLY', b.math('MULTIPLY', up, dustn), dust, clamp=True)
    # ---- base colour ----------------------------------------------------
    tone = b.n('ShaderNodeMapRange'); tone.inputs['To Min'].default_value = 1 - var; tone.inputs['To Max'].default_value = 1 + var
    b.link(b.noise(6 * f * 0.3, 4), tone.inputs['Value'])
    if heat:   # (axis, lo, hi) in object space
        sep = b.n('ShaderNodeSeparateXYZ'); b.link(b.tc.outputs['Object'], sep.inputs[0])
        mr = b.n('ShaderNodeMapRange'); mr.inputs['From Min'].default_value, mr.inputs['From Max'].default_value = heat[1], heat[2]
        b.link(sep.outputs[heat[0]], mr.inputs['Value'])
        r = b.n('ShaderNodeValToRGB'); el = r.color_ramp.elements
        el[0].position, el[0].color = 0.0, lin('#C9A45C'); el[1].position, el[1].color = 1.0, lin('#2F5FCC')
        for p, h in ((0.3, '#C7702A'), (0.55, '#7A3BA8')): x = el.new(p); x.color = lin(h)
        b.link(mr.outputs['Result'], r.inputs[0]); col = r.outputs[0]
    elif grain:  # wood: rings along an axis, distorted by noise
        sep_v = b.n('ShaderNodeMapping'); sep_v.inputs['Scale'].default_value = grain['stretch']
        b.link(b.tc.outputs['Object'], sep_v.inputs['Vector'])
        w = b.n('ShaderNodeTexWave', wave_type='RINGS', rings_direction=grain.get('dir', 'X'))
        w.inputs['Scale'].default_value = grain['scale'] * f * 0.3; w.inputs['Distortion'].default_value = 7; w.inputs['Detail'].default_value = 3
        b.link(sep_v.outputs[0], w.inputs['Vector'])
        col = b.ramp(w.outputs['Fac'], 0.25, 0.9, grain['dark'], grain['light'])
        fine = b.ramp(b.noise(220 * f * 0.3, 8, 0.7, stretch=grain['stretch']), 0.35, 0.7, (0.75, 0.75, 0.75, 1), (1, 1, 1, 1))
        col = b.mixc(1.0, col, fine, 'MULTIPLY')
    else:
        col = base
    col = b.mixc(1.0, col, tone.outputs['Result'] if False else b.ramp(tone.outputs['Result'], 0, 1, (0,0,0,1), (2,2,2,1)), 'MULTIPLY') if False else b.mixc(1.0, col, b.n('ShaderNodeCombineColor').outputs[0] if False else col, 'MIX')
    # tone variation
    tv = b.n('ShaderNodeMix', data_type='RGBA', blend_type='MULTIPLY'); tv.inputs['Factor'].default_value = 1
    b.link(col, tv.inputs['A']) if not isinstance(col, tuple) else setattr(tv.inputs['A'], 'default_value', col)
    tvc = b.n('ShaderNodeCombineColor'); [b.link(tone.outputs['Result'], tvc.inputs[i]) for i in range(3)]
    b.link(tvc.outputs[0], tv.inputs['B']); col = tv.outputs['Result']
    col = b.mixc(b.math('SUBTRACT', 1.0, cav), col, (0.02, 0.018, 0.016, 1), 'MIX')            # grime in cavities
    col = b.mixc(b.math('MULTIPLY', rub, 0.5), col, wear or base, 'MIX')                       # polished band
    col = b.mixc(worn, col, wear or base, 'MIX')                                               # chips to bare material
    col = b.mixc(dustm, col, lin('#7A6E5E'), 'MIX')                                            # dust on top faces
    if isinstance(col, tuple): b.bsdf.inputs['Base Color'].default_value = col
    else: b.link(col, b.bsdf.inputs['Base Color'])
    # ---- metal / roughness --------------------------------------------------
    b.link(b.mixf(worn, metal, wear_metal), b.bsdf.inputs['Metallic'])
    rv = b.n('ShaderNodeMapRange'); rv.inputs['To Min'].default_value = rough - 0.1; rv.inputs['To Max'].default_value = rough + 0.1
    b.link(b.noise(25 * f * 0.3, 6), rv.inputs['Value'])
    scratch = b.ramp(b.noise(400 * f * 0.3, 2, 0.5, stretch=(1, 1, 25)), 0.62, 0.66)            # fine directional scratches
    r = b.mixf(b.math('MULTIPLY', scratch, 0.6), rv.outputs['Result'], max(rough - 0.2, 0.05))
    r = b.mixf(b.math('MULTIPLY', rub, 0.7), r, wear_rough)
    r = b.mixf(worn, r, wear_rough); r = b.mixf(dustm, r, 0.85)
    b.link(r, b.bsdf.inputs['Roughness'])
    if aniso:
        b.bsdf.inputs['Anisotropic'].default_value = aniso
        tg = b.n('ShaderNodeTangent', direction_type='RADIAL', axis='X'); b.link(tg.outputs[0], b.bsdf.inputs['Tangent'])
    if coat: b.bsdf.inputs['Coat Weight'].default_value = coat; b.bsdf.inputs['Coat Roughness'].default_value = 0.15
    if sss: b.bsdf.inputs['Subsurface Weight'].default_value = sss
    if emit:
        b.bsdf.inputs['Emission Color'].default_value = emit; b.bsdf.inputs['Emission Strength'].default_value = emit_str
    # ---- surface normal detail ------------------------------------------------
    h = None
    if stipple:
        v = b.n('ShaderNodeTexVoronoi'); v.inputs['Scale'].default_value = 1400 * f * 0.3; b.link(b.tc.outputs['Object'], v.inputs['Vector']); h = v.outputs['Distance']
    elif streak:
        h = b.noise(600 * f * 0.3, 3, 0.5, stretch=(1, 40, 40))   # machining streaks along X
    elif bump:
        h = b.noise(500 * f * 0.3, 8)
    if h is not None:
        bp = b.n('ShaderNodeBump'); bp.inputs['Strength'].default_value = stipple or streak or bump; bp.inputs['Distance'].default_value = 0.0004 / s
        b.link(h, bp.inputs['Height']); b.link(bp.outputs[0], b.bsdf.inputs['Normal'])
    return b.m


def build_game(parts, name, collection):
    """Apply modifiers on copies of `parts`, join into one mesh `name`, smart-UV it. Source parts are hidden."""
    dg = bpy.context.evaluated_depsgraph_get()
    old = bpy.data.objects.get(name)
    if old: bpy.data.objects.remove(old, do_unlink=True)
    dups = []
    for o in parts:
        if o.type != 'MESH': continue
        me = bpy.data.meshes.new_from_object(o.evaluated_get(dg), preserve_all_data_layers=True, depsgraph=dg)
        d = bpy.data.objects.new("tmp_" + o.name, me); d.matrix_world = o.matrix_world; collection.objects.link(d); dups.append(d)
    bpy.ops.object.select_all(action='DESELECT')
    for d in dups: d.select_set(True)
    bpy.context.view_layer.objects.active = dups[0]; bpy.ops.object.join()
    g = bpy.context.view_layer.objects.active; g.name = name
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bpy.ops.object.material_slot_remove_unused()
    bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=1.15, island_margin=0.003, area_weight=0.0)
    bpy.ops.uv.pack_islands(margin=0.003, rotate=True); bpy.ops.object.mode_set(mode='OBJECT')
    for o in parts: o.hide_render = True; o.hide_set(True)
    return g

def bake(g, kind, folder, prefix, size=1024):
    """kind: basecolor | roughness | metallic | normal. One map per call (keeps each call short)."""
    bpy.ops.object.select_all(action='DESELECT'); g.hide_set(False); g.select_set(True); bpy.context.view_layer.objects.active = g
    key = f"{prefix}_{kind}"
    im = bpy.data.images.get(key)
    if im and (im.size[0] != size): bpy.data.images.remove(im); im = None
    if not im:
        im = bpy.data.images.new(key, size, size, alpha=False, float_buffer=(kind == 'normal'))
        im.colorspace_settings.name = 'sRGB' if kind == 'basecolor' else 'Non-Color'
    for m in g.data.materials:
        n = m.node_tree.nodes.get("BAKE") or m.node_tree.nodes.new('ShaderNodeTexImage'); n.name = "BAKE"; n.image = im; m.node_tree.nodes.active = n
    sc = bpy.context.scene; s0 = sc.cycles.samples; sc.cycles.samples = 8; t = time.time()
    if kind == 'basecolor': bpy.ops.object.bake(type='DIFFUSE', pass_filter={'COLOR'}, margin=6)
    elif kind == 'roughness': bpy.ops.object.bake(type='ROUGHNESS', margin=6)
    elif kind == 'normal': bpy.ops.object.bake(type='NORMAL', normal_space='TANGENT', margin=6)
    elif kind == 'metallic':
        for m in g.data.materials:
            nt = m.node_tree; bs = next(n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED'); out = next(n for n in nt.nodes if n.type == 'OUTPUT_MATERIAL')
            em = nt.nodes.new('ShaderNodeEmission'); em.name = "TMP_EM"
            if bs.inputs['Metallic'].is_linked: nt.links.new(bs.inputs['Metallic'].links[0].from_socket, em.inputs['Color'])
            else: v = bs.inputs['Metallic'].default_value; em.inputs['Color'].default_value = (v, v, v, 1)
            nt.links.new(em.outputs[0], out.inputs[0])
        try: bpy.ops.object.bake(type='EMIT', margin=6)
        finally:
            for m in g.data.materials:
                nt = m.node_tree; bs = next(n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED'); out = next(n for n in nt.nodes if n.type == 'OUTPUT_MATERIAL')
                nt.links.new(bs.outputs[0], out.inputs[0]); nt.nodes.remove(nt.nodes["TMP_EM"])
    sc.cycles.samples = s0
    os.makedirs(folder, exist_ok=True); im.filepath_raw = f"{folder}/{prefix}_{kind}.png"; im.file_format = 'PNG'; im.save()
    return round(time.time() - t, 1)

def export(g, folder, prefix):
    bpy.ops.object.select_all(action='DESELECT'); g.hide_set(False); g.select_set(True); bpy.context.view_layer.objects.active = g
    bpy.ops.export_scene.fbx(filepath=f"{folder}/{prefix}.fbx", use_selection=True, object_types={'MESH'}, apply_unit_scale=True,
                             mesh_smooth_type='OFF', path_mode='STRIP', axis_forward='-Z', axis_up='Y')
    return sum(len(p.vertices) - 2 for p in g.data.polygons)


def bake_socket(g, socket, im):
    """Bake whatever feeds a Principled input by routing it into an Emission shader (works for metals, unlike DIFFUSE COLOR)."""
    for m in g.data.materials:
        nt = m.node_tree; bs = next(n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED'); out = next(n for n in nt.nodes if n.type == 'OUTPUT_MATERIAL')
        em = nt.nodes.new('ShaderNodeEmission'); em.name = "TMP_EM"
        if bs.inputs[socket].is_linked: nt.links.new(bs.inputs[socket].links[0].from_socket, em.inputs['Color'])
        else:
            v = bs.inputs[socket].default_value
            em.inputs['Color'].default_value = tuple(v) if hasattr(v, '__len__') else (v, v, v, 1)
        nt.links.new(em.outputs[0], out.inputs[0])
        n = nt.nodes.get("BAKE") or nt.nodes.new('ShaderNodeTexImage'); n.name = "BAKE"; n.image = im; nt.nodes.active = n
    try: bpy.ops.object.bake(type='EMIT', margin=6)
    finally:
        for m in g.data.materials:
            nt = m.node_tree; bs = next(n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED'); out = next(n for n in nt.nodes if n.type == 'OUTPUT_MATERIAL')
            nt.links.new(bs.outputs[0], out.inputs[0]); nt.nodes.remove(nt.nodes["TMP_EM"])
def bake_base(g, folder, prefix, size=1024):
    bpy.ops.object.select_all(action='DESELECT'); g.hide_set(False); g.select_set(True); bpy.context.view_layer.objects.active = g
    key = f"{prefix}_basecolor"; im = bpy.data.images.get(key)
    if not im: im = bpy.data.images.new(key, size, size, alpha=False); im.colorspace_settings.name = 'sRGB'
    sc = bpy.context.scene; s0 = sc.cycles.samples; sc.cycles.samples = 8
    bake_socket(g, 'Base Color', im); sc.cycles.samples = s0
    im.filepath_raw = f"{folder}/{prefix}_basecolor.png"; im.file_format = 'PNG'; im.save()

def kit(scene_name, col_name, src_scene="Blaster", prefix="RV"):
    """New model scene: copies the Blaster studio lights/camera and world; returns helper dict bound to a fresh collection."""
    sc = bpy.data.scenes.get(scene_name) or bpy.data.scenes.new(scene_name)
    bpy.context.window.scene = sc
    src = bpy.data.scenes[src_scene]
    sc.render.engine = 'CYCLES'; sc.cycles.device = 'GPU'; sc.cycles.use_denoising = True; sc.cycles.samples = src.cycles.samples
    sc.view_settings.view_transform = 'AgX'; sc.view_settings.look = src.view_settings.look
    sc.world = src.world; sc.render.resolution_x, sc.render.resolution_y = 1920, 1080
    for o in src.objects:
        if o.type in ('LIGHT', 'CAMERA'):
            nm = prefix + o.name[2:]
            if nm not in bpy.data.objects:
                c = o.copy(); c.data = o.data.copy(); c.name = nm; sc.collection.objects.link(c)
                if o.type == 'CAMERA': sc.camera = c
    col = bpy.data.collections.get(col_name) or bpy.data.collections.new(col_name)
    if col.name not in sc.collection.children: sc.collection.children.link(col)
    for o in list(col.objects): bpy.data.objects.remove(o, do_unlink=True)
    def fin(o, bevel=0.0, seg=2, smooth=True, wn=True, angle=35):
        for p in o.data.polygons: p.use_smooth = smooth
        if bevel:
            b = o.modifiers.new("Bevel", 'BEVEL'); b.width = bevel; b.segments = seg; b.limit_method = 'ANGLE'; b.angle_limit = math.radians(angle)
            b.harden_normals = True; b.use_clamp_overlap = True; b.miter_outer = 'MITER_ARC'
        if wn: o.modifiers.new("WN", 'WEIGHTED_NORMAL').keep_sharp = True
        return o
    def mk(name, bm, **kw):
        me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free(); o = bpy.data.objects.new(name, me); col.objects.link(o); return fin(o, **kw)
    def prof(name, pts, th, y=0.0, bevel=0.0012, seg=2, **kw):
        bm = bmesh.new(); f = bm.faces.new([bm.verts.new((x, y - th / 2, z)) for x, z in pts]); r_ = bmesh.ops.extrude_face_region(bm, geom=[f])
        for v in [e for e in r_["geom"] if isinstance(e, bmesh.types.BMVert)]: v.co.y += th
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces); return mk(name, bm, bevel=bevel, seg=seg, smooth=False, **kw)
    def lathe(name, prof_, seg=20, axis='X', **kw):
        """Revolve [(r, t)] around an axis (X or Z)."""
        bm = bmesh.new(); rings = []
        for r, t in prof_:
            def P(i):
                a = 2 * math.pi * i / seg; c, s = r * math.cos(a), r * math.sin(a)
                return (t, c, s) if axis == 'X' else (c, s, t)
            rings.append([bm.verts.new(P(0) if False else ((t, 0, 0) if axis == 'X' else (0, 0, t)))] if r < 1e-6 else [bm.verts.new(P(i)) for i in range(seg)])
        for a, b in zip(rings, rings[1:]):
            if len(a) == 1: [bm.faces.new((a[0], b[i], b[(i + 1) % seg])) for i in range(seg)]
            elif len(b) == 1: [bm.faces.new((a[i], b[0], a[(i + 1) % seg])) for i in range(seg)]
            else: [bm.faces.new((a[i], b[i], b[(i + 1) % seg], a[(i + 1) % seg])) for i in range(seg)]
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces); return mk(name, bm, **kw)
    def cut(o, cutter, op='DIFFERENCE'):
        m = o.modifiers.new("Bool", 'BOOLEAN'); m.object = cutter; m.solver = 'EXACT'; m.operation = op
        cutter.hide_render = True; cutter.hide_set(True); cutter.display_type = 'WIRE'
        for n in ("Bevel", "WN"):
            if o.modifiers.get(n): o.modifiers.move(o.modifiers.find(n), len(o.modifiers) - 1)
        return m
    def tube(name, pts, r, res=8, sides=8):
        cu = bpy.data.curves.new(name, 'CURVE'); cu.dimensions = '3D'; cu.bevel_depth = r; cu.bevel_resolution = max(sides // 4 - 1, 0); cu.resolution_u = res; cu.use_fill_caps = True
        sp = cu.splines.new('BEZIER'); sp.bezier_points.add(len(pts) - 1)
        for i, p in enumerate(pts):
            bp = sp.bezier_points[i]; bp.co = p; bp.handle_left_type = bp.handle_right_type = 'AUTO'
        o = bpy.data.objects.new(name, cu); col.objects.link(o)
        bpy.ops.object.select_all(action='DESELECT'); o.select_set(True); bpy.context.view_layer.objects.active = o
        bpy.ops.object.convert(target='MESH'); o = bpy.context.view_layer.objects.active; o.name = name; return fin(o)
    return dict(sc=sc, col=col, fin=fin, mk=mk, prof=prof, lathe=lathe, cut=cut, tube=tube, P={})


def smooth(pts, it=3):
    """Chaikin corner-cutting on a closed outline; points given as (x, z, 's') stay sharp."""
    P_ = [(p[0], p[1], len(p) > 2) for p in pts]
    for _ in range(it):
        out = []
        n = len(P_)
        for i in range(n):
            a, b = P_[i], P_[(i + 1) % n]
            if a[2]: out.append(a)
            else: out.append((0.75 * a[0] + 0.25 * P_[i - 1][0] if False else a[0], a[1], False)) if False else None
            q = (0.75 * a[0] + 0.25 * b[0], 0.75 * a[1] + 0.25 * b[1], False)
            r = (0.25 * a[0] + 0.75 * b[0], 0.25 * a[1] + 0.75 * b[1], False)
            if not a[2]: out.append(q)
            else: out.append(q)
            out.append(r)
        P_ = out
    return [(x, z) for x, z, _ in P_]

def frame(sc, d, lens=60, fill=1.15, col=None, light_scale=None):
    col = col or next(c for c in sc.collection.children if c.name.endswith("_Parts"))
    pts = [o.matrix_world @ Vector(c) for o in col.all_objects if not o.hide_render and o.type == 'MESH' for c in o.bound_box]
    lo = Vector([min(p[i] for p in pts) for i in range(3)]); hi = Vector([max(p[i] for p in pts) for i in range(3)])
    ctr = (lo + hi) / 2; size = (hi - lo).length
    cam = sc.camera; cam.data.lens = lens; d = Vector(d).normalized()
    cam.location = ctr + d * size * fill * lens / 36.0; cam.rotation_euler = (-d).to_track_quat('-Z', 'Y').to_euler()
    cam.data.clip_end = size * 50
    if light_scale:
        for o in sc.objects:
            if o.type == 'LIGHT':
                if "base" not in o: o["base"] = list(o.location) + [o.data.energy, getattr(o.data, 'size', 0)]
                b = o["base"]; o.location = ctr + Vector(b[:3]) * light_scale; o.data.energy = b[3] * light_scale ** 2; o.data.size = b[4] * light_scale
    return [round(v, 3) for v in ctr], round(size, 3)

ns = bpy.app.driver_namespace
ns['lib'] = dict(lin=lin, pbr=pbr)
ns['pipe'] = dict(build_game=build_game, bake=bake, bake_base=bake_base, export=export)
ns['kit'] = kit; ns['smooth'] = smooth; ns['frame_cam'] = frame
