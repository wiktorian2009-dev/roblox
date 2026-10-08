# gen_lua2.py - writes the 135-part PlowConfig from catalog2 + final_variant.json, splicing the generated C.Parts block and the
# offer-pool roles into the LIVE PlowConfig source (keeps every newer edit: drive/car settings, vehicle, clearing).
# The authoritative economy now lives in outputs/Rebalance20261005 (catalog_spec2 + catalog2 + final_variant.json).
import json, os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import exp, gamedata as G, model as M, catalog2 as C2

LIVE = r"C:\Users\wikto\Desktop\Roblox Gra\game\src\ReplicatedStorage\PlowConfig.luau"
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
    "Body": {"classic": "The original plow cab.", "steady": "Sturdy shell: a little more Snow per tile and steadier on bumps.", "nimble": "Light shell: a little more Snow per tile and quicker steering.",
             "grip": "Grippy shell: a little more Snow per tile and a touch more grip.", "titan": "Armoured titan shell: more Snow per tile, extra grip and stability.",
             "cosmic": "Star shell: the most Snow per tile, with extra grip and steering."},
}
STARTER_DESC = {"blade_basic": "A sturdy steel blade. Free and always yours.", "engine_starter": "Small but reliable. Free and always yours.", "body_starter": "The original red plow cab. Free and always yours.",
                "gear_wheels": "Fast and nimble, but they slide. Free and always yours."}

def lnum(x):
    if isinstance(x, bool): return "true" if x else "false"
    if isinstance(x, int) or (isinstance(x, float) and x == int(x) and abs(x) < 1e15): return str(int(x))
    if abs(x) >= 1e15: return "%.6g" % x
    return ("%.4f" % x).rstrip("0").rstrip(".")

def sig(x, n=3):
    return 0 if x == 0 else float("%.*g" % (n, x))

def desc(p):
    if p["id"] in STARTER_DESC: return STARTER_DESC[p["id"]]
    d = ARCH_DESC[p["slot"]][p["archetype"]]
    if p["rarity"] == "Legendary": return d + " A legendary saving goal!"
    if p["role"] == "B": return d + " Premium part for its world."
    if p["role"] == "M": return d + " A solid step up between its world's starter and premium parts."
    return d

def generate(v):
    cat, pol = exp.setup(v)
    order = sorted(cat.values(), key=lambda p: (["Blade", "Engine", "Gear", "Body"].index(p["slot"]), p["band"], {"S": 0, "A": 1, "M": 2, "B": 3, "C": 4}[p["role"]], p["price"], p["id"]))
    lines = []
    for p in order:
        st = p["stats"]
        if p["slot"] == "Engine": st = {"Speed": sig(st["Speed"]), "Power": sig(st["Power"]), "AccelTime": st["AccelTime"]}
        if p["slot"] == "Gear": st = dict(st, PowerMult=sig(st["PowerMult"]))
        if p["slot"] == "Blade": st = dict(st, Soft=sig(st["Soft"]), Hard=sig(st["Hard"]))
        stats = ", ".join("%s = %s" % (k, lnum(val)) for k, val in st.items())
        lines.append('\t%s = {Slot = "%s", Name = %s, Model = "%s", Rarity = "%s", Band = %d, Role = "%s", Theme = %s, Kind = "%s", Price = %s,\n\t\tDesc = %s, Stats = {%s}},' % (
            p["id"], p["slot"], json.dumps(p["name"]), p["model"], p["rarity"], p["band"], p["role"], json.dumps(p["theme"]), p["archetype"], lnum(float(p["price"])), json.dumps(desc(p)), stats))
    return cat, lines

