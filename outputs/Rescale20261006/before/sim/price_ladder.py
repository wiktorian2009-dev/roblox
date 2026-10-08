# price_ladder.py - RESCALE 2026-10-06: part price ladders per slot (old vs new variant) and the biggest step between neighbours.
# usage: python price_ladder.py old.json new.json [out.md]
import json, os, sys, copy
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import exp, catalog2 as C2

def ladder(vpath):
    base = copy.deepcopy(C2.P)
    v = json.load(open(vpath))
    cat, _ = exp.setup(v)
    C2.P.clear(); C2.P.update(base)
    out = {}
    for slot in ("Blade", "Engine", "Gear", "Body"):
        ps = sorted((p for p in cat.values() if p["slot"] == slot and p["role"] not in ("S", "P") and p["price"] > 0), key=lambda p: p["price"])
        out[slot] = [(p["name"], p["band"], p["role"], p["price"]) for p in ps]
    return out, v

def fmt(x):
    for s, val in (("Qi", 1e18), ("Qa", 1e15), ("T", 1e12), ("B", 1e9), ("M", 1e6), ("K", 1e3)):
        if x >= val: return ("%g" % float("%.3g" % (x / val))) + s
    return "%d" % x

if __name__ == "__main__":
    old, vo = ladder(sys.argv[1]); new, vn = ladder(sys.argv[2])
    lines = ["# Part price ladders: before -> after (rescale 2026-10-06)", "",
             "| Slot | Parts | Cheapest before -> after | Priciest before -> after | Biggest neighbour step before -> after | Median step before -> after |",
             "|---|---|---|---|---|---|"]
    for slot in old:
        def steps(l): return [b[3] / a[3] for a, b in zip(l, l[1:])]
        so, sn = steps(old[slot]), steps(new[slot])
        med = lambda s: sorted(s)[len(s) // 2]
        lines.append("| %s | %d | %s -> %s | %s -> %s | x%.0f -> **x%.1f** | x%.2f -> **x%.2f** |" % (slot, len(old[slot]), fmt(old[slot][0][3]), fmt(new[slot][0][3]),
                     fmt(old[slot][-1][3]), fmt(new[slot][-1][3]), max(so), max(sn), med(so), med(sn)))
    lines += ["", "| Stage gate | Before | After |", "|---|---|---|"]
    for s, c in vo["StageCost"].items(): lines.append("| %s | %s | **%s** |" % (s, fmt(c), fmt(vn["StageCost"][s])))
    for slot in new:
        lines += ["", "## %s ladder (after)" % slot, "", "| # | Part | World | Role | Price | Step |", "|---|---|---|---|---|---|"]
        prev = None
        for i, (n, b, r, pr) in enumerate(new[slot]):
            lines.append("| %d | %s | %d | %s | %s | %s |" % (i + 1, n, b, r, fmt(pr), ("x%.2f" % (pr / prev)) if prev else ""))
            prev = pr
    txt = "\n".join(lines)
    if len(sys.argv) > 3: open(sys.argv[3], "w", encoding="utf-8").write(txt)
    print("\n".join(lines[:12 + len(vo["StageCost"])]))
