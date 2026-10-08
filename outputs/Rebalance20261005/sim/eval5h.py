# eval5h.py (2026-10-06, Claude) - whole-game pacing after rebirths were removed: every profile plays from a new profile until it has
# reached Cosmic (end of World 2) AND owns the four top parts (the band-14 premium blade / engine / gear / body). Uses levels.LPlayer
# (part levels + drift) and, when the variant has "Minis", the mini-plow auto collection (minis.py). Estimates, not playtests.
#   usage: python eval5h.py <variant.json> <tag> [seeds] [--lv key=value ...]
import json, math, os, statistics, sys, time
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import levels, sim, sim2, exp, report as R, gamedata as G

TOP = ("blade_galaxy", "engine_nebula", "gear_meteor", "body_starcruiser")
PLAN = [("efficient", {}, True), ("casual", {}, True), ("noRewards", {}, True), ("jobs", {"accept": 1.0}, True),
        ("unlucky", {"mode": -1}, True), ("lucky", {"mode": 1}, True), ("boosted", {}, True),
        ("efficient", {}, False), ("casual", {}, False), ("noRewards", {}, False)]

def pct(v, q): return R.pct(v, q)

def run_one(cat, beh, seed, pol, smart, mode=0, accept=None, pity=True, hours=14):
    from evaluate import Biased
    b = beh if beh in ("efficient", "casual", "noRewards", "boosted") else "efficient"
    p = sim2.Player2(cat, b, seed, policy=pol, accept=accept, beh_name=beh)
    p.smart = smart; p.PITY_AFFORD = pity
    if mode: p.rng = Biased(seed, mode)
    p.trace, nxt, p.top_t = [], 0, None
    collector = False
    while p.t < hours * 3600:
        p.step()
        if not collector and "Cosmic" in p.stages:
            # completionist: once in Cosmic, the four top parts are wanted even when they add little income (keeps rolling for them,
            # buys them when affordable; the build still equips whatever earns most)
            collector = True
            real = p.gain_of
            # 1.3 = "exciting": an unaffordable top part goes on the reserve shelf, and the player saves for it instead of buying levels
            p.gain_of = lambda pid, real=real, p=p: max(real(pid), 1.3) if pid in TOP and pid not in p.owned else real(pid)
            sb = p.smart_buy
            p.smart_buy = lambda sb=sb, p=p: 0 if (p.reserved and p.reserved[0] in TOP and p.snow < p.reserved[1]) else sb()
        if collector and p.reserved and p.reserved[0] in TOP and p.reserved[0] not in p.owned and p.snow >= p.reserved[1]:
            p.spend_time(20); p.buy(p.reserved[0], p.reserved[1]); p.reserved = None   # walks to the garage and buys the saved part
        if p.t >= nxt: nxt += 60; p.trace.append((p.t, p.rate()))
        if p.top_t is None and all(k in p.owned for k in TOP): p.top_t = p.t
        if "Cosmic" in p.stages and p.top_t is not None: break
    p.done_t = p.t
    return p

def gaps_of(p, t0, t1):
    ts = [t for t, k, x, g in p.improvements if g >= R.MEANINGFUL and t0 <= t <= t1]
    return [(b - a) / 60 for a, b in zip([t0] + ts, ts + [t1])]

def summarize(ps):
    m = lambda v: {"median": round(statistics.median(v), 1), "p90": round(pct(v, .9), 1)} if v else None
    w1 = [p.arrive["Portal"] / 60 for p in ps if "Portal" in p.arrive]
    cos = [p.arrive["Cosmic"] / 60 for p in ps if "Cosmic" in p.arrive]
    top = [p.top_t / 60 for p in ps if p.top_t is not None]
    done = [p.done_t / 60 for p in ps]
    first = [min([t for t, k, x, g in p.improvements if k == "part"] or [1e9]) / 60 for p in ps]
    early, late, longest, unav = [], [], [], []
    for p in ps:
        g_early = gaps_of(p, 0, min(p.done_t, 3600)); early += g_early
        late += gaps_of(p, max(0, p.done_t - 3600), p.done_t)
        longest.append(max(gaps_of(p, 0, p.arrive.get("Cosmic", p.done_t)) or [0]))   # to the last stage (the top-part hunt after it is collecting, not income)
        gs = [(b - a) / 60 for a, b in getattr(p, "av_gaps", [])]
        unav.append(max(gs) if gs else 0.0)
    return {"world1": m(w1), "cosmic": m(cos), "top4": m(top), "done": m(done), "finished": sum(1 for p in ps if "Cosmic" in p.stages and p.top_t is not None),
            "n": len(ps), "firstPart": m(first), "gapEarly": m(early), "gapLate": m(late), "longestGap": m(longest), "longestUnavailable": m(unav),
            "jobs": round(statistics.median(p.job_snow / max(p.earned, 1) for p in ps), 3),
            "miniShare": round(statistics.median(getattr(p, "mini_snow", 0) / max(p.earned, 1) for p in ps), 3)}

