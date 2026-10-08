# emit5h.py (2026-10-06, Claude) - writes the "whole game in ~5 h free-to-play" economy (variant tuned5h_d.json) into game/src:
#   StageConfig gates, PlowConfig (parts via gen_lua2, mini-plow level prices, C.Offers.FinalBandPremium), PetConfig egg prices,
#   UpgradeConfig World 2 prices, ActivityConfig lifetime-Snow achievement goals. Pet boosts, fields, part levels' curve, jobs,
#   treasures and quests are unchanged (they are income-relative or already compressed). EconomyMigration is NOT touched.
# Prints a report and writes build/emit5h_report.json. Re-running is safe (every value is computed from the variant + reference data).
import json, math, os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
SRC = r"C:\Users\wikto\Desktop\Roblox Gra\game\src\ReplicatedStorage"
ORDER = ["Desert", "Cursed", "Crystal", "Retro", "Jungle", "AbsoluteZero", "Portal", "Candy", "Atlantis", "Toybox", "Clockwork", "Cloud", "Cosmic"]

def nice(x, n=2):
    if x < 100: return int(round(x))
    e = 10 ** (math.floor(math.log10(x)) - (n - 1))
    return int(round(x / e)) * e
def lnum(x): return "%d" % x if x < 1e15 else "%.6g" % x
def sub_cost(src, ident, value):
    pat = re.compile(r'(\{Id = "%s",[^\n]*?Cost = )([0-9.e+]+)' % re.escape(ident))
    mo = pat.search(src); assert mo, ident
    return src[:mo.start(2)] + lnum(value) + src[mo.end(2):]

