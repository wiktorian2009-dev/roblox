# bay_open.py - open-air garage bay shell, 48 x 45 (Claude, 2026-10-06). Replaces the stretched GarageBay shell:
# no roof, rafters, hanging lamps or corner pillars; waist-high snowy fences; low back wall; matte painted colours;
# the BAY sign stands on a slim post at the entrance (front-right as seen from the street).
# Blender: front = -Y, up = +Z, origin = bay floor centre. Studio local = (-x, z, y).
# usage: blender -b --factory-startup -P bay_open.py -- [--export] [--render]
import bpy, sys, os, math
from mathutils import Vector
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, r"C:\Users\wikto\Desktop\Roblox Gra\outputs\SharedGarage20261005")
sys.path.insert(0, r"C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender")
import w2lib as L
from w2lib import P, cyl
import models as SG

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
bx, ring, snowcap = SG.bx, SG.ring, SG.snowcap
HX, HY = 24.0, 22.5
FLOOR, LANE, SAND, TURN = "D9DEE6", "AFC0D4", "E3CD8F", "BCC9DA"
FENCE, KICK, WOODM, TRIM, CHEST, CRATE, POST, BOARD = "C99263", "9DB9D8", "C99263", "F2F4F7", "C2514A", "A9622F", "4A5160", "2F4F86"
SNOW = SG.SNOW


def BayOpen(m):
    bx(m, "Floor", FLOOR, -HX, HX, -HY, HY, -1.2, 0, r=0.08)
    z0, z1 = -0.03, 0.02  # flush paint
    for sx in (-1, 1):
        bx(m, "Lane", LANE, *sorted((sx * 21.6, sx * 22.2)), -21.0, 20.4, z0, z1, r=0)
    bx(m, "Lane", LANE, -22.2, 22.2, 19.8, 20.4, z0, z1, r=0)
    bx(m, "Sand", SAND, -21.9, 21.9, -22.3, -21.6, z0, z1, r=0)           # entrance line (soft, matte)
    ring(m, P(TURN), (0, 6), 11.6, 12.2, z0, z1, seg=48, part="Turn")     # turntable parking ring
    # waist-high snowy fences between bays (x = +-23.7)
    for sx in (-1, 1):
        x = sx * 23.7
        bx(m, "Kick", KICK, x - 0.12, x + 0.12, -21.0, 21.0, 0, 0.6, r=0.05)
        bx(m, "Fence", FENCE, x - 0.14, x + 0.14, -21.0, 21.0, 1.85, 2.15, r=0.06)
        for y in (-21.0, -14.0, -7.0, 0.0, 7.0, 14.0, 21.0):
            bx(m, "Fence", FENCE, x - 0.2, x + 0.2, y - 0.2, y + 0.2, 0, 2.3, r=0.08)
        snowcap(m, x - 0.16, x + 0.16, -21.0, 21.0, 2.15, t=0.22, ov=0.06)
    # low back wall
    bx(m, "Wood", WOODM, -23.4, 23.4, 21.2, 22.2, 0, 2.5, r=0.12)
    bx(m, "Trim", TRIM, -23.5, 23.5, 21.1, 22.3, 2.45, 2.7, r=0.08)
    snowcap(m, -23.4, 23.4, 21.2, 22.2, 2.7, t=0.3, ov=0.05)
    # floor props against the back wall (outside every clear zone)
    bx(m, "Chest", CHEST, 4.0, 6.6, 19.2, 20.8, 0, 2.6, r=0.15)
    for z in (0.7, 1.4, 2.1):
        bx(m, "Trim", TRIM, 4.5, 6.1, 19.08, 19.2, z - 0.06, z + 0.06, r=0.03)
    bx(m, "Crate", CRATE, -10.0, -7.6, 18.6, 20.6, 0, 1.6, r=0.12)
    for z in (0.4, 1.2):
        bx(m, "Wood", WOODM, -10.05, -7.55, 18.55, 20.65, z - 0.12, z + 0.12, r=0.05)
    snowcap(m, -10.0, -7.6, 18.6, 20.6, 1.6, t=0.25, ov=0.05)
    # BAY sign on a slim post at the entrance (Studio local x +21, z -21.5); the SignPanel SurfaceGui sits on its front face
    px, py = -21.0, -21.5
    cyl(m, P(POST), (px, py, 0.0), r=0.6, h=0.3, seg=12, part="Post")
    cyl(m, P(POST), (px, py, 0.3), r=0.2, h=4.4, seg=10, part="Post")
    bx(m, "Board", BOARD, px - 3.3, px + 3.3, py - 0.15, py + 0.15, 4.6, 7.4, r=0.12)
    snowcap(m, px - 3.3, px + 3.3, py - 0.15, py + 0.15, 7.4, t=0.28, ov=0.08)


def build():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    m = L.Model("BayOpen", at=(0, 0, 0)); BayOpen(m)
    return L.realize([m], "Pack_BayOpen")


def check(objs):
    # nothing between z 0.05 and 7.5 inside the pedestal / workbench / turntable zones (Blender coords)
    zones = [(-17.25, -12, 3.7, 3.7), (-17.25, 0, 3.7, 3.7), (-17.25, 12, 3.7, 3.7), (17.25, -7.5, 4.2, 4.2), (17.25, 10.5, 3.5, 1.6)]
    bad, top = 0, 0.0
    for o in objs:
        for v in o.data.vertices:
            p = o.matrix_world @ v.co
            top = max(top, p.z)
            if 0.05 < p.z < 7.5 and (math.hypot(p.x, p.y - 6) < 11.3 or any(abs(p.x - cx) <= hx and abs(p.y - cy) <= hy for cx, cy, hx, hy in zones)):
                bad += 1
    print("CHECK intrusions=%d  top z=%.2f" % (bad, top))


if __name__ == "__main__":
    objs = build()
    print("STAT", sum(len(p.vertices) - 2 for o in objs for p in o.data.polygons), "tris", len(objs), "objs", [o.name for o in objs])
    check(objs)
    if "--export" in argv:
        mm = L.Model("Ref", at=(0, 0, 0)); L.rbox(mm, "FF00FFNE", (0, 0, 0), (0.2, 0.2, 0.2), r=0.0, part="Origin")
        ref = L.realize([mm], "Ref")[0]; ref.name = "Ref__Origin__FF00FFNE"; ref.data.name = "Ref__Origin__FF00FFNE"
        os.makedirs(os.path.join(HERE, "fbx"), exist_ok=True)
        path = os.path.join(HERE, "fbx", "Pack_BayOpen.fbx")
        L.export_fbx(objs + [ref], path); print("EXPORTED", path, os.path.getsize(path))
    if "--render" in argv:
        import importlib.util
        spec = importlib.util.spec_from_file_location("sg_scene", r"C:\Users\wikto\Desktop\Roblox Gra\outputs\SharedGarage20261005\scene.py")
        S = importlib.util.module_from_spec(spec); spec.loader.exec_module(S)
        S.setup(res=(1500, 950), samples=24)
        os.makedirs(os.path.join(HERE, "renders"), exist_ok=True)
        S.camera((10, -48, 9), (0, 0, 1.5), lens=24); S.render(os.path.join(HERE, "renders", "bay_open_eye.png"))
        S.camera((40, -55, 40), (0, 0, 0), lens=30); S.render(os.path.join(HERE, "renders", "bay_open_high.png"))
    print("DONE")
