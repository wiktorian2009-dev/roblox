# ui_art.py - chunky snowy cartoon GUI art rendered in Blender as transparent PNGs (Claude, 2026-10-06).
# No image-generation AI is available on this PC (no API keys / local models), so the art is built from 2D shapes and rendered flat:
#   buttons (9-slice, 7 colours), a window panel (9-slice), tabs (on/off), a round close button and 12 icons.
# Every piece: navy outline, gradient body, top gloss, darker bottom lip, snow cap. Slice margins are listed in slices.json.
# usage: blender -b --factory-startup -P ui_art.py
import bpy, bmesh, math, os, json, random, sys
from mathutils import Vector
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "png"); os.makedirs(OUT, exist_ok=True)
def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4   # emission colours are linear: convert from sRGB
def hexc(h): return tuple(lin(int(h[i:i + 2], 16) / 255) for i in (0, 2, 4))
NAVY = hexc("142855")
COLORS = {"green": ("5CD27E", "2E9E52"), "blue": ("5FA8F5", "2F6FD0"), "orange": ("FFB04A", "E57A1E"), "red": ("FF6B78", "D63A4A"),
          "grey": ("B6C2D6", "7E8BA3"), "gold": ("FFD95A", "E0A920"), "purple": ("B98CFF", "7B52E0")}

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items] else "BLENDER_EEVEE"
    sc.render.film_transparent = True
    sc.render.image_settings.file_format = "PNG"; sc.render.image_settings.color_mode = "RGBA"
    sc.view_settings.view_transform = "Standard"
    return sc

def mat(name, top, bottom=None, alpha=1.0):
    m = bpy.data.materials.new(name); m.use_nodes = True
    nt = m.node_tree; nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    em = nt.nodes.new("ShaderNodeEmission")
    tr = nt.nodes.new("ShaderNodeBsdfTransparent"); mix = nt.nodes.new("ShaderNodeMixShader")
    mix.inputs[0].default_value = alpha
    if bottom:
        tc = nt.nodes.new("ShaderNodeTexCoord"); sep = nt.nodes.new("ShaderNodeSeparateXYZ"); ramp = nt.nodes.new("ShaderNodeValToRGB")
        nt.links.new(tc.outputs["Generated"], sep.inputs[0]); nt.links.new(sep.outputs[1], ramp.inputs[0])
        ramp.color_ramp.elements[0].color = (*bottom, 1); ramp.color_ramp.elements[1].color = (*top, 1)
        nt.links.new(ramp.outputs[0], em.inputs[0])
    else:
        em.inputs[0].default_value = (*top, 1)
    nt.links.new(tr.outputs[0], mix.inputs[1]); nt.links.new(em.outputs[0], mix.inputs[2]); nt.links.new(mix.outputs[0], out.inputs[0])
    try: m.blend_method = "BLEND"
    except Exception: pass
    return m

def rrect(name, w, h, r, z, m, seg=10, y0=0.0, x0=0.0):
    """rounded rectangle in the XY plane centred at (x0, y0); w, h full size"""
    r = min(r, w / 2, h / 2)
    pts = []
    for cx, cy, a0 in ((w / 2 - r, h / 2 - r, 0), (-w / 2 + r, h / 2 - r, 90), (-w / 2 + r, -h / 2 + r, 180), (w / 2 - r, -h / 2 + r, 270)):
        for i in range(seg + 1):
            a = math.radians(a0 + 90 * i / seg)
            pts.append((x0 + cx + r * math.cos(a), y0 + cy + r * math.sin(a), z))
    return poly(name, pts, m)

def poly(name, pts, m):
    me = bpy.data.meshes.new(name); bm = bmesh.new()
    vs = [bm.verts.new(p) for p in pts]; bm.faces.new(vs); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o); o.data.materials.append(m)
    return o

def circle(name, r, z, m, x=0.0, y=0.0, seg=48):
    return poly(name, [(x + r * math.cos(2 * math.pi * i / seg), y + r * math.sin(2 * math.pi * i / seg), z) for i in range(seg)], m)

