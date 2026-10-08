# minis.py (2026-10-06, Claude) - MINI PLOWS in the sim: an upgrade bought with Snow in levels; each level sets how many mini copies of
# the player's equipped plow drive in their best unlocked field and what share of the plow's own field rate each one earns.
# Mirrors PlowConfig.Minis + MiniPlowService (keep in sync):
#   mini Snow/s = Count x Share x max over unlocked stages of smin(power, cover) x SnowPerPhase x SnowEff  x SnowMult x pets
#   (no dig combo, no drift, no "active share": they run the whole time the player is in the game; nothing offline).
# Level prices are explicit numbers = Frac x the gate of Stage (written into PlowConfig by gen_minis.py), so they follow the gates.
import math, sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import gamedata as G, model as M, sim

CFG = {   # level -> (count, share per mini, price stage, price fraction of that stage's gate)
    # 2026-10-06 Play calibration: the model rate is ~1.3x what the starter plow really clears on Starter (24 vs 18.4 Snow/s), so the top
    # level is 5 x 0.09 = 0.45 of the model rate (~0.6 of real plain driving) - below AFK (0.70), well below active driving with combo/drift
    "Levels": [(1, 0.05, "Desert", 0.12), (2, 0.05, "Cursed", 0.10), (3, 0.05, "Crystal", 0.10), (3, 0.065, "Retro", 0.10),
               (4, 0.065, "Jungle", 0.10), (4, 0.08, "Portal", 0.04), (5, 0.08, "Atlantis", 0.08), (5, 0.09, "Clockwork", 0.08)],
    "PlowingSpeed": 0.6,
}

def level_cost(L):   # Snow to go from level L to L + 1 (L = 0 .. len - 1)
    cnt, share, st, frac = CFG["Levels"][L]
    return nice(frac * G.stage_cost(st))

def nice(x):
    if x < 100: return max(1, int(round(x)))
    e = 10 ** (math.floor(math.log10(x)) - 1)
    return int(round(x / e)) * e

def mini_base(st, stages):   # best field rate of one full-share mini (Snow/s before SnowMult / pets)
    best = 0.0
    for s in stages:
        if s not in G.STAGE_FIELD: continue
        p, c, r, spp = M.field_rates(st, s)
        c *= 1.0   # field_rates already uses PLOWING_SPEED in cover
        v = M.smin(p, c) * spp * st.get("SnowEff", 1.0)
        if v > best: best = v
    return best

