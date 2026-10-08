# levels.py (2026-10-06, Claude) - part levels in the sim: every owned part (all four slots, starter parts included) can be
# levelled 1..Max with Snow. Mirrors PlowConfig.LevelStats / PlowConfig.LevelCost (keep the two in sync).
#   usage: python levels.py <variant.json> <tag> [seedsW1] [seedsW2] [--lv key=value ...]
import copy, json, math, os, sys, time
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import sim, sim2, model as M, gamedata as G

LV = {
    "Max": 10,
    "Step": 0.05,          # key stat x (1 + Step x (level - 1)) -> level 10 = x1.45 (live: PlowConfig.C.Levels)
    "SpeedShare": 0.25,    # engines: top speed gets this share of the step (the 60 cap still applies)
    "BodyFlat": 0.008,     # bodies: +0.8% Snow per level on top (so the free cab is worth levelling too)
    "Cost0": 0.25,         # level 1 -> 2 costs 25% of the part's price
    "Growth": 1.45,        # each further level costs x1.45 (top part's last level ~730T)
    "StarterBase": 60,     # price base for free parts (starter set)
    "PaidBase": 2000,      # price base for paid (pass) parts
    "LateFrom": 3,         # 2026-10-06 retune: from level LateFrom -> LateFrom+1 on, each level costs x LateGrowth (steeper late levels)
    "LateGrowth": 3.0,     # live since 2026-10-06 (= Growth would mean no late steepening)
    "LateJump": 10.0,      # one-off x at the LateFrom step (live since 2026-10-06)
    "Cap": 9.9e14,         # no single level costs more than 990T (nothing past the trillions)
    "Drift": 1.0,          # field Snow x this for the efficient behaviour (drift bonus, up to 1.20 live)
}

def level_stats(p, L):
    s = dict(p["stats"])
    if L <= 1: return s
    m = 1 + LV["Step"] * (L - 1)
    slot = p["slot"]
    if slot == "Blade": s["Soft"] *= m; s["Hard"] *= m
    elif slot == "Engine": s["Power"] *= m; s["Speed"] *= 1 + (m - 1) * LV["SpeedShare"]
    elif slot == "Gear": s["PowerMult"] *= m
    elif slot == "Body": s["Snow"] = s.get("Snow", 0) * m + LV["BodyFlat"] * (L - 1)
    return s

def level_base(p):
    if p.get("role") == "P": return LV["PaidBase"]
    return p["price"] if p["price"] > 0 else LV["StarterBase"]

def level_cost(p, L):   # Snow to go from level L to L + 1
    f = LV["Cost0"] * LV["Growth"] ** (min(L, LV["LateFrom"]) - 1)
    if L >= LV["LateFrom"]: f *= LV["LateJump"] * LV["LateGrowth"] ** (L - LV["LateFrom"])
    return round(min(level_base(p) * f, LV["Cap"]))

def total_cost(p):
    return sum(level_cost(p, L) for L in range(1, LV["Max"]))

class LevelCat(dict):
    """per-player catalog view: owned parts read their levelled stats; offer pools iterate the base entries"""
    def __init__(self, base, levels):
        super().__init__(base); self.levels = levels; self.cache = {}
    def _lv(self, k, v):
        L = self.levels.get(k, 1)
        if L <= 1: return v
        c = self.cache.get((k, L))
        if c is None:
            c = dict(v); c["stats"] = level_stats(v, L); self.cache[(k, L)] = c
        return c
    def __getitem__(self, k): return self._lv(k, dict.__getitem__(self, k))
    def get(self, k, d=None): return self[k] if k in self else d