def snowcap(w, top, z, scale=1.0, seed=1, m=None, shade=None):
    """soft snow lumps along the top edge (y = top): a rounded strip plus overlapping round lumps (all convex shapes)"""
    rnd = random.Random(seed)
    h = 10 * scale
    rrect("SnowStrip", w, h * 1.6, h * 0.8, z, m, y0=top)
    if shade: rrect("SnowShadeStrip", w, h * 1.6, h * 0.8, z - 0.01, shade, y0=top - 3.5 * scale)
    n = max(4, int(w / (26 * scale)))
    for i in range(n):
        x = -w / 2 + h + (w - 2 * h) * (i + 0.5) / n + (rnd.random() - 0.5) * 6 * scale
        r = (7 + rnd.random() * 6) * scale
        circle("Lump", r, z, m, x=x, y=top + h * 0.3 + rnd.random() * 2 * scale, seg=20)
        if shade: circle("LumpShade", r, z - 0.01, shade, x=x, y=top + h * 0.3 - 3.5 * scale, seg=20)
    return None

def camera(w, h, px_w, px_h):
    sc = bpy.context.scene
    cam = bpy.data.cameras.new("Cam"); cam.type = "ORTHO"; cam.ortho_scale = max(w, h)
    o = bpy.data.objects.new("Cam", cam); sc.collection.objects.link(o); sc.camera = o
    o.location = (0, 0, 100)
    sc.render.resolution_x, sc.render.resolution_y = px_w, px_h
    return o

def render(name):
    p = os.path.join(OUT, name + ".png"); bpy.context.scene.render.filepath = p; bpy.ops.render.render(write_still=True); return p

SNOW = mat("snow", (0.97, 0.99, 1.0)); SNOWS = mat("snowshade", (0.72, 0.84, 0.97))
def button(name, light, dark, w=512, h=192, cap=True):
    reset(); global SNOW, SNOWS
    SNOW = mat("snow", (0.97, 0.99, 1.0)); SNOWS = mat("snowshade", (0.72, 0.84, 0.97))
    camera(w, h, w, h)
    out = mat("navy", NAVY)
    rrect("Outline", w - 8, h - 40, 52, 0, out, y0=-14)
    rrect("Lip", w - 26, h - 58, 44, 0.1, mat("lip", hexc(dark)), y0=-20)
    rrect("Body", w - 26, h - 70, 42, 0.2, mat("body", hexc(light), hexc(dark)), y0=-12)
    rrect("Gloss", w - 70, (h - 70) * 0.34, 22, 0.3, mat("gloss", (1, 1, 1), alpha=0.32), y0=-12 + (h - 70) * 0.2)
    if cap:
        snowcap(w - 46, (h - 40) / 2 - 14 + 2, 0.4, scale=2.1, seed=len(name), m=SNOW, shade=SNOWS)
    return render(name)

def panel(name, w=1024, h=1024, frame=("8FC6F2", "4F86D2"), inner=("EAF6FF", "BFE0FA"), line="FFFFFF"):
    reset(); global SNOW, SNOWS
    SNOW = mat("snow", (0.97, 0.99, 1.0)); SNOWS = mat("snowshade", (0.72, 0.84, 0.97))
    camera(w, h, w, h)
    rrect("Outline", w - 16, h - 70, 110, 0, mat("navy", NAVY), y0=-24)
    rrect("Frame", w - 46, h - 100, 96, 0.1, mat("frame", hexc(frame[0]), hexc(frame[1])), y0=-24)
    rrect("Inner", w - 110, h - 164, 70, 0.2, mat("inner", hexc(inner[0]), hexc(inner[1])), y0=-28)
    rrect("InnerLine", w - 110, h - 164, 70, 0.15, mat("line", hexc(line)), y0=-24)
    snowcap(w - 70, (h - 70) / 2 - 24 + 6, 0.4, scale=3.2, seed=7, m=SNOW, shade=SNOWS)
    # little icicles under the cap at the corners
    ice = mat("ice", hexc("D8F0FF"))
    for x in (-w / 2 + 140, -w / 2 + 190, w / 2 - 170, w / 2 - 120):
        poly("Icicle", [(x - 12, (h - 70) / 2 - 40, 0.35), (x + 12, (h - 70) / 2 - 40, 0.35), (x, (h - 70) / 2 - 100, 0.35)], ice)
    return render(name)

