# tune.py - iterative balance tuner. Adjusts (1) engine power growth per band so that clearing is power-limited but healthy
# when a player arrives at a stage, and (2) SnowPerPhase per stage so the efficient player's time per stage matches the
# pacing targets below. Writes tuned.json, read by catalog.py/model.py via apply_tuned().
import json, math, os, sys, statistics
HERE = os.path.dirname(os.path.abspath(__file__))
import gamedata as G, model as M, catalog as CAT, sim

# efficient engaged player, minutes spent in each field stage before buying the next stage (World 1 = ~3.3 h, World 2 = ~4.2 h)
TARGET = {"Starter": 2.5, "Desert": 10, "Cursed": 18, "Crystal": 26, "Retro": 34, "Jungle": 44, "AbsoluteZero": 65,
          "Sakura": 25, "Candy": 35, "Atlantis": 40, "Toybox": 45, "Clockwork": 50, "Cloud": 55}
NEXT = {"Starter": "Desert", "Desert": "Cursed", "Cursed": "Crystal", "Crystal": "Retro", "Retro": "Jungle", "Jungle": "AbsoluteZero",
        "AbsoluteZero": "Portal", "Sakura": "Candy", "Candy": "Atlantis", "Atlantis": "Toybox", "Toybox": "Clockwork",
        "Clockwork": "Cloud", "Cloud": "Cosmic"}
POWER_TARGET = 0.35
MIN_STEP = 2.2   # each newer field pays at least 2.2x the Snow per layer of the previous one   # power-limited rate / coverage rate on arrival (0.32 = clearly power-limited, room to improve)

def load():
    p = os.path.join(HERE, "tuned.json")
    return json.load(open(p)) if os.path.exists(p) else None

def apply_tuned(t):
    if not t: return
    CAT.P["EG"] = t["EG"]
    M.SPP_MULT.clear(); M.SPP_MULT.update(t["SPP"])

def measure(seeds, beh="efficient"):
    cat = CAT.build()
    dur = {s: [] for s in TARGET}; ratio = {s: [] for s in TARGET}
    for sd in seeds:
        p = sim.Player(cat, beh, sd)
        acc = {}
        while "Cosmic" not in p.stages and p.t < 16 * 3600:
            p.step()
            p.rate()
            s = p.cur_stage
            if s in TARGET:
                u, mo = p.mods(); st = M.stats_for(cat, p.build, mo)
                pw, cv, rg, spp = M.field_rates(st, s)
                a = acc.setdefault(s, [0.0, 0])
                a[0] += pw / min(cv, rg); a[1] += 1
        for s, (sm, n) in acc.items(): ratio[s].append(sm / n)
        for s in TARGET:
            n = NEXT[s]
            if s in p.arrive and n in p.arrive: dur[s].append((p.arrive[n] - p.arrive[s]) / 60)
    return ({s: statistics.median(v) if v else None for s, v in dur.items()},
            {s: statistics.median(v) if v else None for s, v in ratio.items()})

if __name__ == "__main__":
    iters = int(sys.argv[1]) if len(sys.argv) > 1 else 12
    order0 = list(G.STAGE_FIELD)
    t = load() or {"EG": list(CAT.P["EG"]), "SPP": {s: 2.0 ** -max(0, i - 1) for i, s in enumerate(order0)}}
    for it in range(iters):
        apply_tuned(t)
        dur, ratio = measure(range(2000, 2006))
        tot1 = sum(dur[s] or 0 for s in ["Starter", "Desert", "Cursed", "Crystal", "Retro", "Jungle", "AbsoluteZero"])
        print("iter", it, "W1 %.0f min" % tot1, {s: (None if dur[s] is None else round(dur[s], 1)) for s in TARGET})
        print("   ratio", {s: (None if ratio[s] is None else round(ratio[s], 2)) for s in TARGET})
        # power growth: the growth INTO band k (EG[k-2]) controls the power/coverage ratio while clearing stage k
        order = list(G.STAGE_FIELD)
        for k in range(2, 15):
            s = order[k - 1]
            if s in ratio and ratio[s]:
                f = (POWER_TARGET / ratio[s]) ** 0.5
                t["EG"][k - 2] = max(1.15, min(6.0, t["EG"][k - 2] * f))
        for s in TARGET:
            if dur[s]:
                f = (dur[s] / TARGET[s]) ** 0.6
                t["SPP"][s] = max(1e-4, min(10, t["SPP"][s] * f))
        t["SPP"]["Cosmic"] = t["SPP"]["Cloud"]
        # a newer field must pay clearly more Snow per layer than the previous one, so a fitting build always moves on
        for i in range(1, len(order)):
            a, b = order[i - 1], order[i]
            ra = G.STAGE_FIELD[a][1] * t["SPP"][a]
            rb = G.STAGE_FIELD[b][1] * t["SPP"][b]
            if rb < MIN_STEP * ra: t["SPP"][b] = MIN_STEP * ra / G.STAGE_FIELD[b][1]
        json.dump(t, open(os.path.join(HERE, "tuned.json"), "w"), indent=1)
    apply_tuned(t)
    dur, ratio = measure(range(2000, 2006))
    print("final", {s: (None if dur[s] is None else round(dur[s], 1)) for s in TARGET})
    print("ratio", {s: (None if ratio[s] is None else round(ratio[s], 2)) for s in TARGET})
    print(json.dumps(t))