if __name__ == "__main__":
    # RESCALE 2026-10-06: the authoritative variant is now rescale_final.json (compressed economy); final_variant.json = the old scale
    vpath = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "rescale_final.json")
    v = json.load(open(vpath))
    cat, lines = generate(v)
    src = open(LIVE, encoding="utf-8").read()
    a = src.index("C.Parts = {\n"); b = src.index("\n}\nfor id, def in pairs(C.Parts)")
    src = src[:a] + "C.Parts = {\n" + "\n".join(lines) + src[b:]
    def _once(old, new):  # idempotent: never apply a text patch twice (the live file may already contain it)
        return src if new in src else src.replace(old, new)
    src = _once("-- 2026-10-05 (Claude): 90-part catalog (30 blades, 30 engines, 30 running gear), progression-aware offer pool with luck that never removes\n-- practical parts, bad-luck protection, engine acceleration, explicit field toughness. Generated from\n-- outputs/PlowExpansion20261005/sim (catalog.py + final_balance.json -> gen_lua.py); edit those and regenerate, or edit here carefully.",
        "-- 2026-10-05 (Claude): 135-part catalog (45 blades, 45 engines, 45 running gear), progression-aware offer pool with luck that never removes\n-- practical parts, bad-luck protection, engine acceleration, explicit field toughness.\n-- REBALANCE 2026-10-05: role M = mid-band step between a world's practical A part and its premium B part; blades and gears now grow\n-- enough per world to be meaningful upgrades. The parts table is generated from outputs/Rebalance20261005/sim (catalog_spec2 +\n-- catalog2 + final_variant.json -> gen_lua2.py, which splices it into this file); regenerate there instead of hand-editing prices.")
    src = _once("-- Band = progression theme (1 Starter ... 7 Absolute Zero, 8 Sakura ... 14 Cosmic). Role: S starter, A practical, B premium, C legendary.",
                      "-- Band = progression theme (1 Starter ... 7 Absolute Zero, 8 Sakura ... 14 Cosmic). Role: S starter, A practical, M mid-band step, B premium, C legendary.")
    src = _once("\tRoleWeight = {A = 1.0, B = 0.42, C = 0.16},", "\tRoleWeight = {A = 1.0, M = 0.7, B = 0.42, C = 0.16}, -- rebalance: M = mid-band step parts")
    src = _once("\t\t\t\tlocal practical = def.Role == \"A\" and (d == 0 or d == -1)", "\t\t\t\tlocal practical = (def.Role == \"A\" or def.Role == \"M\") and (d == 0 or d == -1)")
    src = _once("-- OFFER POOL: relevance to the player's progression band x role weight x luck (rare parts only). The practical group (Common-role parts of",
                      "-- OFFER POOL: relevance to the player's progression band x role weight x luck (rare parts only). The practical group (A and M parts of")
    src = _once("\tProtectAfter = 6,     -- bad-luck protection: after 6 rolls in a row without a USEFUL offer, the next roll is drawn only from useful parts\n",
        "\tProtectAfter = 6,     -- bad-luck protection: after 6 rolls in a row without a USEFUL offer, the next roll is drawn only from useful parts\n\tProtectAffordMinutes = 10, -- rebalance: ...preferring useful parts affordable from Snow in hand + this many minutes of recent Snow/s\n")
    src = _once("for id, def in pairs(C.Parts) do def.Id = id; def.Weight = def.Role == \"S\" and 0 or 1 end -- Weight kept for older readers; odds come from C.OfferPool\n",
        "for id, def in pairs(C.Parts) do def.Id = id; def.Weight = def.Role == \"S\" and 0 or 1 end -- Weight kept for older readers; odds come from C.OfferPool\n"
        "-- rebalance 2026-10-05: price of a saved offer / reservation = the price it was rolled with, or the current catalog price if that is lower\n"
        "-- (catalog price drops are passed on; a shown price never rises)\n"
        "function C.OfferPrice(o)\n\tif type(o) ~= \"table\" then return 0 end\n\tlocal stored = tonumber(o.Price) or 0\n\tlocal def = C.Parts[o.Part or \"\"]\n"
        "\tif def and def.Price and def.Price > 0 and (stored <= 0 or def.Price < stored) then return def.Price end\n\treturn stored\nend\n")
    assert "ProtectAffordMinutes" in src and "function C.OfferPrice" in src
    assert src.count("RoleWeight = {") == 1 and 'def.Role == "M"' in src   # 2026-10-06: weights are tuned in the live file (task 2)
    out = os.path.join(HERE, "..", "build", "PlowConfig.luau")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    open(out, "w", encoding="utf-8", newline="\n").write(src)
    json.dump({p["id"]: dict(p, desc=desc(p)) for p in cat.values()}, open(os.path.join(HERE, "..", "data", "catalog_final135.json"), "w"), indent=1)
    from collections import Counter
    print("wrote", out, len(lines), "parts", dict(Counter(p["slot"] for p in cat.values())), len(src), "chars")