def close_button(name, s=256):
    reset(); global SNOW, SNOWS
    SNOW = mat("snow", (0.97, 0.99, 1.0)); SNOWS = mat("snowshade", (0.72, 0.84, 0.97))
    camera(s, s, s, s)
    circle("Outline", s * 0.44, 0, mat("navy", NAVY), y=-6)
    circle("Lip", s * 0.40, 0.1, mat("lip", hexc("C2303F")), y=-10)
    circle("Body", s * 0.38, 0.2, mat("body", hexc("FF6B78"), hexc("D63A4A")), y=-4)
    wm = mat("white", (1, 1, 1))
    for a in (45, -45):
        o = rrect("X", s * 0.44, s * 0.12, s * 0.06, 0.3, wm, y0=-4); o.rotation_euler[2] = math.radians(a)
    snowcap(s * 0.6, s * 0.36, 0.4, scale=0.9, seed=3, m=SNOW, shade=SNOWS)
    return render(name)

# ---------- icons (256 px, chunky, navy outline = slightly larger navy copy underneath) ----------
def outlined(shape_fn, m, out_m, grow=10):
    shape_fn(m, 0.2, 0)
    shape_fn(out_m, 0.0, grow)

def icon(name, draw, s=256):
    reset()
    camera(s, s, s, s)
    draw(s)
    return render(name)

def star_pts(r1, r2, n=5, rot=90, z=0):
    return [((r1 if i % 2 == 0 else r2) * math.cos(math.radians(rot + 180 * i / n)), (r1 if i % 2 == 0 else r2) * math.sin(math.radians(rot + 180 * i / n)), z) for i in range(2 * n)]

def ic_star(s):
    poly("o", star_pts(s * 0.46, s * 0.22), mat("n", NAVY))
    poly("b", star_pts(s * 0.38, s * 0.17, z=0.2), mat("g", hexc("FFE066"), hexc("F2A91C")))
    poly("h", [(p[0] * 0.5, p[1] * 0.5 + s * 0.06, 0.3) for p in star_pts(s * 0.38, s * 0.17)], mat("w", (1, 1, 1), alpha=0.35))
def ic_shield(s):
    def sh(r, z, m, dy=0):
        pts = [(-r, r * 0.9 + dy, z), (r, r * 0.9 + dy, z)]
        for i in range(17):
            a = math.radians(0 - 90 * i / 16); pts.append((r * math.cos(a) * (1 - i / 32), dy + r * 0.9 * math.sin(a) * 1.6 + r * 0.25, z))
        pts += [(0, -r * 1.25 + dy, z)]
        for i in range(17):
            a = math.radians(-90 - 90 * i / 16); pts.append((r * math.cos(a) * (0.5 + i / 32), dy + r * 0.9 * math.sin(a) * 1.6 + r * 0.25, z))
        return poly("s", pts, m)
    sh(s * 0.42, 0, mat("n", NAVY)); sh(s * 0.35, 0.2, mat("b", hexc("6FB6FF"), hexc("2F6FD0")), dy=-2)
    rrect("stripe", s * 0.1, s * 0.5, s * 0.04, 0.3, mat("w", (1, 1, 1), alpha=0.8), y0=-s * 0.04)
