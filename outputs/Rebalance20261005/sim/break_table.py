# break_table.py (2026-10-06, Claude) - hard-snow speed check: for the sim's casual and efficient players, the break speed
# (speed at which one blade pass breaks a layer) on each stage, from their real build + upgrades + part levels, at stage entry
# and averaged over their time on that stage; compared with the plowing top speed and the 25% floor (PlowConfig C.Drive.HardSnow).
# usage: python break_table.py <variant.json> [seeds]
import json, os, statistics, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import levels, sim2, model as M, gamedata as G
levels.LV.update(LateJump=10.0, LateGrowth=3.0, Drift=1.5)
sim2.Player2 = levels.LPlayer
import exp, catalog2 as C2

FLOOR = 0.25
def vbreak(st, stage):
    hp = G.STAGE_FIELD[stage][0] * M.HP_MULT.get(stage, 1.0)
    eff = st["Soft"] + (st["Hard"] - st["Soft"]) * G.TOUGH[stage]
    return (M.BLADE_DEPTH + 2 * M.SLACK) * st["ClearPower"] * eff / hp

samples = {}
Base = levels.LPlayer
class Probe(Base):
    def earn(self, sec):
        st_id = self.cur_stage
        if st_id in G.STAGE_FIELD:
            u, mo = self.mods()
            st = M.stats_for(self.cat, self.build, mo)
            top = st["MaxSpeed"] * M.PLOWING_SPEED
            v = vbreak(st, st_id)
            k = (self.b_name, st_id)
            s = samples.setdefault(k, {"t": 0.0, "floor": 0.0, "capped": 0.0, "first": None, "top": top})
            s["t"] += sec
            if v < FLOOR * top: s["floor"] += sec
            elif v < top: s["capped"] += sec
            if s["first"] is None: s["first"] = (v, top)
        return super().earn(sec)
sim2.Player2 = Probe

if __name__ == "__main__":
    v = json.load(open(sys.argv[1])); n = int(sys.argv[2]) if len(sys.argv) > 2 else 8
    cat, pol = exp.setup(v)
    for beh in ("casual", "efficient"):
        for i in range(n):
            Probe.b_name = beh
            sim2.run(cat, beh, 3000 + i, policy=pol, smart=True, until="Cosmic", hours=30)
    order = ["Starter", "Desert", "Cursed", "Crystal", "Retro", "Jungle", "AbsoluteZero", "Sakura", "Candy", "Atlantis", "Toybox", "Clockwork", "Cloud", "Cosmic"]
    print("| stage | player | break speed at entry | plowing top | at entry | share of time at floor / capped |")
    for st in order:
        for beh in ("casual", "efficient"):
            s = samples.get((beh, st))
            if not s or not s["first"]: continue
            vb, top = s["first"]
            state = "floor" if vb < FLOOR * top else ("capped" if vb < top else "full speed")
            print("| %s | %s | %.1f | %.1f | %s | %d%% / %d%% |" % (st, beh, vb, top, state, 100 * s["floor"] / s["t"], 100 * s["capped"] / s["t"]))
