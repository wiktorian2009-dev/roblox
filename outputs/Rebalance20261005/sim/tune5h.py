# tune5h.py (2026-10-06, Claude) - "the whole game in ~5 hours free-to-play" (wiktor). Re-tunes every stage gate after Desert so the
# median CASUAL value buyer (no paid boosts, mini plows included, part levels, rebirths removed) arrives near TARGET minutes.
# Parts, World 1 upgrades, World 2 upgrades, eggs, part levels and mini-plow levels all follow the gates (exp.setup / catalog2 / minis).
#   usage: python tune5h.py <in.json> <out.json> [iters] [seeds]
import copy, json, math, os, statistics, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import levels, sim2, exp, gamedata as G, report as R, eval5h as E

# casual arrival targets (minutes): the current casual curve squeezed so Cosmic lands at ~4.5 h, leaving ~30 min for the top parts
TARGET = {"Desert": 3.0, "Cursed": 9.0, "Crystal": 19.0, "Retro": 33.0, "Jungle": 50.0, "AbsoluteZero": 70.0, "Portal": 100.0,
          "Candy": 125.0, "Atlantis": 150.0, "Toybox": 176.0, "Clockwork": 205.0, "Cloud": 236.0, "Cosmic": 270.0}
TUNED = list(TARGET)[1:]   # Desert keeps its gate (the first minutes are already right)

def measure(v, n, beh="casual"):
    cat, pol = exp.setup(v)
    E.set_achievements(v)   # live Snow1-3 goals follow the gates (emit5h writes the same numbers)
    import minis; minis.install(v.get("Minis") if isinstance(v.get("Minis"), dict) else None)
    ps = [E.run_one(cat, beh, 3000 + i, pol, True, pity=v.get("PityAfford", True), hours=12) for i in range(n)]
    arr = {s: statistics.median([p.arrive[s] / 60 for p in ps if s in p.arrive] or [1e9]) for s in TARGET}
    inc = {}
    for s in TARGET:
        key = "Sakura" if s == "Portal" else s
        vals = [p.snap[key]["arrive"]["income"] for p in ps if key in p.snap and "arrive" in p.snap[key]]
        inc[s] = statistics.median(vals) if vals else None
    done = statistics.median([p.done_t / 60 for p in ps])
    return arr, inc, done

def tune(v, iters=6, n=8, damp=0.5):
    v = copy.deepcopy(v); costs = dict(v["StageCost"])
    order = list(TARGET)
    for it in range(iters):
        v["StageCost"] = costs
        arr, inc, done = measure(v, n)
        line = []
        for i, s in enumerate(order):
            if s not in TUNED: continue
            prev = order[i - 1]
            g = math.log(max(inc[s] / inc[prev], 1.0001)) / (arr[s] - arr[prev]) if inc.get(s) and inc.get(prev) and arr[s] > arr[prev] else 0.05
            if arr[s] > 1e8:
                costs[s] *= 0.4; line.append("%s ---/%.0f" % (s[:5], TARGET[s])); continue
            err = (TARGET[s] - TARGET[prev]) - (arr[s] - arr[prev])
            costs[s] *= math.exp(max(-0.8, min(0.8, damp * g * err)))
            line.append("%s %.0f/%.0f" % (s[:5], arr[s], TARGET[s]))
        print("iter", it, "done %.0f |" % done, " ".join(line)); sys.stdout.flush()
    v["StageCost"] = {s: float("%.2g" % c) for s, c in costs.items()}
    return v

if __name__ == "__main__":
    sim2.Player2 = levels.LPlayer; levels.LV["Drift"] = 1.5
    v = json.load(open(sys.argv[1]))
    out = tune(v, iters=int(sys.argv[3]) if len(sys.argv) > 3 else 6, n=int(sys.argv[4]) if len(sys.argv) > 4 else 8)
    json.dump(out, open(sys.argv[2], "w"), indent=1)
    print(json.dumps(out["StageCost"]))