def ic_flame(s):
    def fl(r, z, m, dy=0):
        pts = []
        for i in range(40):
            t = i / 39 * 2 * math.pi
            x = r * 0.75 * math.sin(t) * (1 - 0.35 * math.cos(t))
            y = dy - r * 0.55 * math.cos(t) + r * 0.55 * (1 - math.cos(t)) ** 1.3 * 0.55
            pts.append((x, y - r * 0.3, z))
        return poly("f", pts, m)
    fl(s * 0.5, 0, mat("n", NAVY)); fl(s * 0.42, 0.2, mat("o", hexc("FFD25A"), hexc("FF6A2A")), dy=-3); fl(s * 0.22, 0.3, mat("y", hexc("FFF4B0")), dy=-s * 0.08)
def ic_pin(s):
    def pin(r, z, m, dy=0):
        pts = [(r * math.cos(math.radians(a)), dy + s * 0.08 + r * math.sin(math.radians(a)), z) for a in range(-30, 211, 8)]
        pts.append((0, dy - s * 0.42, z)); return poly("p", pts, m)
    pin(s * 0.36, 0, mat("n", NAVY)); pin(s * 0.29, 0.2, mat("r", hexc("FF7A86"), hexc("D63A4A")), dy=-3)
    circle("hole", s * 0.11, 0.3, mat("w", (1, 1, 1)), y=s * 0.07)
def ic_house(s):
    n = mat("n", NAVY)
    poly("roof_o", [(-s * 0.46, 0.02 * s, 0), (0, s * 0.44, 0), (s * 0.46, 0.02 * s, 0)], n)
    rrect("body_o", s * 0.66, s * 0.5, s * 0.06, 0, n, y0=-s * 0.18)
    rrect("body", s * 0.56, s * 0.42, s * 0.05, 0.2, mat("b", hexc("FFF0D6"), hexc("E8C79A")), y0=-s * 0.2)
    poly("roof", [(-s * 0.38, 0.04 * s, 0.25), (0, s * 0.37, 0.25), (s * 0.38, 0.04 * s, 0.25)], mat("r", hexc("FF7A86"), hexc("D63A4A")))
    rrect("door", s * 0.14, s * 0.22, s * 0.04, 0.3, mat("d", hexc("8A5530")), y0=-s * 0.3)
    snowcap(s * 0.5, s * 0.2, 0.35, scale=0.6, seed=5, m=mat("sn", (0.97, 0.99, 1.0)))
def ic_garage(s):
    n = mat("n", NAVY)
    poly("roof_o", [(-s * 0.48, 0.1 * s, 0), (0, s * 0.42, 0), (s * 0.48, 0.1 * s, 0)], n)
    rrect("body_o", s * 0.8, s * 0.5, s * 0.06, 0, n, y0=-s * 0.13)
    rrect("body", s * 0.7, s * 0.42, s * 0.05, 0.2, mat("b", hexc("9FC9EE"), hexc("5F8FCC")), y0=-s * 0.15)
    poly("roof", [(-s * 0.4, 0.12 * s, 0.25), (0, s * 0.35, 0.25), (s * 0.4, 0.12 * s, 0.25)], mat("r", hexc("5FA8F5"), hexc("2F6FD0")))
    for i in range(3):
        rrect("slat%d" % i, s * 0.42, s * 0.07, s * 0.02, 0.3, mat("s%d" % i, hexc("E6EEF8")), y0=-s * 0.04 - i * s * 0.1)
def ic_wrench(s):
    n = mat("n", NAVY); g = mat("g", hexc("D6DEE8"), hexc("8E9AAE"))
    for m, grow, z in ((n, 1.0, 0), (g, 0.82, 0.2)):
        o = rrect("bar", s * 0.16 * grow + (0 if grow < 1 else 8), s * 0.62, s * 0.06, z, m); o.rotation_euler[2] = math.radians(-45)
        c = circle("head", s * 0.2 * grow + (0 if grow < 1 else 4), z, m, x=s * 0.2, y=s * 0.2)
    circle("cut", s * 0.09, 0.3, mat("bg", NAVY), x=s * 0.27, y=s * 0.27)