Base = sim2.Player2
class LPlayer(Base):
    def __init__(self, cat, beh, seed, rebirths=0, carry=None, *a, **kw):
        levels = dict(getattr(carry, "levels", {}) or {}) if carry else {}
        self.levels = levels
        self.level_buys = 0
        self.drift = LV["Drift"] if beh == "efficient" else 1.0   # 2026-10-06 drift Snow bonus: the efficient player drifts all the time
        super().__init__(LevelCat(cat, levels), beh, seed, rebirths, carry, *a, **kw)
    def income(self, *a, **kw):
        v, stage = super().income(*a, **kw)
        return v * self.drift, stage
    def level_options(self):
        cur = max(self.rate(), 1e-9); out = []
        for slot, pid in self.build.items():
            L = self.levels.get(pid, 1)
            if L >= LV["Max"]: continue
            cost = level_cost(dict.__getitem__(self.cat, pid), L)
            self.levels[pid] = L + 1
            g = self.income()[0] / cur
            self.levels[pid] = L
            if g > 1.0005: out.append(("level", pid, cost, g))
        return out
    def options(self):
        return super().options() + self.level_options()
    def do_level(self, pid):
        self.levels[pid] = self.levels.get(pid, 1) + 1
        self.level_buys += 1; self.dirty = True; self.spend_time(2)
        self.events.append((self.t, "level", pid))
    def smart_buy(self):
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
            self.dirty = True; bought += 1
            self.improvements.append((self.t, kind, obj["Id"] if kind == "upgrade" else (obj if kind == "level" else obj[0]), self.rate() / max(before, 1e-9)))
        return bought
    def try_levels(self):   # legacy (non-value) buyer: same payback rule as its upgrades
        eta = self.eta_next(); limit = max(30, self.b["payback"] * eta); n = 0
        for _ in range(4):
            cands = [o for o in self.level_options() if o[2] <= self.snow]
            if not cands: break
            cur = self.rate()
            best = min(cands, key=lambda o: o[2] / max(cur * (o[3] - 1), 1e-9))
            if best[2] / max(cur * (best[3] - 1), 1e-9) > limit: break
            before = self.rate(); self.snow -= best[2]; self.do_level(best[1]); n += 1
            self.improvements.append((self.t, "level", best[1], self.rate() / max(before, 1e-9)))
        return n
    def available_now(self):
        inc = max(self.rate(), 1e-9); budget = self.snow + inc * 60 * self.AVAIL_MIN
        for o in self.level_options():
            if o[3] >= self.AVAIL_GAIN and o[2] <= budget: return "level"
        return super().available_now()
    def step(self, dt=10):
        if not self.smart:
            self.track_availability(); self.earn(dt)
            while self.try_stage(): pass
            self.try_upgrades(); self.try_levels(); self.try_eggs(); self.garage_trip(); self.do_jobs()
            return
        super().step(dt)

def ladder_check(cat):
    """does a fully levelled part land between its own tier and the next tier's base? (score on its own band's stage)"""
    import statistics
    rows = []
    for slot in ("Blade", "Engine", "Gear", "Body"):
        parts = sorted([(k, v) for k, v in cat.items() if v["slot"] == slot and v.get("role") not in ("P",)], key=lambda kv: (kv[1]["price"], kv[0]))
        for (ka, a), (kb, b) in zip(parts, parts[1:]):
            if a["price"] <= 0 and a.get("role") != "S": continue
            rows.append((slot, ka, kb, a["price"], b["price"]))
    return rows

if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--lv")]
    for a in sys.argv[1:]:
        if a.startswith("--lv"):
            k, val = a[4:].lstrip("=").split("=")
            LV[k] = type(LV[k])(float(val)) if not isinstance(LV[k], int) else int(float(val))
    sim2.Player2 = LPlayer
    import final_eval
    v = json.load(open(args[0])); tag = args[1]
    n1 = int(args[2]) if len(args) > 2 else 40; n2 = int(args[3]) if len(args) > 3 else 20
    t0 = time.time()
    res, cat = final_eval.evaluate(v, n1, n2, pity=v.get("PityAfford", False))
    res["levels"] = dict(LV)
    os.makedirs(os.path.join(HERE, "..", "results"), exist_ok=True)
    json.dump(res, open(os.path.join(HERE, "..", "results", "eval_%s.json" % tag), "w"), indent=1)
    print("done", round(time.time() - t0), "s")

