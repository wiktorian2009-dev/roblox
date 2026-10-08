# build_pets.py - rebuild of all 70 base pets (Claude, 2026-10-05). Headless:
#   blender -b --factory-startup -P build_pets.py -- --eggs SnowyEgg,DesertEgg [--export] [--render] [--blend] [--sheets]
#   --eggs all  builds every egg.  --sheets only composes sheets from existing tiles.
import sys, os, json, importlib
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE); sys.path.insert(0, r"C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender")
import bpy
from mathutils import Vector
import w2lib, petkit
from w2lib import Model, realize, export_fbx, stats, rbox, P
import glob
for _f in sorted(glob.glob(os.path.join(HERE, 'sp_*.py'))): importlib.import_module(os.path.basename(_f)[:-3])
from species_reg import REG
import render as R

EGGS = [
    ("SnowyEgg", ["Snow Bunny", "Penguin", "Arctic Fox", "Polar Bear", "Yeti"]),
    ("DesertEgg", ["Fennec Fox", "Camel", "Sand Lizard", "Scarab", "Sphinx Cat"]),
    ("CursedEgg", ["Shadow Bat", "Ghost", "Imp", "Shadow Wolf", "Void Demon"]),
    ("CrystalEgg", ["Gem Slime", "Crystal Bunny", "Prism Bird", "Crystal Golem", "Diamond Dragon"]),
    ("RetroEgg", ["Pixel Cat", "Arcade Bot", "Neon Frog", "Synth Fox", "Glitch Dragon"]),
    ("JungleEgg", ["Tree Frog", "Monkey", "Toucan", "Jaguar", "Tiki Guardian"]),
    ("AbsoluteZeroEgg", ["Frost Sprite", "Ice Seal", "Snow Owl", "Glacier Mammoth", "Absolute Phoenix"]),
    ("BlossomEgg", ["Koi", "Blossom Bunny", "Red Panda", "Crane", "Blossom Dragon"]),
    ("CandyEgg", ["Gummy Bear", "Marshmallow Bunny", "Cupcake Cat", "Candy Fox", "Sugar Dragon"]),
    ("PearlEgg", ["Crab", "Seahorse", "Turtle", "Manta Ray", "Ancient Sea Serpent"]),
    ("ToyCapsuleEgg", ["Teddy Bear", "Toy Duck", "Wind-up Mouse", "Toy Robot", "Plush Dinosaur"]),
    ("GearEgg", ["Brass Beetle", "Clockwork Bird", "Steam Pup", "Gear Fox", "Clockwork Dragon"]),
    ("CloudEgg", ["Cloud Lamb", "Cloud Kitten", "Thunder Owl", "Rainbow Pegasus", "Sky Whale"]),
    ("StarEgg", ["Comet Pup", "Moon Bunny", "Astro Cat", "Nebula Fox", "Galaxy Dragon"]),
    ("VerityEgg", ["Verity", "Falsity", "Cruelty", "Lord Verity", "Rainbow Verity"]),  # 2026-10-06: paid shop egg (sp_15_verity.py)
]
RAR = ["Common", "Common", "Uncommon", "Rare", "Legendary"]
SPACING = 9.0
def key_of(name): return name.replace(" ", "").replace("-", "")
def at_of(i): return (SPACING * (i + 1), 0.0, 0.0)

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
def opt(k): return k in argv
def val(k, d=None): return argv[argv.index(k) + 1] if k in argv else d
sel = val("--eggs", "all")
eggs = [e for e in EGGS if sel == "all" or e[0] in sel.split(",")]
OUTD = HERE; TILES = os.path.join(HERE, "renders", "tiles"); DATA = os.path.join(HERE, "data"); PACKS = os.path.join(HERE, "packs")
for d in (TILES, DATA, PACKS): os.makedirs(d, exist_ok=True)

def build_egg(ei, egg, names):
    models = []
    for i, name in enumerate(names):
        key = key_of(name)
        for sc in (1.0, 0.86, 0.74, 0.64, 0.55):
            petkit.SC[0] = sc; m = Model(key, at=at_of(i))
            kw = REG[name](m) or {}
            petkit.finish(m, RAR[i], **kw)
            if m.meta["tris"] <= 2450: break
            for b_ in m.parts.values(): b_.free()
        m.meta["seg_scale"] = sc; petkit.SC[0] = 1.0
        m.meta.update(name=name, egg=egg, rarity=RAR[i])
        models.append(m)
    meta = {m.name: dict(m.meta) for m in models}
    objs = realize(models, "Pets_" + egg)
    for o in objs:
        _, part, pc = o.name.split("__")[:3]
        o["part"], o["pc"], o["egg"] = part, pc.split(".")[0], egg
    return objs, meta

