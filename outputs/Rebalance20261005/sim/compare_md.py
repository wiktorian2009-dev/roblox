# compare_md.py - BEFORE vs AFTER markdown (results/eval_before.json vs results/eval_final.json). Model estimates, not human playtests.
import json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from make_md import fmt
RES = os.path.join(HERE, "..", "results")
B = json.load(open(os.path.join(RES, os.environ.get("CMP_BEFORE", "eval_before.json"))))
A = json.load(open(os.path.join(RES, os.environ.get("CMP_AFTER", "eval_final.json"))))

def mm(d, k="median"): return "-" if not d else d.get(k, "-")

L = ["# Rebalance 2026-10-05: before vs after (simulation)", "",
     "Model estimates from outputs/Rebalance20261005/sim (40 seeds per World 1 behaviour, 20 for World 2), not human playtests.",
     "Value buyer = buys the best income gain per Snow and saves for clearly better items; legacy = the old egg-first spender.",
     "'Gap' = minutes between purchases that raise income by >= 10%; 'unavailable' = longest stretch without an obtainable,",
     "affordable (within 10 min of income) part or upgrade.", "",
     "## Summary per behaviour", "",
     "| Behaviour | W1 min before -> after (median, P90) | Longest gap per player med/P90 | Unavailable P90 | First part min | Parts bought W1 | Job pay vs collecting |",
     "|---|---|---|---|---|---|---|"]
for k in A:
    if k in ("world2", "rebirth") or k not in B: continue
    b, a = B[k]["summary"], A[k]["summary"]
    L.append("| %s | %s / %s -> **%s / %s** | %s / %s -> **%s / %s** | %s -> **%s** | %s -> **%s** | %s -> **%s** | %s -> **%s** |" % (
        k, b["world1_minutes"]["median"], b["world1_minutes"]["p90"], a["world1_minutes"]["median"], a["world1_minutes"]["p90"],
        b["longestGapPerPlayer"]["median"], b["longestGapPerPlayer"]["p90"], a["longestGapPerPlayer"]["median"], a["longestGapPerPlayer"]["p90"],
        b["longestUnavailable"]["p90"], a["longestUnavailable"]["p90"], b["firstPartMinute"]["median"], a["firstPartMinute"]["median"],
        b["partsBoughtW1"]["median"], a["partsBoughtW1"]["median"], b["jobs"]["payVsCollecting"], a["jobs"]["payVsCollecting"]))
bw, aw = B["world2"]["summary"].get("world2_minutes"), A["world2"]["summary"].get("world2_minutes")
L += ["", "World 2 (Sakura -> Cosmic, value buyer): %s min median (P90 %s) -> **%s min (P90 %s)**. Rebirth World 1 replay: %s -> **%s** min." % (
    mm(bw), mm(bw, "p90"), mm(aw), mm(aw, "p90"), B["rebirth"]["replayWorld1Minutes"]["median"], A["rebirth"]["replayWorld1Minutes"]["median"]), ""]

L += ["## Offers (value buyer, efficient)", "", "| | Before | After |", "|---|---|---|"]
ob, oa = B["efficient"].get("offers") or {}, A["efficient"]["offers"]
for key in ("usefulShare", "affordableUsefulShare", "duplicateShare"):
    L.append("| %s | %s | %s |" % (key, ob.get(key, "not logged"), oa[key]))
L.append("| longest dry streak (max) | %s | %s |" % ((ob.get("longestDryStreak") or {}).get("max", "not logged"), oa["longestDryStreak"]["max"]))
L.append("| slot share | %s | %s |" % (ob.get("slotShare", "not logged"), oa["slotShare"]))
L.append("")

for beh in ("efficient", "casual", "noRewards", "world2"):
    L += ["## Per stage: %s" % beh, "",
          "| Stage | Arrive med (before -> after) | Longest gap in stage med/P90 (before -> after) | Cheapest +10%% part at entry: before | after | Rolls to affordable useful offer (b -> a) | Job vs collecting (b -> a) |" ,
          "|---|---|---|---|---|---|---|"]
    for s, ra in A[beh]["stages"].items():
        rb = B[beh]["stages"].get(s)
        def part(r):
            cp = r and r["entry"]["cheapPart"]
            return ("%s %s (%s min)" % (cp["name"], fmt(cp["price"]), cp["minutes"])) if cp else "none"
        L.append("| %s | %s -> **%s** | %s / %s -> **%s / %s** | %s | %s | %s -> %s | %s -> %s |" % (
            s, rb and rb["arriveMin"]["median"], ra["arriveMin"]["median"],
            rb and rb["longestGapInStage"]["median"], rb and rb["longestGapInStage"]["p90"], ra["longestGapInStage"]["median"], ra["longestGapInStage"]["p90"],
            part(rb), part(ra), rb and rb["entry"]["rollsForAffordableUseful"], ra["entry"]["rollsForAffordableUseful"],
            rb and rb["entry"]["jobVsCollecting"], ra["entry"]["jobVsCollecting"]))
    L.append("")
open(os.environ.get("CMP_OUT", os.path.join(HERE, "..", "BEFORE_AFTER.md")), "w", encoding="utf-8").write("\n".join(L) + "\n")
print("\n".join(L)[:9000])