def install(cfg=None):
    if isinstance(cfg, dict): CFG.update(cfg)
    import sim2
    Base = sim2.Player2
    if getattr(Base, "_minis", False): return
    class MPlayer(Base):
        _minis = True
        def __init__(self, *a, **kw):
            self.mini_level = 0; self.mini_snow = 0.0
            super().__init__(*a, **kw)
        def mini_rate(self, build=None, ups=None, pets=None, level=None):
            L = self.mini_level if level is None else level
            if L <= 0: return 0.0
            cnt, share = CFG["Levels"][L - 1][0], CFG["Levels"][L - 1][1]
            u, mo = self.mods(ups)
            st = M.stats_for(self.cat, build or self.build, mo)
            s, l = self.ach()
            snow_mult = u["SnowMult"] * (1 + s) * self.b["boost"] * getattr(self, "PAID_SNOW", 1.0)
            return cnt * share * mini_base(st, self.stages) * snow_mult * self.pet_mult(u, pets)
        def income(self, build=None, ups=None, pets=None):
            v, stage = super().income(build, ups, pets)
            return v + self.mini_rate(build, ups, pets), stage
        def rate(self):
            if self.dirty: self._mr = self.mini_rate()
            return super().rate()
        def earn(self, sec):
            if self.mini_level > 0: self.rate(); self.mini_snow += self._mr * sec
            super().earn(sec)   # rate() already includes the minis
        def spend_time(self, sec):
            # review fix 2026-10-06: live MiniPlowService pays every second while in the game, also while buying, rolling, travelling
            if self.mini_level > 0:
                self.rate(); g = self._mr * sec
                self.snow += g; self.earned += g; self.mini_snow += g
            super().spend_time(sec)
        def do_jobs(self):
            # review fix 2026-10-06: a Help job pays from the plow alone (ContractService), the minis keep earning 1x meanwhile
            if self.mini_level <= 0: return super().do_jobs()
            self.rate(); mr = self._mr; L = self.mini_level; t0 = self.t
            self.mini_level = 0; self.dirty = True
            try:
                super().do_jobs()
            finally:
                self.mini_level = L; self.dirty = True
            g = mr * (self.t - t0)
            self.snow += g; self.earned += g; self.mini_snow += g
        def mini_option(self):
            if self.mini_level >= len(CFG["Levels"]): return []
            cur = max(self.rate(), 1e-9)
            g = (cur - self.mini_rate() + self.mini_rate(level=self.mini_level + 1)) / cur
            return [("mini", self.mini_level + 1, level_cost(self.mini_level), g)] if g > 1.0005 else []
        def options(self):
            return super().options() + self.mini_option()
        def smart_buy(self):
            # same value rule as levels.LPlayer.smart_buy, with "mini" as one more kind
            bought = 0
            for _ in range(10):
                opts = self.options()
                if not opts: break
                inc = max(self.rate(), 1e-9)
                opts = [o for o in opts if o[3] > 1.0 and o[2] / (inc * (o[3] - 1)) <= 60 * self.PAYBACK_MIN]
                reach = [o for o in opts if o[2] <= self.snow + inc * 60 * self.SAVE_MIN]
                if not reach: break
                val = lambda o: math.log(o[3]) / max(o[2], 1e-9)
                best = max(reach, key=val)
                if best[2] > self.snow:
                    aff = [o for o in reach if o[2] <= self.snow and val(o) >= 0.5 * val(best)]
                    if not aff: break
                    best = max(aff, key=val)
                if best[0] != "mini":
                    self._buy_one(best)
                else:
                    before = self.rate()
                    self.snow -= best[2]; self.mini_level = best[1]; self.dirty = True; self.spend_time(3)
                    self.events.append((self.t, "mini", best[1]))
                    self.improvements.append((self.t, "mini", best[1], self.rate() / max(before, 1e-9)))
                bought += 1
            return bought
        def _buy_one(self, best):
            before = self.rate()
            kind, obj, cost, g = best
            self.snow -= cost
            if kind == "upgrade":
                self.ups.add(obj["Id"]); self.events.append((self.t, "upgrade", obj["Id"])); self.spend_time(3)
            elif kind == "level":
                self.do_level(obj)
            else:
                self.hatches += 1
                x = self.rng.random() * 100
                for name, ch, bo in obj[3]:
                    x -= ch
                    if x <= 0: break
                self.pets[name] = self.pets.get(name, 0) + 1
                self.fuse(); self.spend_time(4); self.events.append((self.t, "egg", obj[0]))
            self.dirty = True
            self.improvements.append((self.t, kind, obj["Id"] if kind == "upgrade" else (obj if kind == "level" else obj[0]), self.rate() / max(before, 1e-9)))
            return 1
        def try_minis(self):   # legacy (non-value) buyer: the same payback rule as its upgrades
            eta = self.eta_next(); limit = max(30, self.b["payback"] * eta); n = 0
            for _ in range(2):
                o = self.mini_option()
                if not o or o[0][2] > self.snow: break
                cur = self.rate()
                if o[0][2] / max(cur * (o[0][3] - 1), 1e-9) > limit: break
                before = cur; self.snow -= o[0][2]; self.mini_level = o[0][1]; self.dirty = True; n += 1
                self.improvements.append((self.t, "mini", self.mini_level, self.rate() / max(before, 1e-9)))
            return n
        def available_now(self):
            inc = max(self.rate(), 1e-9); budget = self.snow + inc * 60 * self.AVAIL_MIN
            for o in self.mini_option():
                if o[3] >= self.AVAIL_GAIN and o[2] <= budget: return "mini"
            return super().available_now()
        def step(self, dt=10):
            if not self.smart:
                self.track_availability(); self.earn(dt)
                while self.try_stage(): pass
                self.try_upgrades(); self.try_levels(); self.try_minis(); self.try_eggs(); self.garage_trip(); self.do_jobs()
                return
            Base.step(self, dt)
    sim2.Player2 = MPlayer
