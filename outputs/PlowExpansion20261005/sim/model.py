# model.py - production formulas mirrored from PlowConfig.StatsFor / SnowFieldService.collect (and the new offer pool).
import math
import gamedata as G

BASE_POWER = 4.5
BLADE_DEPTH = 2.6
SLACK = 0.3 * G.TILE
MAX_WIDTH_MULT = 1.6
TOP_CAP = 60.0
ACCEL_DEFAULT = 1.6

def stats_for(cat, build, mods):
    b, e, g = cat.get(build.get("Blade")), cat.get(build.get("Engine")), cat.get(build.get("Gear"))
    bs = b["stats"] if b else {"Width": 0, "Soft": 0, "Hard": 0}
    es = e["stats"] if e else {"Speed": 0, "Power": 0, "AccelTime": ACCEL_DEFAULT}
    gs = g["stats"] if g else {"SpeedMult": 0, "Traction": 0, "Turn": 0, "Pivot": 0, "Stability": 1, "PowerMult": 1}
    raw = max(1.0, mods.get("SizeMult", 1) * mods.get("ReachMult", 1))
    wm = min(raw, MAX_WIDTH_MULT)
    wp = max(1.0, raw / MAX_WIDTH_MULT)
    power = (BASE_POWER * es["Power"] * gs["PowerMult"] + mods.get("PowerBonus", 0) * BASE_POWER) * mods.get("PowerMult", 1) * mods.get("SpinMult", 1) * wp
    top = min(TOP_CAP, es["Speed"] * gs["SpeedMult"] * mods.get("SpeedMult", 1))
    return {"MaxSpeed": top, "Accel": top / es.get("AccelTime", ACCEL_DEFAULT), "Traction": gs["Traction"], "Pivot": gs["Pivot"],
            "Turn": gs["Turn"], "BladeWidth": bs["Width"] * wm, "Soft": bs["Soft"], "Hard": bs["Hard"], "ClearPower": power if b else 0}

def handling(st):
    # share of top speed that is productive while sweeping a field with turns (model assumption, documented)
    h = 0.42 + 0.32 * st["Traction"] + 0.14 * min(st["Pivot"], 1.0) + 0.06 * min(st["Turn"], 1.2) / 1.2
    acc_pen = min(0.12, 0.6 / max(st["Accel"], 1e-6))   # slow acceleration costs a little at every turn
    return max(0.3, min(0.9, h - acc_pen))

PLOWING_SPEED = 0.6  # 2026-10-05: PlowConfig.Drive.PlowingSpeedFactor (top speed while the blade is over a field)
SPP_MULT = {}   # balance tuner: new SnowPerPhase = live value x this
HP_MULT = {}

def field_rates(st, stage):
    hp, spp, regrow = G.STAGE_FIELD[stage]
    spp *= SPP_MULT.get(stage, 1.0)
    hp *= HP_MULT.get(stage, 1.0)
    tough = G.TOUGH[stage]
    w = st["BladeWidth"] + 2 * SLACK
    eff = st["Soft"] + (st["Hard"] - st["Soft"]) * tough
    nc = (w / G.TILE) * ((BLADE_DEPTH + 2 * SLACK) / G.TILE)
    power = nc * st["ClearPower"] * eff / hp
    cover = 3.0 * (w / G.TILE) * (st["MaxSpeed"] * PLOWING_SPEED * handling(st)) / G.TILE
    area = max(G.zone_tiles(z) for z in G.ZONES[stage])
    regrow_cap = 0.92 * area / regrow
    return power, cover, regrow_cap, spp

def smin(*xs, k=4.0):
    return sum(x ** -k for x in xs if x > 0) ** (-1.0 / k) if all(x > 0 for x in xs) else 0.0

def layer_rate(st, stage):
    p, c, r, spp = field_rates(st, stage)
    return smin(p, c, r)

def score(st, stage):
    """Productive score used for 'useful offer' checks (no regrowth cap - server version reads only stage HP/toughness)."""
    p, c, r, spp = field_rates(st, stage)
    return smin(p, c)

# ---- offer pool (mirrors PlowConfig.OfferPool) ----
RANK = {"Starter": 1, "Common": 2, "Uncommon": 3, "Rare": 4, "Epic": 5, "Legendary": 6}
REL = {-3: 0.04, -2: 0.2, -1: 0.85, 0: 1.0, 1: 0.5, 2: 0.16, 3: 0.05}
ROLE_W = {"A": 1.0, "B": 0.42, "C": 0.16}
PRACTICAL_FLOOR = 0.45

def luck_factor(luck):
    return min(2.0, 1.0 + 0.25 * math.log2(max(1.0, luck)))

def offer_pool(cat, band, luck):
    lf = luck_factor(luck)
    w, prac = {}, {}
    for pid, p in cat.items():
        if p["role"] == "S": continue
        d = p["band"] - band
        rel = REL.get(d, 0.04 if d < -3 else 0.0)
        if rel <= 0: continue
        if p["band"] == 1 and band > 1: rel = max(rel, 0.04)
        x = rel * ROLE_W[p["role"]] * lf ** max(0, RANK[p["rarity"]] - 3) ** 1
        if RANK[p["rarity"]] > 3: x = rel * ROLE_W[p["role"]] * lf ** (RANK[p["rarity"]] - 3)
        w[pid] = x
        prac[pid] = p["role"] == "A" and d in (-1, 0)
    tot = sum(w.values()); ptot = sum(v for k, v in w.items() if prac[k])
    if ptot > 0 and ptot / tot < PRACTICAL_FLOOR:
        s = PRACTICAL_FLOOR * (tot - ptot) / ((1 - PRACTICAL_FLOOR) * ptot)
        for k in w:
            if prac[k]: w[k] *= s
        tot = sum(w.values())
    return {k: v / tot for k, v in w.items()}

