# catalog.py - gameplay stats + prices + offer roles for the 90-part catalog.
# Identity/visuals come from data/catalog_spec.py. Every number written into PlowConfig comes from here.
import json, math, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "data"))
import catalog_spec as spec
import gamedata as G

# ---- tunables (the balance tuner edits these) ----
P = {
    # engine clearing power of the band-k practical engine = E1 * prod(EG[1..k-1])
    "E1": 1.0,
    "EG": [3.2, 3.0, 2.6, 2.5, 2.5, 2.3, 1.55, 1.6, 1.5, 1.5, 1.5, 1.5, 1.5],  # growth band k -> k+1 (13 values)
    "BG": [1.15] * 13,   # blade level growth per band
    "GG": [1.07] * 13,   # gear PowerMult growth per band
    "PremiumPower": 1.7,  # B parts vs A parts of the same band (engine power / blade level)
    "PremiumGear": 1.12,
    "LegendC": 2.6,       # band-7 legendary vs band-7 A part
    # prices as a fraction of a stage cost: A = PA x cost(stage of band), B = PB x cost(next stage)
    "PA": 0.30, "PB": 0.22, "PC": 0.55,
}
# fixed prices for the original eight (existing offers keep their stored price anyway)
FIXED_PRICE = {"blade_wide": 120, "engine_balanced": 450, "gear_tracks": 650}

ENGINE_ARCH = {  # Speed base, power mod, accel time (s)
    "compact": (25, 0.92, 1.2), "twin": (29, 1.0, 1.5), "industrial": (26, 1.18, 2.1), "turbine": (34, 0.86, 1.0),
    "crystal": (29, 1.06, 1.6), "pixel": (30, 1.0, 1.3), "clockwork": (28, 1.04, 1.4), "core": (32, 1.1, 1.25),
}
BLADE_ARCH = {  # Soft, Hard
    "straight": (1.0, 1.0), "sweeper": (1.25, 0.6), "scoop": (1.12, 0.85), "icebreaker": (0.78, 1.6), "vshape": (0.9, 1.35),
    "toothed": (0.85, 1.45), "segmented": (1.0, 1.15), "crystal": (0.85, 1.55), "pixel": (1.12, 0.92), "mechanical": (0.9, 1.5),
    "cosmic": (1.15, 1.35),
}
GEAR_ARCH = {  # SpeedMult, Traction, Turn, Pivot, Stability, power mod
    "smalltires": (1.0, 0.55, 1.0, 0.15, 1.0, 0.96), "bigtires": (0.95, 0.72, 0.9, 0.2, 1.35, 1.05),
    "studded": (0.95, 0.9, 0.95, 0.22, 1.2, 1.05), "tracks": (0.85, 0.95, 0.9, 0.75, 1.7, 1.15),
    "widetracks": (0.8, 0.92, 0.8, 0.6, 2.0, 1.24), "compacttracks": (0.9, 0.95, 1.15, 1.0, 1.5, 1.1),
    "flotation": (0.95, 0.66, 0.95, 0.25, 1.6, 1.12), "pixel": (1.0, 0.7, 1.05, 0.35, 1.1, 1.0),
    "hover": (1.1, 0.62, 1.2, 0.9, 1.0, 0.98), "skis": (1.15, 0.42, 1.1, 0.1, 1.1, 0.97), "rings": (1.05, 0.8, 1.1, 0.6, 1.3, 1.06),
}
DRIVE_TOP_CAP = 60  # hard cap on top speed after every bonus (studs/s)

def stage_cost(band):
    sid = G.FIELD_STAGES[band - 1]
    if sid == "Sakura": sid = "Portal"
    return max(G.stage_cost(sid), 600)

def next_stage_cost(band):
    if band >= 14: return stage_cost(14) * 2.0
    return stage_cost(band + 1)

def level(growth, band):
    v = 1.0
    for g in growth[:band - 1]: v *= g
    return v

def nice(x):
    if x < 100: return int(round(x))
    e = 10 ** (math.floor(math.log10(x)) - 1)
    return int(round(x / e)) * e

def build():
    parts = spec.all_parts()
    out = {}
    for p in parts:
        k, role, slot = p["band"], p["role"], p["slot"]
        prem = role in ("B",)
        legend = role == "C" and k == 7
        if slot == "Engine":
            sp, pm, acc = ENGINE_ARCH[p["archetype"]]
            pw = P["E1"] * level(P["EG"], k) * pm
            if prem: pw *= P["PremiumPower"]
            if legend: pw *= P["LegendC"]
            if role == "S": pw, sp, acc = 1.0, 24, 1.6
            if role == "C" and k == 1: pw, sp, acc = 4.5 * pm, 30, 1.5   # Balanced Engine: old value 4.5
            if role == "A" and k == 1: pw = 2.2 * pm
            speed = min(40, sp + 0.45 * (k - 1) + (2 if prem else 0) + (3 if legend else 0))
            stats = {"Speed": round(speed, 1), "Power": round(pw, 3 if pw < 10 else 1) if pw < 1e4 else nice(pw), "AccelTime": acc}
        elif slot == "Blade":
            so, ha = BLADE_ARCH[p["archetype"]]
            lv = level(P["BG"], k) * (P["PremiumPower"] ** 0.5 if prem else 1) * (1.6 if legend else 1)
            w = round(p["visualWidth"] - 0.5, 1)
            if role == "S": so, ha, lv, w = 1.0, 1.0, 1.0, 7.0
            if p["id"] == "blade_wide": w = 12.0
            stats = {"Width": w, "Soft": round(so * lv, 2), "Hard": round(ha * lv, 2)}
        else:
            sm, tr, tu, pv, st, pm = GEAR_ARCH[p["archetype"]]
            lv = level(P["GG"], k) * (P["PremiumGear"] if prem else 1) * (1.15 if legend else 1)
            if role == "S": sm, tr, tu, pv, st, pm, lv = 1.0, 0.55, 1.0, 0.15, 1.0, 1.0, 1.0
            if p["id"] == "gear_tracks": sm, tr, tu, pv, st, pm, lv = 0.85, 0.95, 0.9, 0.75, 1.7, 1.15, 1.0
            stats = {"SpeedMult": sm, "Traction": tr, "Turn": tu, "Pivot": pv, "Stability": st, "PowerMult": round(pm * lv, 3)}
        if role == "S": price = 0
        elif p["id"] in FIXED_PRICE: price = FIXED_PRICE[p["id"]]
        elif k == 1: price = {"Blade": 120, "Engine": 300, "Gear": 220}[slot] if role == "A" else 650
        elif role == "A": price = nice(P["PA"] * stage_cost(k))
        elif role == "B": price = nice(P["PB"] * next_stage_cost(k))
        else: price = nice(P["PC"] * next_stage_cost(k + 1))
        out[p["id"]] = dict(p, stats=stats, price=price)
    return out

if __name__ == "__main__":
    c = build()
    json.dump(c, open(os.path.join(HERE, "catalog_built.json"), "w"), indent=1)
    for pid, p in c.items(): print(pid, p["band"], p["role"], p["price"], p["stats"])

