import sys, json
import sim, model as M, catalog as CAT, gamedata as G, tune3
t = tune3.load(); tune3.apply(t)
cat = CAT.build()
beh = sys.argv[1] if len(sys.argv) > 1 else "efficient"
until = sys.argv[2] if len(sys.argv) > 2 else "Cosmic"
seed = int(sys.argv[3]) if len(sys.argv) > 3 else 2000
step = float(sys.argv[4]) if len(sys.argv) > 4 else 600
p = sim.Player(cat, beh, seed)
nxt = 0
while until not in p.stages and p.t < 18 * 3600:
    p.step()
    if p.t >= nxt:
        nxt += step
        u, mo = p.mods()
        r, stage = p.income()
        st = M.stats_for(cat, p.build, mo)
        pw, cv, rg, spp = M.field_rates(st, stage)
        ns = p.next_stage()
        print("%6.1f %-12s %-9.3g snow %-9.3g next %s %.3g | pow %.3g cov %.3g reg %.3g | upP %.3g upS %.3g pets %.3g | %s %s %s | ups %d eggs %d" % (
            p.t / 60, stage, r, p.snow, ns, G.stage_cost(ns) if ns else 0, pw, cv, rg, u["PowerMult"], u["SnowMult"], p.pet_mult(u),
            p.build["Blade"], p.build["Engine"], p.build["Gear"], len(p.ups), p.hatches))
print({s: round(v / 60, 1) for s, v in p.arrive.items()})
