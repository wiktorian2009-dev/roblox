# compress.py - RESCALE 2026-10-06 (Claude): "no amounts beyond the trillions, no big jumps".
# Every GROWTH multiplier of the economy is raised to the power c (< 1), so income grows much more gently over the whole game:
#   field SnowPerPhase and TileHP (relative to the Starter field), engine Power, gear PowerMult, blade Soft/Hard levels,
#   multiplicative Snow/clearing-power upgrades (1 + a) -> (1 + a)^c, pet boosts, body Snow efficiency, Snow per rebirth.
# Prices are NOT transformed here: the stage gates are re-tuned against the compressed income (tune_gates.py), and parts, World 1
# upgrades, World 2 upgrades, eggs and rebirth milestones follow the gates exactly as before (exp.setup / catalog2.price_of).
# Rates that are already income-relative (jobs, quests, boss, cocoa, treasures, chests, daily, wheel) need no change.
# The same functions are used by emit_rescale.py to write the live configs, so sim and game always agree.
import copy, math
import gamedata as G, model as M

_ORIG = {}

def snapshot():
    if _ORIG: return
    _ORIG["UPG"] = copy.deepcopy(G.UPGRADES)
    _ORIG["EGGS"] = copy.deepcopy(G.EGGS)
    _ORIG["REBIRTH"] = copy.deepcopy(G.REBIRTH)

def grow(x, c):              # dimensionless growth factor (1 = starting value)
    return x ** c if x > 0 else x
def q05(x):                  # same rounding as the live UpgradeConfig compression step (0.05 steps, at least 0.05)
    return max(0.05, math.floor(x / 0.05 + 0.5) * 0.05)
def mul_amount(a, c):        # upgrade Effect {Stat, a, "Mul"} = x(1 + a)
    return round(q05((1 + a) ** c - 1), 2)
def pet_boost(b, c):         # a full row of 3 equal pets keeps (1 + 3b)^c
    return round(((1 + 3 * b) ** c - 1) / 3, 4)
def body_snow(s, c):
    return round((1 + s) ** c - 1, 4)
def field(value, start, c):  # SnowPerPhase / TileHP relative to the Starter field
    return start * (value / start) ** c

def apply(cat, cz):
    """apply compression in place to the sim data (idempotent: always starts from the snapshot)"""
    snapshot()
    amt = {u["Id"]: u["Amt"] for u in _ORIG["UPG"]}
    for u in G.UPGRADES: u["Amt"] = amt[u["Id"]]   # only effect sizes are restored (costs were just set by exp.setup)
    G.EGGS[:] = copy.deepcopy(_ORIG["EGGS"]); G.REBIRTH.clear(); G.REBIRTH.update(copy.deepcopy(_ORIG["REBIRTH"]))
    if not cz: return cat
    c = cz["c"]
    # fields (HP_MULT was just set by evaluate.apply_final from the live TileHP)
    hp0 = G.STAGE_FIELD["Starter"][0] * M.HP_MULT.get("Starter", 1.0)
    sp0 = G.STAGE_FIELD["Starter"][1]
    M.SPP_MULT.clear()
    for s, (hp, spp, rg) in G.STAGE_FIELD.items():
        h = hp * M.HP_MULT.get(s, 1.0)
        M.HP_MULT[s] = field(h, hp0, cz.get("cHP", c)) / hp
        M.SPP_MULT[s] = field(spp, sp0, c) / spp
    for u in G.UPGRADES:
        if u["Mul"] and u["Stat"] in ("SnowMult", "PowerMult"): u["Amt"] = mul_amount(u["Amt"], c)
    import sim
    G.EGGS[:] = [tuple(list(e[:3]) + [[(n, ch, pet_boost(bo, c)) for n, ch, bo in e[3]]]) for e in _ORIG["EGGS"]]
    sim.PET_BOOST.clear()
    for e in G.EGGS:
        for n, ch, bo in e[3]: sim.PET_BOOST[n] = bo
    G.REBIRTH["Snow"] = cz.get("RebirthSnow", 0.22)
    for p in cat.values():
        st = p["stats"]
        if p["slot"] == "Engine": st["Power"] = round(grow(st["Power"], c), 4)
        elif p["slot"] == "Gear": st["PowerMult"] = round(grow(st["PowerMult"], c), 4)
        elif p["slot"] == "Blade":
            st["Soft"], st["Hard"] = round(grow(st["Soft"], c), 3), round(grow(st["Hard"], c), 3)
        elif p["slot"] == "Body" and "Snow" in st: st["Snow"] = body_snow(st["Snow"], c)
    return cat

def restore_pets():
    import sim
    sim.PET_BOOST.clear()
    for e in (_ORIG.get("EGGS") or G.EGGS):
        for n, ch, bo in e[3]: sim.PET_BOOST[n] = bo
