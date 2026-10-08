# tune_gates.py - adjusts stage gate costs so the median efficient (value-buyer) player reaches each stage near a target minute.
# new cost = cost x exp(damp x growth x (target - actual)), growth = measured log income growth per minute around that stage.
import json, math, os, sys, statistics, copy
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import exp, gamedata as G, report as R, catalog2 as C2

TARGET = {"Desert": 4.5, "Cursed": 12.5, "Crystal": 30, "Retro": 58, "Jungle": 90, "AbsoluteZero": 128, "Portal": 195,
          "Candy": 235, "Atlantis": 280, "Toybox": 325, "Clockwork": 370, "Cloud": 418, "Cosmic": 470}
TUNED = ["Retro", "Jungle", "AbsoluteZero", "Portal", "Candy", "Atlantis", "Toybox", "Clockwork", "Cloud", "Cosmic"]
if __name__ == "__main__" and "--all" in sys.argv:   # RESCALE 2026-10-06: the compressed economy re-tunes every gate after Desert
    TUNED = ["Cursed", "Crystal"] + TUNED
    sys.argv.remove("--all")

def measure(v, n):
    cat, pol = exp.setup(v)
    ps = R.run_set(cat, "efficient", n, pol, smart=True, until="Cosmic", hours=24)
    arr = {s: statistics.median([p.arrive[s] / 60 for p in ps if s in p.arrive] or [1e9]) for s in TARGET}
    inc = {}
    for s in TARGET:
        key = "Sakura" if s == "Portal" else s
        vals = [p.snap[key]["arrive"]["income"] for p in ps if key in p.snap and "arrive" in p.snap[key]]
        inc[s] = statistics.median(vals) if vals else None
    return arr, inc, ps

def tune(v, iters=6, n=12, damp=0.4):
    v = copy.deepcopy(v)
    costs = dict(v.get("StageCost") or {})
    for s in TARGET:
        if s not in costs: costs[s] = G.LIVE_COST[s] * json.load(open(os.path.join(HERE, "final_balance.json")))["StageCost"].get(s, G.LIVE_COST[s]) / G.LIVE_COST[s]
    for it in range(iters):
        v["StageCost"] = costs
        arr, inc, ps = measure(v, n)
        order = list(TARGET)
        line = []
        for i, s in enumerate(order):
            if s not in TUNED: continue
            prev = order[i - 1]
            if inc.get(s) and inc.get(prev) and arr[s] > arr[prev]:
                g = math.log(max(inc[s] / inc[prev], 1.0001)) / (arr[s] - arr[prev])
            else:
                g = 0.05
            if arr[s] > 1e8:   # not reached: this gate (or an earlier one) is far too expensive
                costs[s] *= 0.4; line.append("%s ---/%.0f" % (s[:5], TARGET[s])); continue
            err = (TARGET[s] - TARGET[prev]) - (arr[s] - arr[prev])   # per-stage duration error (decoupled from earlier stages)
            step = max(-0.8, min(0.8, damp * g * err))
            costs[s] = costs[s] * math.exp(step)
            line.append("%s %.0f/%.0f" % (s[:5], arr[s], TARGET[s]))
        print("iter", it, " ".join(line)); sys.stdout.flush()
    v["StageCost"] = {s: float("%.2g" % c) for s, c in costs.items()}
    return v

if __name__ == "__main__":
    v = json.load(open(sys.argv[1]))
    out = tune(v, iters=int(sys.argv[3]) if len(sys.argv) > 3 else 6)
    json.dump(out, open(sys.argv[2], "w"), indent=1)
    print(json.dumps(out["StageCost"]))