def ic_cycle(s):
    n = mat("n", NAVY); b = mat("b", hexc("7CE09A"), hexc("2E9E52"))
    for m, r0, r1, z in ((n, s * 0.2, s * 0.42, 0), (b, s * 0.25, s * 0.36, 0.2)):
        for a0 in (20, 200):
            pts = [(r1 * math.cos(math.radians(a)), r1 * math.sin(math.radians(a)), z) for a in range(a0, a0 + 141, 7)]
            pts += [(r0 * math.cos(math.radians(a)), r0 * math.sin(math.radians(a)), z) for a in range(a0 + 140, a0 - 1, -7)]
            poly("arc", pts, m)
            a = math.radians(a0 + 140); ax, ay = math.cos(a), math.sin(a)
            mid = (r0 + r1) / 2; tip = (mid * math.cos(a + 0.45), mid * math.sin(a + 0.45))
            k = 1.35 if m is n else 1.0
            poly("tip", [(ax * (r0 - 14 * k), ay * (r0 - 14 * k), z), (ax * (r1 + 14 * k), ay * (r1 + 14 * k), z), (tip[0], tip[1], z)], m)
def ic_coin(s):
    circle("o", s * 0.44, 0, mat("n", NAVY)); circle("r", s * 0.38, 0.1, mat("d", hexc("E0A920")))
    circle("b", s * 0.32, 0.2, mat("g", hexc("FFE680"), hexc("F2B21C")))
    w = mat("w", (1, 1, 1))
    for a in (0, 60, 120):
        o = rrect("flake", s * 0.42, s * 0.06, s * 0.03, 0.3, w); o.rotation_euler[2] = math.radians(a)
def ic_brush(s):
    n = mat("n", NAVY)
    o = rrect("handle_o", s * 0.16, s * 0.62, s * 0.07, 0, n, y0=s * 0.1); o.rotation_euler[2] = math.radians(-35)
    o = rrect("handle", s * 0.1, s * 0.56, s * 0.05, 0.2, mat("h", hexc("C98F5E"), hexc("8A5530")), y0=s * 0.1); o.rotation_euler[2] = math.radians(-35)
    circle("tip_o", s * 0.17, 0, n, x=-s * 0.17, y=-s * 0.2); circle("tip", s * 0.13, 0.2, mat("p", hexc("FF8AC8"), hexc("D63A8A")), x=-s * 0.17, y=-s * 0.2)
def ic_door(s):
    n = mat("n", NAVY)
    rrect("door_o", s * 0.46, s * 0.74, s * 0.06, 0, n, x0=-s * 0.12)
    rrect("door", s * 0.38, s * 0.66, s * 0.05, 0.2, mat("d", hexc("C98F5E"), hexc("8A5530")), x0=-s * 0.12)
    circle("knob", s * 0.035, 0.3, mat("k", hexc("FFD95A")), x=-s * 0.0, y=0)
    poly("arrow_o", [(s * 0.1, s * 0.12, 0.25), (s * 0.3, s * 0.12, 0.25), (s * 0.3, s * 0.24, 0.25), (s * 0.47, 0, 0.25), (s * 0.3, -s * 0.24, 0.25), (s * 0.3, -s * 0.12, 0.25), (s * 0.1, -s * 0.12, 0.25)], n)
    poly("arrow", [(s * 0.13, s * 0.07, 0.3), (s * 0.32, s * 0.07, 0.3), (s * 0.32, s * 0.17, 0.3), (s * 0.43, 0, 0.3), (s * 0.32, -s * 0.17, 0.3), (s * 0.32, -s * 0.07, 0.3), (s * 0.13, -s * 0.07, 0.3)], mat("g", hexc("7CE09A"), hexc("2E9E52")))