def marker(egg):
    mk = Model("Ref", at=(0, 0, 0)); rbox(mk, "FF00FFNE", (0, 0, 0), (0.2, 0.2, 0.2), r=0, part="Origin")
    o = realize([mk], "Ref_" + egg)[0]
    o.name = "Ref__Origin__FF00FFNE"; o.data.name = "Ref__Origin__FF00FFNE"
    return o

for _o in list(bpy.data.objects): bpy.data.objects.remove(_o, do_unlink=True)
def check_eyes(objs):
    """Each eye highlight (Shine island) must sit outside the pet's other surfaces with >= 0.04 stud clearance."""
    import bmesh as _bm
    from mathutils.bvhtree import BVHTree
    keys = sorted({o.name.split("__")[0] for o in objs}); bad = []
    for k in keys:
        mine = [o for o in objs if o.name.split("__")[0] == k]
        solid = [o for o in mine if petkit.role_of(o["part"]) in ("Body", "Belly", "Mark", "Accent", "Glow")]
        bm = _bm.new()
        for o in solid:
            t = _bm.new(); t.from_mesh(o.data); petkit._merge(bm, t)
        tree = BVHTree.FromBMesh(bm)
        for o in mine:
            if petkit.role_of(o["part"]) != "Shine": continue
            t = _bm.new(); t.from_mesh(o.data); t.verts.ensure_lookup_table()
            seen = set()
            for v in t.verts:
                if v.index in seen: continue
                isl, stack = [], [v]
                while stack:
                    x = stack.pop()
                    if x.index in seen: continue
                    seen.add(x.index); isl.append(x.co.copy())
                    stack += [e.other_vert(x) for e in x.link_edges]
                c = sum(isl, Vector()) / len(isl)
                hits = 0; p = c.copy()
                for _ in range(20):
                    h = tree.ray_cast(p, Vector((0.0123, 0.0071, 1)))
                    if h[0] is None: break
                    hits += 1; p = h[0] + Vector((0.0123, 0.0071, 1)).normalized() * 1e-4
                near = tree.find_nearest(c)
                d = near[3] if near[0] is not None else 9
                if hits % 2 == 1 or d < 0.04: bad.append((k, round(d, 3), hits % 2 == 1))
            t.free()
        bm.free()
    for b in bad: print("EYECHECK", b)
    print("EYECHECK done, issues:", len(bad))

R.setup() if (opt("--render") or opt("--sheets")) else None
cam = bpy.data.objects.get("PetCam"); txt = bpy.data.objects.get("PetLabel")
allobjs = []
for ei, (egg, names) in enumerate(EGGS):
    if (egg, names) not in eggs: continue
    objs, meta = build_egg(ei, egg, names)
    st = stats(objs)
    if opt("--check"): check_eyes(objs)
    rec = []
    for i, name in enumerate(names):
        k = key_of(name); s = st[k]
        rec.append({"name": name, "key": k, "egg": egg, "rarity": RAR[i], "at": list(at_of(i)), "tris": s["tris"],
                    "objects": s["parts"], "bbox_min": s["min"], "bbox_max": s["max"], "size": s["size"], "scale": meta[k].get("scale")})
        rec[-1]["seg_scale"] = meta[k].get("seg_scale")
        print("PET %-20s tris=%5d objs=%2d size=%s scale=%s seg=%s" % (name, s["tris"], len(s["parts"]), s["size"], meta[k].get("scale"), meta[k].get("seg_scale")))
    if opt("--export"):
        mk = marker(egg)
        path = os.path.join(PACKS, egg + "_Pets.fbx")
        export_fbx(objs + [mk], path)
        for r_ in rec: r_["pack"] = os.path.relpath(path, r"C:\Users\wikto\Desktop\Roblox Gra")
        bpy.data.objects.remove(mk, do_unlink=True)
    json.dump(rec, open(os.path.join(DATA, egg + ".json"), "w"), indent=1)
    if opt("--render"):
        for i, name in enumerate(names):
            k = key_of(name)
            for o in objs: o.hide_render = (o["part"] is None) or (o.name.split("__")[0] != k)
            tgt = Vector(at_of(i)) + Vector((0, 0, 1.55))
            R.assign_render_colors(objs, golden=False)
            R.render_tile(cam, tgt, os.path.join(TILES, k + ".png"))
            R.assign_render_colors(objs, golden=True)
            R.render_tile(cam, tgt, os.path.join(TILES, k + "_gold.png"))
            if not os.path.exists(os.path.join(TILES, k + "_label.png")) or opt("--labels"):
                for o in objs: o.hide_render = True
                R.render_label(cam, txt, name, os.path.join(TILES, k + "_label.png"))
        for o in objs: o.hide_render = True
        R.restore_materials(objs)
    # park the egg in its own row for the combined .blend
    for o in objs: o.location.y -= 10.0 * ei
    allobjs += objs

