import sys, json
import sim, model as M, catalog as CAT, gamedata as G
cat = CAT.build()
beh = sys.argv[1] if len(sys.argv) > 1 else "efficient"
until = sys.argv[2] if len(sys.argv) > 2 else "Portal"
p = sim.Player(cat, beh, 1000)
last = None
nxt = 0
while until not in p.stages and p.t < 14 * 3600:
    p.step()
    if p.t >= nxt:
        nxt += 300
        u, mo = p.mods()
        r, stage = p.income()
        st = M.stats_for(cat, p.build, mo)
        pw, cv, rg, spp = M.field_rates(st, stage)
        print("%6.1f min %-12s snow/s %-10.3g pow %.3g cov %.3g reg %.3g | P %.3g W %.1f  up(P%.3g S%.3g) pets %.3g | %s %s %s | ups %d" % (
            p.t / 60, stage, r, pw, cv, rg, st["ClearPower"], st["BladeWidth"], u["PowerMult"], u["SnowMult"], p.pet_mult(u),
            p.build["Blade"], p.build["Engine"], p.build["Gear"], len(p.ups)))
for s, t in p.arrive.items(): print(s, round(t / 60, 1))
