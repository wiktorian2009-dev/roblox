# check_live.py - confirms the simulator's catalog equals the LIVE PlowConfig parts (dumped from Studio to before/live_parts.json).
import json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import evaluate as E, catalog as CAT

E.apply_final()
cat = CAT.build()
live = json.load(open(os.path.join(HERE, "..", "before", "live_parts.json")))["parts"]
bad = 0
for pid, lp in live.items():
    p = cat.get(pid)
    if not p: print("MISSING in sim", pid); bad += 1; continue
    if abs(p["price"] - lp["price"]) > 1e-6 * max(1, lp["price"]): print("PRICE", pid, p["price"], lp["price"]); bad += 1
    for k, v in lp["stats"].items():
        sv = p["stats"].get(k)
        if sv is None or abs(float(sv) - float(v)) > 0.011 * max(1, abs(float(v))): print("STAT", pid, k, sv, v); bad += 1
print("parts", len(live), "sim", len(cat), "mismatches", bad)