def ic_help(s):
    circle("o", s * 0.44, 0, mat("n", NAVY)); circle("b", s * 0.37, 0.2, mat("y", hexc("FFE066"), hexc("F2A91C")))
    cu = bpy.data.curves.new("q", "FONT"); cu.body = "?"; cu.size = s * 0.62; cu.align_x = "CENTER"; cu.align_y = "CENTER"; cu.extrude = 0
    o = bpy.data.objects.new("q", cu); bpy.context.scene.collection.objects.link(o); o.location = (0, -s * 0.02, 0.3); o.data.materials.append(mat("t", NAVY))
def ic_wheel(s):
    n = mat("n", NAVY); g = mat("g", hexc("5A6478"))
    circle("o", s * 0.45, 0, n); circle("rim", s * 0.39, 0.1, mat("r", hexc("8E9AAE"), hexc("4A5468")))
    circle("in", s * 0.3, 0.15, mat("bg", hexc("DCE8F6")))
    for a in (90, 210, 330):
        o = rrect("sp", s * 0.07, s * 0.32, s * 0.03, 0.2, g, y0=0); o.rotation_euler[2] = math.radians(a)
        o.location = (math.cos(math.radians(a + 90)) * s * 0.15, math.sin(math.radians(a + 90)) * s * 0.15, 0)
    circle("hub", s * 0.1, 0.3, mat("h", hexc("FF6B78"), hexc("D63A4A")))

def tut_arrow(name, s=256):
    """tutorial pointer (2026-10-06): chunky gold arrow pointing DOWN, navy outline, snow on the shaft top (convex pieces only)"""
    reset(); camera(s, s, s, s)
    n = mat("n", NAVY); g = mat("g", hexc("FFE066"), hexc("F2A91C")); sn = mat("sn", (0.97, 0.99, 1.0))
    rrect("shaft_o", s * 0.34, s * 0.5, s * 0.08, 0, n, y0=s * 0.18)
    poly("head_o", [(-s * 0.44, s * 0.02, 0), (s * 0.44, s * 0.02, 0), (0, -s * 0.47, 0)], n)
    rrect("shaft", s * 0.24, s * 0.44, s * 0.06, 0.2, g, y0=s * 0.17)
    poly("head", [(-s * 0.35, s * -0.015, 0.2), (s * 0.35, s * -0.015, 0.2), (0, -s * 0.4, 0.2)], g)
    rrect("gloss", s * 0.07, s * 0.32, s * 0.03, 0.3, mat("w", (1, 1, 1), alpha=0.4), y0=s * 0.17, x0=-s * 0.05)
    snowcap(s * 0.3, s * 0.42, 0.35, scale=0.75, seed=11, m=sn)
    return render(name)

