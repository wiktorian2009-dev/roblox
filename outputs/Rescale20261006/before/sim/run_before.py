# run_before.py - BEFORE report for the live economy (90 parts, live stage/upgrade/egg prices, jobs = 30 s bonus).
import json, os, sys, time
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import gamedata as G, model as M, evaluate as E, catalog as CAT, jobs as J, report as R

def apply_live():
    E.apply_final()
    live = json.load(open(os.path.join(HERE, "..", "before", "live_upgrades_eggs.json")))
    for u in G.UPGRADES: u["C"] = float(live["upgrades"][u["Id"]])
    eggs = live["eggs"]
    G.egg_cost = lambda e: float(eggs[e[0]])

if __name__ == "__main__":
    apply_live()
    cat = CAT.build()
    pol = J.Policy("live", bonus_seconds=30)
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 30
    out = {}
    t0 = time.time()
    for beh in ("efficient", "casual", "noRewards"):
        ps = R.run_set(cat, beh, n, pol, until="Portal")
        out[beh] = {"summary": R.summary(ps), "stages": R.stage_table(cat, ps, pol)}
        print(beh, json.dumps(out[beh]["summary"]), round(time.time() - t0)); sys.stdout.flush()
    ps = R.run_set(cat, "efficient", max(10, n // 2), pol, until="Cosmic", hours=20)
    out["efficient_w2"] = {"summary": R.summary(ps), "stages": R.stage_table(cat, ps, pol)}
    print("w2", json.dumps(out["efficient_w2"]["summary"]))
    json.dump(out, open(os.path.join(HERE, "..", "before", "before_report.json"), "w"), indent=1)
