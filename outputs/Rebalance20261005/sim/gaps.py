# gaps.py (2026-10-06, Claude) - World 1 time + longest wait between improvements, with and without part levels (same seeds).
#   python gaps.py <variant.json> [seeds] [--lv key=value ...]
import copy, json, statistics, sys
import levels as L, sim2, exp, catalog2 as C2

def pct(v, q): v = sorted(v); return v[min(len(v) - 1, int(q * len(v)))]
def longest_gap(p, thr, until="Portal"):
    end = p.arrive.get(until, p.t)
    ts = [t for t, k, x, g in p.improvements if g >= thr and t <= end]
    return max((b - a) / 60 for a, b in zip([0.0] + ts, ts + [end]))

def run(cls, cat, pol, beh, smart, n):
    out = []
    for i in range(n):
        sim2.Player2 = cls
        p = sim2.run(cat, beh, 3000 + i, policy=pol, smart=smart)
        out.append(p)
    return out

if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--lv")]
    for a in sys.argv[1:]:
        if a.startswith("--lv"):
            k, val = a[4:].lstrip("=").split("=")
            L.LV[k] = type(L.LV[k])(float(val)) if not isinstance(L.LV[k], int) else int(float(val))
    v = json.load(open(args[0])); n = int(args[1]) if len(args) > 1 else 16
    cat, pol = exp.setup(v)
    base_cls = L.Base
    for beh, smart in (("efficient", True), ("casual", True), ("casual", False)):
        row = {}
        for tag, cls in (("before", base_cls), ("levels", L.LPlayer)):
            ps = run(cls, cat, pol, beh, smart, n)
            w1 = [p.arrive.get("Portal", p.t) / 60 for p in ps]
            g10 = [longest_gap(p, 1.10) for p in ps]; g2 = [longest_gap(p, 1.02) for p in ps]
            lv = [getattr(p, "level_buys", 0) for p in ps]
            row[tag] = "W1 %3.0f min | longest wait +10%%: med %4.1f p90 %4.1f | any +2%%: med %4.1f p90 %4.1f | levels bought %.0f" % (
                statistics.median(w1), statistics.median(g10), pct(g10, .9), statistics.median(g2), pct(g2, .9), statistics.median(lv))
        name = ("" if smart else "legacy:") + beh
        print(name); print("  before:", row["before"]); print("  levels:", row["levels"]); sys.stdout.flush()
    sim2.Player2 = base_cls