REF_GATES = None
REF_SNOW_GOALS = (40000.0, 30000000.0, 2000000000.0)   # live Snow1-3 goals on the rescale_w1x108 gates (before the 5-hour pass)
def snow_goal_map(new_gates):
    """review fix 2026-10-06: live Snow1-3 goals for a variant = the reference goals log-mapped between matching gates (as emit5h writes)"""
    global REF_GATES
    if REF_GATES is None: REF_GATES = json.load(open(os.path.join(HERE, "rescale_w1x108.json")))["StageCost"]
    order = ["Desert", "Cursed", "Crystal", "Retro", "Jungle", "AbsoluteZero", "Portal", "Candy", "Atlantis", "Toybox", "Clockwork", "Cloud", "Cosmic"]
    pts = [(REF_GATES[s], new_gates[s]) for s in order]
    def m(x):
        if x <= pts[0][0]: return x
        for (a0, b0), (a1, b1) in zip(pts, pts[1:]):
            if x <= a1: return b0 * (b1 / b0) ** (math.log(x / a0) / math.log(a1 / a0))
        return pts[-1][1] * x / pts[-1][0]
    return m

def nice1(x):
    if x < 100: return int(round(x))
    e = 10 ** math.floor(math.log10(x)); return int(round(x / e)) * e

def set_achievements(v):
    m = snow_goal_map(v["StageCost"])
    goals = [nice1(m(g)) for g in REF_SNOW_GOALS]
    out, k = [], 0
    for a in G.ACHIEVEMENTS:
        if a[0] == "Rebirths": continue   # rebirths removed 2026-10-06
        if a[0] == "SnowEarned": a = (a[0], goals[k], a[2], a[3]); k += 1
        out.append(a)
    G.ACHIEVEMENTS[:] = out
    return goals

def evaluate(v, n=24):
    cat, pol = exp.setup(v)
    print("Snow achievement goals", set_achievements(v))
    if v.get("Minis"):
        import minis; minis.install(v["Minis"])
    out = {}
    for beh, kw, smart in PLAN:
        name = ("" if smart else "legacy:") + beh
        ps = [run_one(cat, beh, 3000 + i, pol, smart, kw.get("mode", 0), kw.get("accept"), v.get("PityAfford", True)) for i in range(n)]
        s = summarize(ps); out[name] = s
        f = lambda d: d and "%s/%s" % (d["median"], d["p90"])
        print("%-18s W1 %-11s Cosmic %-11s top4 %-11s DONE %-11s (%d/%d) first %s gapEarly %s gapLate %s longest %s unavail %s jobs %s minis %s" % (
            name, f(s["world1"]), f(s["cosmic"]), f(s["top4"]), f(s["done"]), s["finished"], s["n"], f(s["firstPart"]), f(s["gapEarly"]), f(s["gapLate"]),
            f(s["longestGap"]), f(s["longestUnavailable"]), s["jobs"], s["miniShare"])); sys.stdout.flush()
    return out

if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--lv")]
    for a in sys.argv[1:]:
        if a.startswith("--lv"):
            k, val = a[4:].lstrip("=").split("=")
            levels.LV[k] = type(levels.LV[k])(float(val)) if not isinstance(levels.LV[k], int) else int(float(val))
    sim2.Player2 = levels.LPlayer
    v = json.load(open(args[0])); tag = args[1]; n = int(args[2]) if len(args) > 2 else 24
    if "LV" in v: levels.LV.update(v["LV"])
    t0 = time.time()
    res = evaluate(v, n)
    res["levels"] = dict(levels.LV)
    os.makedirs(os.path.join(HERE, "..", "results"), exist_ok=True)
    json.dump(res, open(os.path.join(HERE, "..", "results", "eval5h_%s.json" % tag), "w"), indent=1)
    print("done", round(time.time() - t0), "s")
