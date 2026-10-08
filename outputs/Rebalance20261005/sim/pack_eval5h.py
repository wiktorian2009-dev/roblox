# pack_eval5h.py (2026-10-06, Claude) - Starter Pack effect on the 5-hour pacing (eval5h run_one, tuned5h_f, same seeds).
# Cases: free, old pack (Desert set + 3,000 Snow), new pack (Desert set + all 10 Cursed/Haunted parts, no Snow).
# Pack parts are owned at level 1 from t=0, equipped only when they raise income (value buyer). Estimates, not playtests.
#   usage: python pack_eval5h.py [seeds]
import json, os, statistics, sys, time
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import levels, sim2, exp, eval5h as E

DESERT = ["blade_dune", "engine_sandrunner", "gear_balloon", "body_dunerunner"]
HAUNTED = ["blade_grave", "blade_bonechill", "blade_hex", "engine_lantern", "engine_cauldron", "engine_phantom",
           "gear_bonewheels", "gear_graverollers", "gear_haunted", "body_gravehauler"]
CASES = [("free", [], 0), ("oldPack", DESERT, 3000), ("newPack", DESERT + HAUNTED, 0)]

def give(p, cat, parts, snow):
    for pid in parts:
        assert pid in cat, pid
        p.owned[pid] = 1
    p.snow += snow
    for _ in range(2):   # equip the best combination slot by slot
        for pid in parts:
            s = cat[pid]["slot"]; b = dict(p.build); b[s] = pid
            if p.income(build=b)[0] > p.income()[0]: p.build[s] = pid
    p.dirty = True

if __name__ == "__main__":
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 16
    sim2.Player2 = levels.LPlayer
    v = json.load(open(os.path.join(HERE, "tuned5h_f.json")))
    if "LV" in v: levels.LV.update(v["LV"])
    cat, pol = exp.setup(v)
    E.set_achievements(v)
    if v.get("Minis"):
        import minis; minis.install(v["Minis"])
    orig = sim2.Player2.__init__
    out = {}
    t0 = time.time()
    for name, parts, snow in CASES:
        def init(self, *a, parts=parts, snow=snow, **k):
            orig(self, *a, **k); give(self, cat, parts, snow)
        sim2.Player2.__init__ = init
        for beh in ("casual", "efficient"):
            ps = [E.run_one(cat, beh, 3000 + i, pol, True, pity=v.get("PityAfford", True)) for i in range(n)]
            s = E.summarize(ps)
            arr = {st: round(statistics.median(p.arrive.get(st, p.t) / 60 for p in ps), 1) for st in ("Desert", "Cursed", "Crystal", "Retro", "Portal")}
            s["arrive"] = arr; out[name + ":" + beh] = s
            f = lambda d: d and "%s/%s" % (d["median"], d["p90"])
            print("%-8s %-9s W1 %-11s Cosmic %-11s DONE %-11s (%d/%d) arrive %s" % (name, beh, f(s["world1"]), f(s["cosmic"]), f(s["done"]), s["finished"], s["n"], arr))
            sys.stdout.flush()
    sim2.Player2.__init__ = orig
    json.dump(out, open(os.path.join(HERE, "..", "results", "pack_eval5h.json"), "w"), indent=1)
    print("done", round(time.time() - t0), "s")