def ic_starterpack(s):
    """Starter Pack (2026-10-06): a gift box with a plow blade and a wheel, on a pile of snow (reads at 48 px)"""
    n = mat("n", NAVY); sn = mat("sn", (0.97, 0.99, 1.0)); sns = mat("sns", hexc("BFD8F2"))
    # snow pile (convex lumps) at the bottom
    for x, r in ((-0.26, 0.2), (0.0, 0.24), (0.27, 0.19)):
        circle("pile_o", s * r + 6, 0, n, x=s * x, y=-s * 0.3, seg=28)
    for x, r in ((-0.26, 0.2), (0.0, 0.24), (0.27, 0.19)):
        circle("pile", s * r, 0.25, sn, x=s * x, y=-s * 0.3, seg=28)
        circle("pileshade", s * r * 0.8, 0.2, sns, x=s * x, y=-s * 0.34, seg=24)
    # wheel peeking out on the left
    circle("wh_o", s * 0.17, 0.3, n, x=-s * 0.28, y=-s * 0.02); circle("wh", s * 0.13, 0.35, mat("whr", hexc("5A6478")), x=-s * 0.28, y=-s * 0.02)
    circle("whhub", s * 0.05, 0.4, mat("hub", hexc("FF6B78")), x=-s * 0.28, y=-s * 0.02)
    # plow blade leaning on the right
    o = rrect("bl_o", s * 0.16, s * 0.42, s * 0.05, 0.3, n, x0=s * 0.3, y0=s * 0.03); o.rotation_euler[2] = math.radians(-14)
    o = rrect("bl", s * 0.11, s * 0.37, s * 0.04, 0.35, mat("blc", hexc("FF6B5A"), hexc("C9302C")), x0=s * 0.3, y0=s * 0.03); o.rotation_euler[2] = math.radians(-14)
    # gift box in front
    rrect("box_o", s * 0.5, s * 0.4, s * 0.05, 0.5, n, y0=-s * 0.06)
    rrect("box", s * 0.42, s * 0.33, s * 0.04, 0.55, mat("bx", hexc("FFB04A"), hexc("E57A1E")), y0=-s * 0.07)
    rrect("lid_o", s * 0.56, s * 0.13, s * 0.04, 0.6, n, y0=s * 0.15)
    rrect("lid", s * 0.48, s * 0.08, s * 0.03, 0.65, mat("ld", hexc("FFD95A"), hexc("E0A920")), y0=s * 0.15)
    rrect("ribbon", s * 0.08, s * 0.4, s * 0.02, 0.7, mat("rb", hexc("5FA8F5")), y0=-s * 0.02)
    circle("bow1", s * 0.07, 0.72, mat("bw", hexc("5FA8F5")), x=-s * 0.06, y=s * 0.23); circle("bow2", s * 0.07, 0.72, mat("bw2", hexc("5FA8F5")), x=s * 0.06, y=s * 0.23)
    circle("knot", s * 0.04, 0.75, mat("kn", hexc("2F6FD0")), y=s * 0.22)
    # a snowflake badge on the box (the 3,000 Snow)
    w = mat("w", (1, 1, 1))
    for a in (0, 60, 120):
        o = rrect("fl", s * 0.17, s * 0.04, s * 0.018, 0.8, w); o.rotation_euler[2] = math.radians(a); o.location = (0, -s * 0.07, 0)
    snowcap(s * 0.5, s * 0.21, 0.78, scale=0.55, seed=4, m=sn)

ICONS = {"star": ic_star, "shield": ic_shield, "flame": ic_flame, "pin": ic_pin, "house": ic_house, "garage": ic_garage, "wrench": ic_wrench,
         "reroll": ic_cycle, "coin": ic_coin, "brush": ic_brush, "leave": ic_door, "help": ic_help, "wheel": ic_wheel}

if __name__ == "__main__":
    if "--arrow" in sys.argv:  # 2026-10-06 tutorial spotlight: render only the new pointer
        tut_arrow("tut_arrow"); print("DONE arrow"); raise SystemExit
    if "--starterpack" in sys.argv:  # 2026-10-06 Starter Pack card icon
        icon("icon_starterpack", ic_starterpack); print("DONE starterpack"); raise SystemExit
    slices = {}
    for cname, (l, d) in COLORS.items():
        button("btn_" + cname, l, d); slices["btn_" + cname] = {"size": [512, 192], "slice": [70, 70, 442, 150]}
    button("tab_on", "8FD0FF", "3F86E0", 384, 160, cap=False); slices["tab_on"] = {"size": [384, 160], "slice": [60, 50, 324, 120]}
    button("tab_off", "C9D6E8", "8F9DB5", 384, 160, cap=False); slices["tab_off"] = {"size": [384, 160], "slice": [60, 50, 324, 120]}
    panel("panel_dark", frame=("8FC6F2", "4F86D2"), inner=("4C8FE0", "1F3F82"), line="9FD3FF"); slices["panel_dark"] = {"size": [1024, 1024], "slice": [160, 200, 864, 864]}
    panel("panel"); slices["panel"] = {"size": [1024, 1024], "slice": [160, 200, 864, 864]}
    close_button("close"); slices["close"] = {"size": [256, 256]}
    for n, fn in ICONS.items():
        icon("icon_" + n, fn); slices["icon_" + n] = {"size": [256, 256]}
    json.dump(slices, open(os.path.join(HERE, "slices.json"), "w"), indent=1)
    print("DONE", len(slices))
