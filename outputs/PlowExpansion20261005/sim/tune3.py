# tune3.py - balance tuner (final method).
#  * Part power follows a fixed, smooth curve (catalog.P["EG"]): every band's practical engine is clearly stronger than the last.
#  * Field TileHP per stage (HP_MULT) is tuned so a player working a stage is power-limited but healthy: the blade's
#    power-limited clearing rate is ~POWER_TARGET of the coverage/regrowth limit (parts and power upgrades keep mattering,
#    clearing never feels stuck).
#  * Stage gate costs (COST_MULT) are tuned so the efficient engaged player spends TARGET minutes in each stage. Egg prices,
#    part prices, World 2 upgrade prices and the World 1 upgrade price curve follow the stage costs.
import json, os, sys, statistics
HERE = os.path.dirname(os.path.abspath(__file__))
import gamedata as G, model as M, catalog as CAT, sim

TARGET = {"Starter": 2.5, "Desert": 10, "Cursed": 18, "Crystal": 26, "Retro": 34, "Jungle": 44, "AbsoluteZero": 65,
          "Sakura": 25, "Candy": 35, "Atlantis": 40, "Toybox": 45, "Clockwork": 50, "Cloud": 55}
NEXT = {"Starter": "Desert", "Desert": "Cursed", "Cursed": "Crystal", "Crystal": "Retro", "Retro": "Jungle", "Jungle": "AbsoluteZero",
        "AbsoluteZero": "Portal", "Sakura": "Candy", "Candy": "Atlantis", "Atlantis": "Toybox", "Toybox": "Clockwork",
        "Clockwork": "Cloud", "Cloud": "Cosmic"}
POWER_TARGET = 0.4
EG = [3.0, 2.8, 2.6, 2.5, 2.4, 2.3, 1.9, 1.8, 1.75, 1.7, 1.7, 1.65, 1.6]
PATH = os.path.join(HERE, "tuned3.json")

def apply(t):
    CAT.P["EG"] = list(t["EG"])
    G.COST_MULT.clear(); G.COST_MULT.update(t["COST"]); G.refresh_costs()
    M.HP_MULT.clear(); M.HP_MULT.update(t["HP"]); M.SPP_MULT.clear()

def load():
    return json.load(open(PATH)) if os.path.exists(PATH) else None

def measure(seeds, beh="efficient", hours=18):
    cat = CAT.build()
    dur = {s: [] for s in TARGET}; ratio = {s: [] for s in TARGET}; tot1 = []; tot2 = []
    for sd in seeds:
        p = sim.Player(cat, beh, sd)
        acc = {}
        while "Cosmic" not in p.stages and p.t < hours * 3600:
            p.step(); p.rate()
            s = p.cur_stage
            if s in TARGET:
                u, mo = p.mods(); st = M.stats_for(cat, p.build, mo)
                pw, cv, rg, spp = M.field_rates(st, s)
                a = acc.setdefault(s, [0.0, 0]); a[0] += min(3.0, pw / min(cv, rg)); a[1] += 1
        for s, (sm, n) in acc.items(): ratio[s].append(sm / n)
        for s in TARGET:
            n = NEXT[s]
            if s in p.arrive and n in p.arrive: dur[s].append((p.arrive[n] - p.arrive[s]) / 60)
        if "Portal" in p.arrive: tot1.append(p.arrive["Portal"] / 60)
        if "Cosmic" in p.arrive and "Portal" in p.arrive: tot2.append((p.arrive["Cosmic"] - p.arrive["Portal"]) / 60)
    med = lambda v: statistics.median(v) if v else None
    return {s: med(v) for s, v in dur.items()}, {s: med(v) for s, v in ratio.items()}, med(tot1), med(tot2)

def fmt(d): return {s: (None if v is None else round(v, 2)) for s, v in d.items()}

if __name__ == "__main__":
    iters = int(sys.argv[1]) if len(sys.argv) > 1 else 15
    t = load() or {"EG": EG, "COST": {}, "HP": {}}
    for it in range(iters):
        apply(t)
        dur, ratio, w1, w2 = measure(range(2000, 2008))
        print("iter", it, "W1", w1 and round(w1), "W2", w2 and round(w2), fmt(dur)); print("   ratio", fmt(ratio)); sys.stdout.flush()
        damp = 0.55 if it < 6 else 0.35
        for s in TARGET:
            if ratio.get(s):
                t["HP"][s] = max(0.2, min(60.0, t["HP"].get(s, 1.0) * (ratio[s] / POWER_TARGET) ** damp))
        t["HP"]["Cosmic"] = t["HP"].get("Cloud", 1.0)
        for s, tg in TARGET.items():
            n = NEXT[s]
            if dur[s] is not None:
                t["COST"][n] = max(0.2, min(1e5, t["COST"].get(n, 1.0) * (tg / max(dur[s], 0.05)) ** damp))
        json.dump(t, open(PATH, "w"), indent=1)
    apply(t)
    dur, ratio, w1, w2 = measure(range(2000, 2012))
    print("final W1", w1, "W2", w2, fmt(dur)); print("ratio", fmt(ratio)); print(json.dumps(t))
