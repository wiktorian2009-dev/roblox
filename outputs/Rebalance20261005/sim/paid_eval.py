# paid_eval.py - task 8: effect of the paid offers on non-paid pacing (fixed seeds, value buyer). Model estimates, not playtests.
# Compares World 1 minutes / stage arrival for: free, Starter Pack, Aurora Wheels (several PowerMult candidates), 1.5x Snow.
import json, os, statistics, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import exp, sim2, gamedata as G
from evaluate import Biased

PACK = {"Blade": "blade_dune", "Engine": "engine_sandrunner", "Gear": "gear_balloon", "Body": "body_dunerunner"}
PACK_SNOW = 3000

def aurora(pm):
    return {"id": "gear_aurorawheels", "name": "Aurora Wheels", "slot": "Gear", "band": 1, "role": "P", "rarity": "Legendary", "model": "GearAuroraWheels",
            "archetype": "bigtires", "price": 0, "stats": {"SpeedMult": 1.0, "Traction": 0.92, "Turn": 1.15, "Pivot": 0.7, "Stability": 1.5, "PowerMult": pm}}

def run(cat, pol, seed, beh, opt):
    p = sim2.Player2(cat, beh, seed, policy=pol); p.smart = True; p.PITY_AFFORD = True
    if opt.get("pack"):
        for s, pid in PACK.items(): p.owned[pid] = 1     # owned, not auto-equipped: the value buyer equips if better
        p.snow += PACK_SNOW
        for s, pid in PACK.items():
            b = dict(p.build); b[s] = pid
            if p.income(build=b)[0] > p.income()[0]: p.build[s] = pid
    if opt.get("aurora"):
        p.owned["gear_aurorawheels"] = 1
        b = dict(p.build); b["Gear"] = "gear_aurorawheels"
        if p.income(build=b)[0] > p.income()[0]: p.build["Gear"] = "gear_aurorawheels"
    if opt.get("snow15"): p.PAID_SNOW = 1.5
    p.dirty = True
    while "Portal" not in p.stages and p.t < 14 * 3600: p.step()
    return p

if __name__ == "__main__":
    v = json.load(open(os.path.join(HERE, "final_variant.json")))
    cat, pol = exp.setup(v)
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 12
    cases = [("free", {}), ("starterPack", {"pack": True}), ("snow1.5", {"snow15": True})]
    for pm in (1.6, 1.75, 1.9):
        cases.append(("aurora%.2f" % pm, {"aurora": True, "pm": pm}))
    out = {}
    for name, opt in cases:
        c = dict(cat)
        if opt.get("aurora"): c["gear_aurorawheels"] = aurora(opt["pm"])
        for beh in ("efficient", "casual"):
            ps = [run(c, pol, 3000 + i, beh, opt) for i in range(n)]
            w1 = statistics.median(p.arrive.get("Portal", p.t) / 60 for p in ps)
            arr = {s: round(statistics.median(p.arrive.get(s, p.t) / 60 for p in ps), 1) for s in ("Desert", "Cursed", "Crystal", "Retro")}
            # when do free players' gears overtake Aurora? (first time the equipped gear is not Aurora)
            out[name + ":" + beh] = {"W1": round(w1), "arrive": arr}
            print("%-14s %-9s W1 %4d min  arrive %s" % (name, beh, round(w1), arr)); sys.stdout.flush()
    json.dump(out, open(os.path.join(HERE, "..", "results", "paid_eval.json"), "w"), indent=1)