def sheet_egg(egg, names, gold=False):
    c = R.canvas(R.TILE_W * 5, R.TILE_H)
    for i, n in enumerate(names):
        k = key_of(n); p = os.path.join(TILES, k + ("_gold" if gold else "") + ".png")
        if os.path.exists(p): R.over(c, R.load(p), i * R.TILE_W, 0)
        lp = os.path.join(TILES, k + "_label.png")
        if os.path.exists(lp): R.over(c, R.load(lp), i * R.TILE_W, R.TILE_H - 46)
    R.save(c, os.path.join(HERE, "renders", "sheet_%s%s.png" % (egg, "_gold" if gold else "")))

def sheet_all(gold=False, small=False):
    names = [n for _, ns in EGGS for n in ns]
    if small:
        T = 96; c = R.canvas(T * 10, T * 7)
        for j, n in enumerate(names):
            p = os.path.join(TILES, key_of(n) + ".png")
            if os.path.exists(p): R.over(c, R.resize(R.crop_alpha(R.load(p)), T, T), (j % 10) * T, (j // 10) * T)
        R.save(c, os.path.join(HERE, "renders", "sheet_small96.png")); return
    tw, th = R.TILE_W // 2, R.TILE_H // 2; c = R.canvas(tw * 10, th * 7)
    for j, n in enumerate(names):
        k = key_of(n); p = os.path.join(TILES, k + ("_gold" if gold else "") + ".png")
        x, y = (j % 10) * tw, (j // 10) * th
        if os.path.exists(p): R.over(c, R.resize(R.load(p), tw, th), x, y)
        lp = os.path.join(TILES, k + "_label.png")
        if os.path.exists(lp): R.over(c, R.resize(R.load(lp), tw, 22), x, y + th - 24)
    R.save(c, os.path.join(HERE, "renders", "sheet_all%s.png" % ("_gold" if gold else "")))

if val("--review"):
    if not bpy.data.objects.get("PetCam"): R.setup()
    keys = val("--review").split(",")
    c = R.canvas(R.TILE_W * len(keys), R.TILE_H * 2)
    for i, k in enumerate(keys):
        for j, suf in enumerate(("", "_gold")):
            p = os.path.join(TILES, k + suf + ".png")
            if os.path.exists(p): R.over(c, R.load(p), i * R.TILE_W, j * R.TILE_H)
    R.save(c, os.path.join(HERE, "renders", "review.png"))
if opt("--render") or opt("--sheets"):
    for egg, names in eggs:
        sheet_egg(egg, names); sheet_egg(egg, names, gold=True)
if opt("--sheets"):
    sheet_all(); sheet_all(gold=True); sheet_all(small=True)
if opt("--blend"):
    for o in allobjs: o.hide_render = False
    for o in [o for o in bpy.data.objects if o.type != "MESH" or not o.get("pc")]:
        if o.name.startswith(("PetCam", "PetSun", "PetLabel")): bpy.data.objects.remove(o, do_unlink=True)
    for o in [o for o in bpy.data.objects if o.name in ("Cube", "Light", "Camera")]: bpy.data.objects.remove(o, do_unlink=True)
    w2lib.save_blend(os.path.join(HERE, "Pets70.blend"))
print("DONE", [e for e, _ in eggs])




