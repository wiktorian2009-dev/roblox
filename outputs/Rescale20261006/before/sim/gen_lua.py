# gen_lua.py - writes the production PlowConfig.luau from catalog.py + final_balance.json (single source of truth).
import json, os, math
HERE = os.path.dirname(os.path.abspath(__file__))
import evaluate as E, catalog as CAT, gamedata as G, model as M

E.apply_final()
cat = CAT.build()

ARCH_DESC = {
    "Blade": {"straight": "Dependable all-rounder: the same on soft powder and hard ice.", "sweeper": "Extra-wide sweep for soft snow; weaker on hard ice.",
              "scoop": "Curved scoop: wide and good in soft snow.", "icebreaker": "Narrow armoured edge that smashes hard ice.",
              "vshape": "V-wedge that splits tough snow - great on hard fields.", "toothed": "Teeth bite into hard ice; weaker in soft powder.",
              "segmented": "Segmented plates: steady all-rounder with a hard-ice edge.", "crystal": "Crystal edge: excellent on hard ice.",
              "pixel": "Blocky and wide: strong in soft snow.", "mechanical": "Grinding gears chew through hard ice.",
              "cosmic": "Cosmic edge: strong on every kind of snow."},
    "Engine": {"compact": "Light motor that speeds up quickly.", "twin": "Twin cylinders: balanced power and speed.",
               "industrial": "Heavy torque and big clearing power, slower to speed up.", "turbine": "High top speed and instant spin-up, a little less power.",
               "crystal": "Crystal core: solid power at a steady speed.", "pixel": "Arcade motor: balanced and peppy.",
               "clockwork": "Wind-up power with smooth acceleration.", "core": "Energy core: high power and high speed."},
    "Gear": {"smalltires": "Nimble and fast, but slides in turns.", "bigtires": "Chunky grip and stability with a small push bonus.",
             "studded": "Studs grip hard snow: great traction and extra push.", "tracks": "Grippy tracks that turn on the spot and push harder.",
             "widetracks": "Wide flotation tracks: the strongest push, slower but rock-steady.", "compacttracks": "Compact tracks: spin on the spot, very agile.",
             "flotation": "Balloon tires float on soft snow: stable with extra push.", "pixel": "Blocky wheels: light and nimble.",
             "hover": "Hover pods: fast and spin on the spot, but little grip.", "skis": "Ski runners: the fastest glide, very slippery.",
             "rings": "Orbit rings: fast, agile and grippy."},
}
ROLE_NOTE = {"S": " Free starter part - always yours.", "A": "", "B": " Premium part for its world.", "C": " A legendary saving goal!"}
STARTER_DESC = {"blade_basic": "A sturdy steel blade. Free and always yours.", "engine_starter": "Small but reliable. Free and always yours.",
                "gear_wheels": "Fast and nimble, but they slide. Free and always yours."}

def lnum(x):
    if isinstance(x, bool): return "true" if x else "false"
    if isinstance(x, int) or (isinstance(x, float) and x == int(x) and abs(x) < 1e15): return str(int(x))
    if abs(x) >= 1e15: return "%.6g" % x
    return ("%.4f" % x).rstrip("0").rstrip(".")

def sig(x, n=3):
    if x == 0: return 0
    return float("%.*g" % (n, x))

def lstr(s): return json.dumps(s)

lines = []
order = sorted(cat.values(), key=lambda p: (["Blade", "Engine", "Gear"].index(p["slot"]), p["band"], {"S": 0, "A": 1, "C": 3, "B": 2}[p["role"]], p["id"]))
for p in order:
    st = p["stats"]
    if p["slot"] == "Engine": st = {"Speed": sig(st["Speed"]), "Power": sig(st["Power"]), "AccelTime": st["AccelTime"]}
    if p["slot"] == "Gear": st = dict(st, PowerMult=sig(st["PowerMult"]))
    if p["slot"] == "Blade": st = dict(st, Soft=sig(st["Soft"]), Hard=sig(st["Hard"]))
    stats = ", ".join("%s = %s" % (k, lnum(v)) for k, v in st.items())
    desc = STARTER_DESC.get(p["id"]) or (ARCH_DESC[p["slot"]][p["archetype"]] + (ROLE_NOTE["C"] if p["rarity"] == "Legendary" else (ROLE_NOTE["B"] if p["role"] == "B" else "")))
    lines.append('\t%s = {Slot = "%s", Name = %s, Model = "%s", Rarity = "%s", Band = %d, Role = "%s", Theme = %s, Kind = "%s", Price = %s,\n\t\tDesc = %s, Stats = {%s}},' % (
        p["id"], p["slot"], lstr(p["name"]), p["model"], p["rarity"], p["band"], p["role"], lstr(p["theme"]), p["archetype"], lnum(float(p["price"])), lstr(desc), stats))

bands = ", ".join('"%s"' % s for s in G.FIELD_STAGES)
tough = ", ".join("%s = %s" % (s, lnum(v)) for s, v in G.TOUGH.items())
rel = ", ".join("[%d] = %s" % (k, lnum(v)) for k, v in sorted(M.REL.items()))
src = open(os.path.join(HERE, "PlowConfig_template.luau"), encoding="utf-8").read()
src = src.replace("--@@PARTS@@", "\n".join(lines)).replace("--@@BANDS@@", bands).replace("--@@TOUGH@@", tough).replace("--@@REL@@", rel)
out = os.path.join(HERE, "..", "build", "PlowConfig.luau")
os.makedirs(os.path.dirname(out), exist_ok=True)
open(out, "w", encoding="utf-8", newline="\n").write(src)
json.dump({p["id"]: dict(p, desc=STARTER_DESC.get(p["id"]) or (ARCH_DESC[p["slot"]][p["archetype"]] + (ROLE_NOTE["C"] if p["rarity"] == "Legendary" else (ROLE_NOTE["B"] if p["role"] == "B" else "")))) for p in order},
          open(os.path.join(HERE, "..", "data", "catalog_final.json"), "w"), indent=1)
print("wrote", out, len(lines), "parts")

