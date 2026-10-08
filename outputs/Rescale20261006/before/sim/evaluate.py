# evaluate.py - reproducible progression report for the FINAL balance (final_balance.json), fixed seeds.
# Behaviours: efficient, casual, noRewards (ignores daily/quests/codes), unlucky / lucky (every random roll for offers and
# hatches is the worse / better of two draws), rebirth (efficient player who already finished World 1 once: keeps parts,
# pets, upgrades, has 8 rebirths, replays World 1). Results are model estimates, NOT measured human playthroughs.
import json, os, sys, statistics, random
HERE = os.path.dirname(os.path.abspath(__file__))
import gamedata as G, model as M, catalog as CAT, sim

FINAL = json.load(open(os.path.join(HERE, "final_balance.json")))
def apply_final():
    G.COST_MULT.clear()
    for s, c in FINAL["StageCost"].items(): G.COST_MULT[s] = c / G.LIVE_COST[s]
    G.refresh_costs()
    M.HP_MULT.clear()
    for s, hp in FINAL["TileHP"].items(): M.HP_MULT[s] = hp / G.STAGE_FIELD[s][0]
    M.SPP_MULT.clear()
    CAT.P["EG"] = list(FINAL["EG"])

class Biased(random.Random):
    def __init__(self, seed, mode): super().__init__(seed); self.mode = mode
    def random(self):
        a, b = super().random(), super().random()
        return max(a, b) if self.mode > 0 else min(a, b)

STAGES = [s[0] for s in G.STAGES]

def run_one(cat, beh, seed, mode=0, carry=None, rebirths=0, until="Cosmic", hours=20):
    base = "efficient" if beh in ("unlucky", "lucky", "rebirth") else beh
    p = sim.Player(cat, base, seed, rebirths=rebirths, carry=carry)
    if mode: p.rng = Biased(seed, mode)
    trace = []
    nxt = 0
    while until not in p.stages and p.t < hours * 3600:
        p.step()
        if p.t >= nxt:
            nxt += 60; trace.append((p.t, p.rate()))
    p.trace = trace
    return p

def gaps(p, until):
    """minutes between 'meaningful' upgrades: any purchase after which income rose >= 15% within a minute"""
    tr = p.trace; ev = []
    last_r, last_t = None, 0
    for t, r in tr:
        if last_r is None or r >= last_r * 1.15: ev.append(t); last_r = r
        else: last_r = max(last_r * 0.999, min(last_r, r))
        if t > until: break
    g = [(b - a) / 60 for a, b in zip(ev, ev[1:])]
    return g

def pct(v, q):
    v = sorted(v); return v[min(len(v) - 1, int(q * len(v)))] if v else None

def report(beh, n=40, seed0=3000):
    apply_final(); cat = CAT.build()
    players = []
    for i in range(n):
        mode = -1 if beh == "unlucky" else (1 if beh == "lucky" else 0)
        if beh == "rebirth":
            first = run_one(cat, "efficient", seed0 + i, until="Portal")
            p = run_one(cat, "rebirth", seed0 + 500 + i, carry=first, rebirths=8, until="Portal")
        else:
            p = run_one(cat, beh, seed0 + i, mode=mode, until="Portal" if beh in ("casual", "noRewards") else "Cosmic")
        players.append(p)
    out = {"behaviour": beh, "seeds": n, "stages": {}}
    for s in STAGES:
        ts = [p.arrive[s] / 60 for p in players if s in p.arrive]
        if len(ts) < n / 2: continue
        rates = []
        for p in players:
            if s in p.arrive:
                t0 = p.arrive[s]; r = [r for t, r in p.trace if t >= t0]
                if r: rates.append(r[0])
        out["stages"][s] = {"p10": round(pct(ts, .1), 1), "median": round(statistics.median(ts), 1), "p90": round(pct(ts, .9), 1),
                            "reached": len(ts), "incomeOnArrival": "%.3g" % statistics.median(rates) if rates else None}
    w1 = [p.arrive["Portal"] / 60 for p in players if "Portal" in p.arrive]
    out["world1_minutes"] = {"p10": round(pct(w1, .1)), "median": round(statistics.median(w1)), "p90": round(pct(w1, .9))} if w1 else None
    w2 = [(p.arrive["Cosmic"] - p.arrive["Portal"]) / 60 for p in players if "Cosmic" in p.arrive]
    out["world2_minutes"] = {"p10": round(pct(w2, .1)), "median": round(statistics.median(w2)), "p90": round(pct(w2, .9))} if w2 else None
    parts = [sum(1 for e in p.events if e[1] == "part" and (beh == "rebirth" or e[0] <= p.arrive.get("Portal", 1e9))) for p in players]
    out["partsBoughtWorld1"] = {"median": statistics.median(parts), "p10": pct(parts, .1), "p90": pct(parts, .9)}
    rolls = [p.rolls for p in players]
    out["rolls"] = {"median": statistics.median(rolls)}
    waits = [w for p in players for w in p.useful_waits]
    out["rollsBetweenUsefulOffers"] = {"median": statistics.median(waits), "p90": pct(waits, .9), "max": max(waits)} if waits else None
    # time between useful offers measured on actual play time (includes driving between garage visits)
    tw = []
    for p in players:
        ts = p.useful_t
        tw += [(b - a) / 60 for a, b in zip(ts, ts[1:])]
    out["minutesBetweenUsefulOffers"] = {"median": round(statistics.median(tw), 1), "p90": round(pct(tw, .9), 1)} if tw else None
    gp = [g for p in players for g in gaps(p, p.arrive.get("Portal", 1e9))]
    out["minutesBetweenMeaningfulUpgrades_W1"] = {"median": round(statistics.median(gp), 1), "p90": round(pct(gp, .9), 1), "max": round(max(gp), 1)} if gp else None
    first_part = [min([e[0] for e in p.events if e[1] == "part"] or [1e9]) / 60 for p in players]
    out["firstPartPurchaseMinute"] = {"median": round(statistics.median(first_part), 1), "p90": round(pct(first_part, .9), 1)}
    rsv = [sum(1 for e in p.events if e[1] == "reserve") for p in players]
    out["reservations"] = {"median": statistics.median(rsv)}
    return out

if __name__ == "__main__":
    behs = sys.argv[1:] or ["efficient", "casual", "noRewards", "unlucky", "lucky", "rebirth"]
    res = {}
    for b in behs:
        res[b] = report(b, n=40 if b != "rebirth" else 20)
        print(json.dumps(res[b])); sys.stdout.flush()
    json.dump(res, open(os.path.join(HERE, "evaluation_%s.json" % "_".join(behs)), "w"), indent=1)
