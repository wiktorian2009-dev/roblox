# exp.py - runs one balance variant (catalog2 tunables + economy levers + job policy) and prints compact cadence metrics.
import json, os, sys, statistics
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import gamedata as G, model as M, evaluate as E, catalog2 as C2, jobs as J, report as R, run_before as RB, sim

def setup(v):
    """v: dict of levers. stage costs / HP via final_balance + overrides; catalog2.P overrides; offer-pool roles."""
    RB.apply_live()   # exact live prices (upgrades, eggs) + final_balance stage costs / HP
    live = json.load(open(os.path.join(HERE, "..", "before", "live_upgrades_eggs.json")))
    if v.get("StageCost"):
        # prices that follow stages in the game: W1 upgrades read StageConfig through UpgradeConfig.CostOf (PriceEnd curve),
        # W2 upgrades / eggs were set per stage -> scale the exact live price by the sim formula's new/old ratio
        old_up = {}
        for u in G.UPGRADES: old_up[u["Id"]] = G.upgrade_cost(u)
        old_cost = {s: G.stage_cost(s) for s in G.LIVE_COST}
        for s, c in v["StageCost"].items(): G.COST_MULT[s] = c / G.LIVE_COST[s]
        for u in G.UPGRADES: u["C"] = float(live["upgrades"][u["Id"]]) * G.upgrade_cost(u) / old_up[u["Id"]]
        eggs = dict(live["eggs"])
        for e in G.EGGS:
            st = "Portal" if e[2] == "Sakura" else e[2]
            if old_cost[st] > 0: eggs[e[0]] = float(live["eggs"][e[0]]) * G.stage_cost(st) / old_cost[st]
        G.egg_cost = lambda e, eggs=eggs: eggs[e[0]]
    for s, hp in v.get("TileHP", {}).items(): M.HP_MULT[s] = hp / G.STAGE_FIELD[s][0]
    for k, val in v.get("Cat", {}).items(): C2.P[k] = val
    M.ROLE_W["M"] = v.get("RoleM", 0.7)
    M.PRACTICAL_ROLES = set(v.get("Practical", ["A", "M"]))
    cat = C2.build() if v.get("Catalog", 135) == 135 else __import__("catalog").build()
    if v.get("NoBody"): cat = {k: p for k, p in cat.items() if p["slot"] != "Body"}   # task 7: the 135-part game without bodies
    import compress   # RESCALE 2026-10-06: growth multipliers ^c (no-op without "Compress"; always resets to the live values first)
    cat = compress.apply(cat, v.get("Compress"))
    if not v.get("Compress"): compress.restore_pets()
    M.SLOT_SHARE["Body"] = v.get("BodyShare", M.SLOT_SHARE["Body"])
    pol = J.Policy(**v.get("Jobs", {"mode": "live", "bonus_seconds": 30}))
    return cat, pol

def run(v, n=16, behs=("efficient", "casual", "noRewards"), smart_modes=(True, False), w2=False):
    cat, pol = setup(v)
    res = {}
    for smart in smart_modes:
        for beh in behs:
            ps = R.run_set(cat, beh, n, pol, smart=smart, until="Cosmic" if w2 else "Portal", hours=20 if w2 else 14)
            s = R.summary(ps)
            st = R.stage_table(cat, ps, pol)
            key = ("smart" if smart else "legacy") + ":" + beh
            res[key] = {"W1": s["world1_minutes"], "W2": s.get("world2_minutes"), "gap": s["longestGapPerPlayer"], "between": s["minutesBetweenMeaningful"],
                        "first": s["firstPartMinute"]["median"], "unavail": s["longestUnavailable"], "parts": s["partsBoughtW1"]["median"], "job": s["jobs"].get("payVsCollecting"),
                        "jobShareTime": s["jobs"]["shareOfTime"],
                        "stages": {k: [r["arriveMin"]["median"], r["longestGapInStage"]["median"], r["longestGapInStage"]["p90"]] for k, r in st.items()}}
    return res, cat

def show(res):
    for k, r in res.items():
        print("%-18s W1 %s W2 %s gap(med/p90/max) %s/%s/%s unavail %s/%s/%s first %s parts %s job x%s (%.0f%% time)" % (k, r["W1"] and (r["W1"]["median"], r["W1"]["p90"]),
              r["W2"] and r["W2"]["median"], r["gap"]["median"], r["gap"]["p90"], r["gap"]["max"], r["unavail"]["median"], r["unavail"]["p90"], r["unavail"]["max"], r["first"], r["parts"], r["job"], 100 * r["jobShareTime"]))
        print("    " + "  ".join("%s:%s(%s/%s)" % (s[:5], a, g, g9) for s, (a, g, g9) in r["stages"].items()))

if __name__ == "__main__":
    v = json.load(open(sys.argv[1])) if len(sys.argv) > 1 else {}
    n = int(sys.argv[2]) if len(sys.argv) > 2 else 16
    w2 = len(sys.argv) > 3 and sys.argv[3] == "w2"
    res, cat = run(v, n, w2=w2)
    show(res)