def main(vpath):
    v = json.load(open(vpath))
    old = json.load(open(os.path.join(HERE, "rescale_w1x108.json")))["StageCost"]   # the gates live before this pass
    new = v["StageCost"]
    import exp, gamedata as G, gen_lua2, minis
    cat, pol = exp.setup(v)
    rep = {"gates": {s: [old[s], new[s]] for s in ORDER}}
    # StageConfig
    p = os.path.join(SRC, "StageConfig.luau"); src = open(p, encoding="utf-8").read()
    for s in ORDER:
        src = sub_cost(src, s, int(new[s]))
        src = re.sub(r'(\{Id = "%s",[^\n]*?) -- (?:5h) 2026-10-06: was [^\n]*\n' % s, lambda mo: mo.group(1) + "\n", src, count=1)
        src = re.sub(r'(\{Id = "%s",[^\n]*?)\n' % s, lambda mo: mo.group(1) + " -- 5h 2026-10-06: was %s\n" % gen_abbrev(old[s]), src, count=1)
    if "5-HOUR GAME 2026-10-06" not in src:
        src = src.replace("local S = {}", "-- 5-HOUR GAME 2026-10-06 (Claude; wiktor: \"rebalance everything so game can done in like 5 hours f2p\"): gates re-tuned so a casual\n-- free player finishes both worlds with the top parts in ~5 h (outputs/Rebalance20261005/sim: tune5h.py -> tuned5h_d.json -> emit5h.py).\nlocal S = {}", 1)
    open(p, "w", encoding="utf-8", newline="\n").write(src)
    # PetConfig egg prices
    p = os.path.join(SRC, "PetConfig.luau"); src = open(p, encoding="utf-8").read()
    eggs = {}
    for e in G.EGGS:
        c = nice(G.egg_cost(e)); eggs[e[0]] = c; src = sub_cost(src, e[0], c)
    open(p, "w", encoding="utf-8", newline="\n").write(src); rep["eggs"] = eggs
    # UpgradeConfig World 2 prices
    p = os.path.join(SRC, "UpgradeConfig.luau"); src = open(p, encoding="utf-8").read()
    w2 = {}
    for u in G.UPGRADES:
        if u["Id"].startswith("W2_"):
            w2[u["Id"]] = nice(u["C"]); src = sub_cost(src, u["Id"], w2[u["Id"]])
    open(p, "w", encoding="utf-8", newline="\n").write(src); rep["w2upgrades"] = w2
    # ActivityConfig lifetime Snow goals: log-interpolated between matching old / new gates
    pts = [(old[s], new[s]) for s in ORDER]
    def m(x):
        if x <= pts[0][0]: return x
        for (a0, b0), (a1, b1) in zip(pts, pts[1:]):
            if x <= a1: f = math.log(x / a0) / math.log(a1 / a0); return b0 * (b1 / b0) ** f
        return pts[-1][1] * x / pts[-1][0]
    p = os.path.join(SRC, "ActivityConfig.luau"); src = open(p, encoding="utf-8").read()
    ach = {}
    REF = {"Snow1": 40000.0, "Snow2": 30000000.0, "Snow3": 2000000000.0}   # review fix: always map from the fixed pre-5h goals (re-run safe)
    def asub(mo):
        sid = re.search(r'"(Snow\d)"', mo.group(1)).group(1)
        g = REF[sid]; g2 = nice(m(g), 1); ach[sid] = (g, g2)
        return mo.group(1) + mo.group(2).replace(mo.group(2)[mo.group(2).index("Dig ") + 4:mo.group(2).index(" snow")], gen_abbrev(g2)) + "%d" % g2
    src = re.sub(r'(\{Id = "Snow\d",)([^\n]*?Text = "Dig [^"]* snow", Stat = "SnowEarned", Goal = )([0-9.e+]+)', asub, src)
    open(p, "w", encoding="utf-8", newline="\n").write(src); rep["achievements"] = ach
    # PlowConfig: parts (gen_lua2 splice), mini level prices, final-band premium
    v2 = dict(v)
    cat2, lines = gen_lua2.generate(v2)
    p = os.path.join(SRC, "PlowConfig.luau"); src = open(p, encoding="utf-8").read()
    a = src.index("C.Parts = {\n"); b = src.index("\n}\nfor id, def in pairs(C.Parts)")
    src = src[:a] + "C.Parts = {\n" + "\n".join(lines) + src[b:]
    lv = []
    for i, (cnt, share, st, frac) in enumerate(minis.CFG["Levels"]):
        lv.append("\t\t{Count = %d, Share = %s, Cost = %s}, -- %g x %s gate" % (cnt, ("%g" % share), lnum(minis.level_cost(i)), frac, st))
    a = src.index("-- %MINI_LEVELS%\n") + len("-- %MINI_LEVELS%\n"); b = src.index("\t}, -- %END_MINI_LEVELS%")
    src = src[:a] + "\n".join(lv) + "\n" + src[b:]
    fb = v["Offers"].get("FinalBandPremium", 1.0)
    if "FinalBandPremium" not in src:
        src = src.replace("\tLuckSlope = 0.25, LuckCap = 2.0,", "\tFinalBandPremium = %g, -- 2026-10-06 (5-hour game): in the last band (Cosmic) its premium (B) parts show this many times more often\n\tLuckSlope = 0.25, LuckCap = 2.0," % fb, 1)
        src = src.replace("\t\t\t\tlocal w = rel * (O.RoleWeight[def.Role] or 1) * lf ^ math.max(0, rank - 3)\n",
            "\t\t\t\tlocal w = rel * (O.RoleWeight[def.Role] or 1) * lf ^ math.max(0, rank - 3)\n\t\t\t\tif band == #C.Bands and def.Band == band and def.Role == \"B\" then w *= (O.FinalBandPremium or 1) end\n", 1)
        assert "w *= (O.FinalBandPremium" in src
    else:
        src = re.sub(r"FinalBandPremium = [0-9.]+", "FinalBandPremium = %g" % fb, src, count=1)
    open(p, "w", encoding="utf-8", newline="\n").write(src)
    rep["minis"] = [minis.level_cost(i) for i in range(len(minis.CFG["Levels"]))]
    rep["top"] = {k: cat[k]["price"] for k in ("blade_galaxy", "engine_nebula", "gear_meteor", "body_starcruiser")}
    os.makedirs(os.path.join(HERE, "..", "build"), exist_ok=True)
    json.dump(rep, open(os.path.join(HERE, "..", "build", "emit5h_report.json"), "w"), indent=1)
    print(json.dumps({k: rep[k] for k in ("gates", "minis", "top", "achievements")}, indent=0))

def gen_abbrev(x):
    for s, val in (("Qi", 1e18), ("Qa", 1e15), ("T", 1e12), ("B", 1e9), ("M", 1e6), ("K", 1e3)):
        if x >= val: return ("%g" % float("%.3g" % (x / val))) + s
    return "%d" % x

if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "tuned5h_d.json"))
