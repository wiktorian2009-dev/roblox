# make_md.py - renders a report JSON (before / after) as markdown tables.
import json, os, sys
def fmt(x):
    if x is None: return "-"
    if isinstance(x, str): return x
    a = abs(x)
    for s, v in (("Qi", 1e18), ("Qa", 1e15), ("T", 1e12), ("B", 1e9), ("M", 1e6), ("K", 1e3)):
        if a >= v: return ("%.3g" % (x / v)) + s
    return "%.3g" % x

def table(rep, title):
    L = ["### " + title, "", "| Stage | Arrive (med/P90 min) | Leave | Entry build | Snow/min entry -> developed | Tile HP / tough | Limit | Cheapest +10% part (price, min) | Cheapest +10% upgrade (min) | Rolls to affordable useful offer | Gate (cost, min at entry -> developed) | Longest gap in stage (med/P90) | Job vs collecting |",
         "|---|---|---|---|---|---|---|---|---|---|---|---|---|"]
    for s, r in rep["stages"].items():
        e, d = r["entry"], r["developed"] or {}
        cp = e["cheapPart"]; cu = e["cheapUpgrade"]
        L.append("| %s | %s / %s | %s | %s | %s -> %s | %s / %.2f | %s | %s | %s | %s | %s: %s, %s -> %s | %s / %s | %s |" % (
            s, r["arriveMin"]["median"], r["arriveMin"]["p90"], r["leaveMin"]["median"] if r["leaveMin"] else "-", e["build"],
            fmt(e["income_per_min"]), fmt(d.get("income_per_min")), fmt(e["tileHP"]), e["tough"], e["limit"],
            ("%s (%s, %s)" % (cp["name"], fmt(cp["price"]), cp["minutes"])) if cp else "none",
            ("%s (%s)" % (cu["id"], cu["minutes"])) if cu else "none",
            e["rollsForAffordableUseful"] or "never", e["nextGate"], fmt(e["gateCost"]), e["gateMinutes"], d.get("gateMinutes"),
            r["longestGapInStage"]["median"], r["longestGapInStage"]["p90"], e["jobVsCollecting"]))
    s = rep["summary"]
    L += ["", "Summary: World 1 %s min (P10/med/P90 %s/%s/%s); meaningful purchases every %s min median, P90 %s; longest gap per player median %s, P90 %s, max %s min; first part at %s min; parts bought in W1 %s; jobs %s (%.0f%% of Snow in %.0f%% of time)." % (
        "", s["world1_minutes"]["p10"], s["world1_minutes"]["median"], s["world1_minutes"]["p90"], s["minutesBetweenMeaningful"]["median"], s["minutesBetweenMeaningful"]["p90"],
        s["longestGapPerPlayer"]["median"], s["longestGapPerPlayer"]["p90"], s["longestGapPerPlayer"]["max"], s["firstPartMinute"]["median"], s["partsBoughtW1"]["median"],
        s["jobs"]["median"], 100 * s["jobs"]["shareOfSnow"], 100 * s["jobs"]["shareOfTime"])]
    if s.get("world2_minutes"): L.append("World 2: %s min median (P10 %s, P90 %s)." % (s["world2_minutes"]["median"], s["world2_minutes"]["p10"], s["world2_minutes"]["p90"]))
    return "\n".join(L) + "\n\n"

if __name__ == "__main__":
    rep = json.load(open(sys.argv[1]))
    md = "".join(table(rep[k], k) for k in rep)
    open(sys.argv[2], "w", encoding="utf-8").write(md)
    print(md[:6000])
