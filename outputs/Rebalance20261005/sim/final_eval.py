# final_eval.py - BEFORE vs AFTER evaluation across behaviours (fixed seeds). Model estimates, not human playtests.
# usage: python final_eval.py <variant.json> <outtag> [seedsW1] [seedsW2]
import copy, json, os, statistics, sys, time
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import exp, report as R, sim2, catalog2 as C2, gamedata as G

BASE_P = copy.deepcopy(C2.P)

def offer_stats(players, cat):
    logs = [e for p in players for e in p.offer_log]
    if not logs: return None
    n = len(logs)
    useful = sum(1 for e in logs if e[2]); aff = sum(1 for e in logs if e[2] and e[3]); dup = sum(1 for e in logs if e[4])
    by = {}
    for e in logs:
        s = cat[e[1]]["slot"]; by[s] = by.get(s, 0) + 1
    streaks = []
    for p in players:
        cur = best = 0
        for e in p.offer_log:
            cur = 0 if e[2] else cur + 1; best = max(best, cur)
        streaks.append(best)
    return {"rolls": n, "usefulShare": round(useful / n, 3), "affordableUsefulShare": round(aff / n, 3), "duplicateShare": round(dup / n, 3),
            "slotShare": {k: round(v / n, 3) for k, v in by.items()}, "longestDryStreak": {"median": statistics.median(streaks), "max": max(streaks)}}

def evaluate(v, n1=40, n2=20, pity=False):
    C2.P.clear(); C2.P.update(copy.deepcopy(BASE_P))
    cat, pol = exp.setup(v)
    out = {}
    plan = [("efficient", {}, True), ("casual", {}, True), ("noRewards", {}, True), ("jobs", {"accept": 1.0}, True),
            ("unlucky", {"mode": -1}, True), ("lucky", {"mode": 1}, True), ("boosted", {}, True),
            ("efficient", {}, False), ("casual", {}, False), ("noRewards", {}, False)]
    for beh, kw, smart in plan:
        name = ("" if smart else "legacy:") + beh
        b = beh if beh in ("efficient", "casual", "noRewards", "boosted") else "efficient"
        acc = kw.get("accept")
        ps = [sim2.run(cat, b, 3000 + i, policy=pol, smart=smart, mode=kw.get("mode", 0), accept=acc, pity=pity) for i in range(n1)]
        out[name] = {"summary": R.summary(ps), "stages": R.stage_table(cat, ps, pol), "offers": offer_stats(ps, cat)}
        s = out[name]["summary"]
        print("%-18s W1 %s longestGap %s unavail %s between %s first %s jobs %s" % (name, s["world1_minutes"], s["longestGapPerPlayer"], s["longestUnavailable"],
              s["minutesBetweenMeaningful"], s["firstPartMinute"], s["jobs"])); sys.stdout.flush()
    # World 2 and rebirth (value buyer)
    ps = [sim2.run(cat, "efficient", 5000 + i, policy=pol, smart=True, until="Cosmic", hours=24, pity=pity) for i in range(n2)]
    out["world2"] = {"summary": R.summary(ps, until="Portal"), "stages": R.stage_table(cat, ps, pol), "offers": offer_stats(ps, cat)}
    print("world2", out["world2"]["summary"].get("world2_minutes"))
    firsts = ps
    rb = []
    for i, f in enumerate(firsts):
        p = sim2.Player2(cat, "efficient", 7000 + i, rebirths=8, carry=f, policy=pol)
        p.smart = True; p.PITY_AFFORD = pity
        while "Portal" not in p.stages and p.t < 6 * 3600: p.step()
        rb.append(p.arrive.get("Portal", p.t) / 60)
    out["rebirth"] = {"replayWorld1Minutes": {"median": round(statistics.median(rb), 1), "p90": round(R.pct(rb, .9), 1)}}
    print("rebirth", out["rebirth"])
    return out, cat

if __name__ == "__main__":
    v = json.load(open(sys.argv[1]))
    tag = sys.argv[2]
    n1 = int(sys.argv[3]) if len(sys.argv) > 3 else 40
    n2 = int(sys.argv[4]) if len(sys.argv) > 4 else 20
    t0 = time.time()
    res, cat = evaluate(v, n1, n2, pity=v.get("PityAfford", False))
    os.makedirs(os.path.join(HERE, "..", "results"), exist_ok=True)
    json.dump(res, open(os.path.join(HERE, "..", "results", "eval_%s.json" % tag), "w"), indent=1)
    print("done", round(time.time() - t0), "s")
