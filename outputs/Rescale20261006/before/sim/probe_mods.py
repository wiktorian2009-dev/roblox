# probe_mods.py - upgrade/pet multipliers of the simulated efficient player when entering a stage (for the Studio drive tests)
import json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import exp, sim2
v = json.load(open(os.path.join(HERE, "final_variant.json")))
cat, pol = exp.setup(v)
for target in sys.argv[1:] or ["Jungle", "Candy"]:
    p = sim2.Player2(cat, "efficient", 3000, policy=pol); p.smart = True; p.PITY_AFFORD = True
    while target not in p.stages and p.t < 20 * 3600: p.step()
    u, m = p.mods()
    print(target, round(p.t / 60), "min", {k: round(x, 3) for k, x in m.items()}, "SnowMult", round(u.get("SnowMult", 1), 2), "build", p.build, "income/s %.3g" % p.income()[0])
